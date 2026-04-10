use gtk::prelude::*;
use webkit2gtk::{WebView, WebViewExt};
use serde::Serialize;
use std::sync::{Arc, Mutex};
use std::time::Duration;
use sysinfo::{Disks, System};
use glib::ControlFlow;

const HTML_CONTENT: &str = include_str!("../local.html");

#[derive(Serialize, Clone)]
struct BatteryInfo {
    percent: u8,
    status: String,
}

#[derive(Serialize, Clone)]
struct MemoryInfo {
    total: f64,
    used: f64,
    percent: f64,
}

#[derive(Serialize, Clone)]
struct StorageInfo {
    total: f64,
    used: f64,
    percent: f64,
}

#[derive(Serialize, Clone)]
struct SystemData {
    date: String,
    time: String,
    cpu_percent: f32,
    memory: MemoryInfo,
    battery: BatteryInfo,
    brightness: u8,
    storage: StorageInfo,
}

fn read_sys_file(path: &str) -> Result<String, std::io::Error> {
    std::fs::read_to_string(path).map(|s| s.trim().to_string())
}

fn get_battery_info() -> BatteryInfo {
    const BATTERY_DIR: &str = "/sys/class/power_supply/qcom-battmgr-bat/";

    let energy_full_path = format!("{}energy_full", BATTERY_DIR);
    let energy_now_path = format!("{}energy_now", BATTERY_DIR);
    let status_path = format!("{}status", BATTERY_DIR);

    match (
        read_sys_file(&energy_full_path),
        read_sys_file(&energy_now_path),
        read_sys_file(&status_path),
    ) {
        (Ok(full), Ok(now), Ok(status)) => {
            if let (Ok(energy_full), Ok(energy_now)) = (full.parse::<f64>(), now.parse::<f64>()) {
                let capacity = ((energy_now / energy_full) * 100.0).round() as u8;
                return BatteryInfo {
                    percent: capacity.clamp(0, 100),
                    status,
                };
            }
        }
        _ => {}
    }

    BatteryInfo {
        percent: 0,
        status: "No Battery".to_string(),
    }
}

fn get_brightness_level() -> u8 {
    const BRIGHTNESS_PATH: &str = "/sys/class/backlight/backlight/brightness";
    const MAX_BRIGHTNESS_PATH: &str = "/sys/class/backlight/backlight/max_brightness";

    match (read_sys_file(BRIGHTNESS_PATH), read_sys_file(MAX_BRIGHTNESS_PATH)) {
        (Ok(brightness), Ok(max_brightness)) => {
            if let (Ok(b), Ok(mb)) = (brightness.parse::<f64>(), max_brightness.parse::<f64>()) {
                return ((b / mb) * 100.0).round() as u8;
            }
        }
        _ => {}
    }
    0
}

fn get_storage_info() -> StorageInfo {
    let disks = Disks::new_with_refreshed_list();

    for disk in &disks {
        if disk.mount_point().to_str() == Some("/") {
            let total_gb = disk.total_space() as f64 / (1024_f64.powi(3));
            let available_gb = disk.available_space() as f64 / (1024_f64.powi(3));
            let used_gb = total_gb - available_gb;
            let percent = (used_gb / total_gb * 100.0).round();

            return StorageInfo {
                total: (total_gb * 100.0).round() / 100.0,
                used: (used_gb * 100.0).round() / 100.0,
                percent,
            };
        }
    }

    StorageInfo {
        total: 0.0,
        used: 0.0,
        percent: 0.0,
    }
}

fn collect_system_data(sys: &mut System) -> SystemData {
    sys.refresh_cpu();
    sys.refresh_memory();

    let now = chrono::Local::now();
    let cpu_percent = sys.global_cpu_info().cpu_usage();

    let total_mem = sys.total_memory() as f64 / (1024_f64.powi(3));
    let used_mem = sys.used_memory() as f64 / (1024_f64.powi(3));
    let mem_percent = (used_mem / total_mem * 100.0).round();

    SystemData {
        date: now.format("%d %b %y").to_string(),
        time: now.format("%H:%M").to_string(),
        cpu_percent,
        memory: MemoryInfo {
            total: (total_mem * 100.0).round() / 100.0,
            used: (used_mem * 100.0).round() / 100.0,
            percent: mem_percent,
        },
        battery: get_battery_info(),
        brightness: get_brightness_level(),
        storage: get_storage_info(),
    }
}

fn start_system_monitor(webview: WebView) {
    // Wrap the system data in an Arc<Mutex<>> to share between threads
    let system_data = Arc::new(Mutex::new(None::<SystemData>));
    let system_data_clone = system_data.clone();

    // Background thread to collect system data
    std::thread::spawn(move || {
        let mut sys = System::new_all();
        sys.refresh_all();

        loop {
            let data = collect_system_data(&mut sys);
            *system_data_clone.lock().unwrap() = Some(data);
            std::thread::sleep(Duration::from_secs(1));
        }
    });

    // GTK main thread timer to update the webview
    glib::timeout_add_local(Duration::from_secs(1), move || {
        if let Some(data) = system_data.lock().unwrap().clone() {
            if let Ok(json) = serde_json::to_string(&data) {
                let script = format!("updateSystemInfo({});", json);
                webview.run_javascript(&script, None::<&gio::Cancellable>, |_| {});
            }
        }
        ControlFlow::Continue
    });
}

fn build_ui() {
    let window = gtk::Window::new(gtk::WindowType::Toplevel);
    window.set_title("Webdash");
    window.set_default_size(800, 600);

    // Make window fullscreen
    window.fullscreen();

    // Keep window on top
    window.set_keep_above(true);

    // Remove decorations
    window.set_decorated(false);

    // Make window transparent
    if let Some(screen) = gtk::prelude::WidgetExt::screen(&window) {
        if let Some(visual) = screen.rgba_visual() {
            window.set_visual(Some(&visual));
        }
    }
    window.set_app_paintable(true);

    // Create WebView
    let webview = WebView::new();

    // Set transparent background
    webview.set_background_color(&gdk::RGBA::new(0.0, 0.0, 0.0, 0.0));

    // Load HTML content
    webview.load_html(HTML_CONTENT, Some("file:///"));

    // Add webview to scrolled window
    let scrolled_window = gtk::ScrolledWindow::new(None::<&gtk::Adjustment>, None::<&gtk::Adjustment>);
    scrolled_window.add(&webview);

    window.add(&scrolled_window);

    // Start system monitoring
    start_system_monitor(webview);

    window.connect_delete_event(|_, _| {
        gtk::main_quit();
        glib::Propagation::Stop
    });

    window.show_all();
}

fn main() {
    gtk::init().expect("Failed to initialize GTK");

    build_ui();

    gtk::main();
}
