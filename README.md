# CPU Core Visualizer

Per-core CPU bars plus memory and disk usage strips for DankBar / DankMaterialShell.

## What it does

- one bar per CPU core, plus dedicated memory and disk sections
- vivid, soft-dark, mono, or UI-base rendering
- compact icons to distinguish CPU, memory, and disk sections
- selectable disk partitions for the disk usage section
- optional usage percentages plus adjustable probe time and smoother motion

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
