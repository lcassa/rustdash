#!/bin/bash

echo "Webdash Rust - Build Verification"
echo "=================================="
echo ""

# Check for Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust/Cargo not found. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi
echo "✓ Rust/Cargo found"

# Check for GTK3
if ! pkg-config --exists gtk+-3.0; then
    echo "❌ GTK3 not found. Install with: sudo pacman -S gtk3"
    exit 1
fi
echo "✓ GTK3 found"

# Check for WebKit2GTK
if ! pkg-config --exists webkit2gtk-4.0; then
    echo "❌ WebKit2GTK not found. Install with: sudo pacman -S webkit2gtk"
    exit 1
fi
echo "✓ WebKit2GTK found"

echo ""
echo "All dependencies satisfied!"
echo ""
echo "Building release version..."
cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "Binary location: ./target/release/webdash"
    ls -lh ./target/release/webdash | awk '{print "Binary size:", $5}'
    echo ""
    echo "Run with: ./target/release/webdash"
    echo "Or use launcher: ./launcher.sh"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
