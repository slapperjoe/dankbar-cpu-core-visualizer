#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="CpuCoreVisualizer"
PLUGIN_ID="cpuCoreVisualizer"
PLUGINS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugins"
TARGET_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

usage() {
    cat <<EOF
Usage: ./install.sh [--target-dir PATH]

Installs ${PLUGIN_NAME} into the DankMaterialShell plugins directory.

Options:
  --target-dir PATH  Install into a specific destination directory
  -h, --help         Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir)
            if [[ $# -lt 2 ]]; then
                echo "error: --target-dir requires a path" >&2
                exit 1
            fi
            TARGET_DIR="$2"
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

if [[ -z "$TARGET_DIR" || "$TARGET_DIR" == "/" ]]; then
    echo "error: refusing to install into '$TARGET_DIR'" >&2
    exit 1
fi

mkdir -p "$(dirname -- "$TARGET_DIR")"
rm -rf -- "$TARGET_DIR"
mkdir -p -- "$TARGET_DIR"

tar --exclude=.git -cf - -C "$SCRIPT_DIR" . | tar -xf - -C "$TARGET_DIR"

cat <<EOF
Installed ${PLUGIN_ID} to:
  ${TARGET_DIR}

Next in DankMaterialShell:
  1. Open DMS Settings -> Plugins
  2. Click Scan for Plugins
  3. Enable CPU Core Visualizer
  4. Add ${PLUGIN_ID} to your DankBar widget list
EOF
