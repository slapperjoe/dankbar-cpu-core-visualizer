#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"

# Plugin definitions: "display_name  dir_name  plugin_id"
PLUGINS=(
    "CPU Core Visualizer  cpuCoreVisualizer  cpuCoreVisualizer"
    "GPU Monitor          gpuMonitor          gpuMonitor"
    "Memory Monitor       memoryMonitor        memoryMonitor"
    "Disk Monitor         diskMonitor          diskMonitor"
    "Network Monitor      networkMonitor        networkMonitor"
    "Audio Switcher       audioSwitcher        audioSwitcher"
)

usage() {
    cat <<EOF
Usage: ./install.sh [--all] [--plugin PLUGIN_ID]

Installs all split monitoring plugins into the DankMaterialShell plugins directory.

Options:
  --all              Install all plugins (default)
  --plugin PLUGIN_ID  Install a single plugin by ID
  -h, --help         Show this help text
EOF
}

INSTALL_ALL=true
INSTALL_PLUGIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)
            INSTALL_ALL=true
            INSTALL_PLUGIN=""
            shift
            ;;
        --plugin)
            if [[ $# -lt 2 ]]; then
                echo "error: --plugin requires a plugin ID" >&2
                exit 1
            fi
            INSTALL_ALL=false
            INSTALL_PLUGIN="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

install_plugin() {
    local display_name="$1"
    local dir_name="$2"
    local plugin_id="$3"
    local target_dir="$PLUGINS_DIR/$dir_name"

    mkdir -p -- "$target_dir"
    rm -rf -- "$target_dir"
    mkdir -p -- "$target_dir"

    local src_dir="$SCRIPT_DIR/$dir_name"
    if [[ ! -d "$src_dir" ]]; then
        echo "warning: source directory '$src_dir' not found, skipping $plugin_id" >&2
        return
    fi

    cp -r "$src_dir/." "$target_dir/"
    echo "Installed $display_name ($plugin_id) -> $target_dir"
}

if [[ "$INSTALL_ALL" == "true" ]]; then
    echo "Installing all monitoring plugins..."
    for entry in "${PLUGINS[@]}"; do
        read -r display_name dir_name plugin_id <<< "$entry"
        install_plugin "$display_name" "$dir_name" "$plugin_id"
    done
else
    found=false
    for entry in "${PLUGINS[@]}"; do
        read -r display_name dir_name plugin_id <<< "$entry"
        if [[ "$plugin_id" == "$INSTALL_PLUGIN" ]]; then
            install_plugin "$display_name" "$dir_name" "$plugin_id"
            found=true
            break
        fi
    done
    if [[ "$found" == "false" ]]; then
        echo "error: unknown plugin ID '$INSTALL_PLUGIN'" >&2
        echo "Available: cpuCoreVisualizer gpuMonitor memoryMonitor diskMonitor networkMonitor audioSwitcher" >&2
        exit 1
    fi
fi

# Restart DMS to pick up plugins
if command -v dms &>/dev/null; then
    dms restart
fi

cat <<EOF

Installed successfully. Next steps in DankMaterialShell:
  1. Open DMS Settings -> Plugins
  2. Click 'Scan for Plugins'
  3. Enable the plugins you want
  4. Add their IDs to your DankBar widget list:

     cpuCoreVisualizer  gpuMonitor  memoryMonitor
     diskMonitor        networkMonitor  audioSwitcher

Each plugin also supports niri desktop widgets (DMS will host them automatically).
EOF
