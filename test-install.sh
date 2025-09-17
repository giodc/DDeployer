#!/bin/bash

# Simple test script to verify installation requirements

echo "=== DDeployer Installation Test ==="
echo

# Check current directory
echo "Current directory: $(pwd)"
echo "Script location: $(dirname "$0")"
echo

# Check for required files
echo "Checking for required files:"
files=("docker-compose.yml" "admin/composer.json" "templates/wordpress/docker-compose.yml" "config/mysql/my.cnf")

all_found=true
for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✓ Found: $file"
    else
        echo "✗ Missing: $file"
        all_found=false
    fi
done

echo

if $all_found; then
    echo "✅ All required files found! You can run the installer."
    echo "Run: sudo ./install.sh --local"
else
    echo "❌ Some files are missing. Please ensure you're in the DDeployer directory."
    echo
    echo "Expected directory structure:"
    echo "DDeployer/"
    echo "├── install.sh"
    echo "├── docker-compose.yml"
    echo "├── admin/"
    echo "├── templates/"
    echo "└── config/"
fi

echo
echo "Files in current directory:"
ls -la
