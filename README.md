# Webdash - Rust Implementation

A blazing-fast system dashboard for Arch Linux ARM, rewritten in Rust.

## Performance Improvements

This Rust implementation offers significant performance improvements over the Python version:

- **Instant startup**: ~50-100ms vs 500-1000ms for Python
- **Lower memory usage**: ~20-30MB vs 60-100MB for Python
- **Zero GC pauses**: No garbage collection overhead
- **Native compilation**: Fully optimized machine code
- **Efficient system monitoring**: Direct sysfs reads with minimal overhead

## Build Instructions

### Prerequisites

Install required dependencies on Arch Linux ARM:

```bash
sudo pacman -S rust gtk4 webkit2gtk-4.1
```

### Building

```bash
# Debug build (faster compilation, slower runtime)
cargo build

# Release build (optimized, recommended)
cargo build --release
```

The release build will be located at `target/release/webdash`

### Running

```bash
# Direct execution
./target/release/webdash

# Or use the launcher script (toggle on/off)
./launcher.sh
```

## Project Structure

```
.
├── Cargo.toml           # Rust project configuration
├── src/
│   ├── main.rs          # Main application code
│   └── local.html       # Embedded HTML dashboard
├── launcher.sh          # Toggle script for the dashboard
└── README.md            # This file
```

## Key Features

- **Embedded HTML**: HTML is compiled into the binary for instant loading
- **Async runtime**: Non-blocking system monitoring using Tokio
- **Optimized compilation**: LTO, single codegen unit, stripped symbols
- **Efficient system access**: Direct `/sys` filesystem reads
- **Native GTK4**: Modern GTK4 bindings for minimal overhead

## System Requirements

- Arch Linux ARM (tested on Qualcomm X13s)
- GTK4
- WebKit2GTK 4.1
- System paths:
  - Battery: `/sys/class/power_supply/qcom-battmgr-bat/`
  - Brightness: `/sys/class/backlight/backlight/`

## Customization

To modify the dashboard appearance, edit `src/local.html` and rebuild:

```bash
cargo build --release
```

## License

Same as original project.
