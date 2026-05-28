#!/usr/bin/env bash
# Install Memory Monitor plugin into DankMaterialShell
set -euo pipefail

PLUGIN_DIR="$HOME/.config/DankMaterialShell/plugins/memoryMonitor"

echo "Installing Memory Monitor plugin..."
mkdir -p "$PLUGIN_DIR"
cp -r ../memoryMonitor/* "$PLUGIN_DIR/"

echo "Memory Monitor plugin installed to $PLUGIN_DIR"
echo "Open DMS Settings -> Plugins, click 'Scan for Plugins', enable 'Memory Monitor'."
echo "Then add 'memoryMonitor' to your DankBar widget list or use as a desktop widget."
