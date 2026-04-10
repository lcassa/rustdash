#!/bin/bash

# Path to the compiled Rust binary
BINARY_PATH="/home/lcassa/repos/rustdash/target/release/webdash"

# PID file to track the running instance
PID_FILE="/tmp/webdash.pid"

# Check if the binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary not found at $BINARY_PATH"
    echo "Please run: cargo build --release"
    exit 1
fi

# Check if the script is already running
if [ -f "$PID_FILE" ]; then
    # Read the PID from the file
    EXISTING_PID=$(cat "$PID_FILE")

    # Check if the process is still running
    if ps -p "$EXISTING_PID" > /dev/null; then
        # Kill the existing process
        kill "$EXISTING_PID"
        rm "$PID_FILE"
        echo "Existing fullscreen window closed."
        exit 0
    fi
fi

# Run the binary in the background
"$BINARY_PATH" &

# Store the PID of the background process
echo $! > "$PID_FILE"

echo "Fullscreen window launched."
