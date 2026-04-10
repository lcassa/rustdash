#!/bin/bash

echo "Checking project structure..."
echo ""

errors=0

# Check for Cargo.toml
if [ ! -f "Cargo.toml" ]; then
    echo "❌ Cargo.toml not found"
    errors=$((errors + 1))
else
    echo "✓ Cargo.toml found"
fi

# Check for src directory
if [ ! -d "src" ]; then
    echo "❌ src/ directory not found"
    errors=$((errors + 1))
else
    echo "✓ src/ directory found"
fi

# Check for main.rs
if [ ! -f "src/main.rs" ]; then
    echo "❌ src/main.rs not found"
    errors=$((errors + 1))
else
    echo "✓ src/main.rs found"
fi

# Check for local.html in project root
if [ ! -f "local.html" ]; then
    echo "❌ local.html not found in project root"
    echo "   (needed for include_str!(\"../local.html\"))"
    errors=$((errors + 1))
else
    echo "✓ local.html found in project root"
fi

echo ""
if [ $errors -eq 0 ]; then
    echo "✓ Project structure is correct!"
    echo ""
    echo "You can now run: cargo build --release"
else
    echo "❌ Found $errors error(s) in project structure"
    exit 1
fi
