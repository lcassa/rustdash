.PHONY: build release run install clean install-battery-notify

# Default target
all: release

# Debug build
build:
	cargo build

# Optimized release build
release:
	cargo build --release

# Run the dashboard
run: release
	./target/release/webdash

# Install to /usr/local/bin
install: release
	sudo cp target/release/webdash /usr/local/bin/
	sudo chmod +x /usr/local/bin/webdash
	@echo "Installed to /usr/local/bin/webdash"

# Install the standalone low-battery notifier (script + systemd user timer)
install-battery-notify:
	install -Dm755 battery-notify/battery-notify.sh $(HOME)/.local/bin/battery-notify.sh
	install -Dm644 battery-notify/battery-notify.service $(HOME)/.config/systemd/user/battery-notify.service
	install -Dm644 battery-notify/battery-notify.timer $(HOME)/.config/systemd/user/battery-notify.timer
	systemctl --user daemon-reload
	systemctl --user enable --now battery-notify.timer
	@echo "Battery notifier installed and timer enabled"

# Clean build artifacts
clean:
	cargo clean

# Show binary size
size: release
	@ls -lh target/release/webdash | awk '{print "Binary size:", $$5}'
	@strip target/release/webdash
	@ls -lh target/release/webdash | awk '{print "Stripped size:", $$5}'
