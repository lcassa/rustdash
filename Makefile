.PHONY: build release run install clean

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

# Clean build artifacts
clean:
	cargo clean

# Show binary size
size: release
	@ls -lh target/release/webdash | awk '{print "Binary size:", $$5}'
	@strip target/release/webdash
	@ls -lh target/release/webdash | awk '{print "Stripped size:", $$5}'
