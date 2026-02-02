#!/bin/bash
# Build script for Linux/macOS
# This creates a standalone executable using PyInstaller

echo "Installing PyInstaller..."
pip3 install pyinstaller

echo "Building RandomDom executable..."
pyinstaller --onefile --name randomdom randomdom.py

echo ""
echo "Build complete!"
echo "Executable is located in: dist/randomdom"
echo ""
