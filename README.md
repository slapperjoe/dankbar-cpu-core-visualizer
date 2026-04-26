# CPU Core Visualizer

Per-core vivid CPU bars for DankBar / DankMaterialShell.

## What it does

- one bar per CPU core
- vivid, soft-dark, mono, or UI-base rendering
- bars only, no labels
- optional overall CPU percentage plus adjustable probe time and smoother motion

## Install

From the repository root:

```bash
chmod +x ./install.sh
./install.sh
```

Then:

1. Open **DMS Settings -> Plugins**
2. Click **Scan for Plugins**
3. Enable **CPU Core Visualizer**
4. Add `cpuCoreVisualizer` to your DankBar widget list

To install somewhere else, use:

```bash
./install.sh --target-dir /path/to/plugins/CpuCoreVisualizer
```

## Current limits

- top/bottom bars are the best-looking path right now
- left/right bars still use horizontal strips, but they now fill inward from the bar edge
- smoothness still depends on the host CPU refresh cadence
