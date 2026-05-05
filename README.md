# CPU Core Visualizer

Per-core CPU bars plus NVIDIA GPU, memory, disk, and network throughput history for DankBar / DankMaterialShell.

## What it does

- one bar per CPU core, plus dedicated GPU, memory, and disk sections
- a rolling one-minute network chart with separate download and upload scales
- slot-based section visibility and ordering for CPU, GPU, memory, disk, and network
- vivid or soft data-fill palettes while text and chrome follow the DankBar theme
- compact icons to distinguish CPU, GPU, memory, and disk sections
- selectable disk partitions for the disk usage section
- configurable network chart width, line thickness, and grid
- optional usage percentages plus adjustable probe time and smoother motion
- optional audio-output button with current-device icon and preferred-device selector row
- NVIDIA GPU popout details for utilization, VRAM, clocks, power, encoder/decoder usage, and top GPU-memory processes

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
5. Optional: enable **Show Audio Output Button** in the plugin settings

To install somewhere else, use:

```bash
./install.sh --target-dir /path/to/plugins/CpuCoreVisualizer
```

## Current limits

- top/bottom bars are the best-looking path right now
- left/right bars still use horizontal strips, but they now fill inward from the bar edge
- smoothness still depends on the host polling cadence
- rich GPU telemetry currently depends on `nvidia-smi`, so the GPU section is NVIDIA-only

## Audio output button

- enable **Show Audio Output Button** in the plugin settings to add a clickable sink button to the bar
- the button icon reflects the active output type: monitor for HDMI/display sinks, headset for headphones, otherwise speaker
- left-click the button to open the audio panel, then choose an output from the source icons at the top
- leave both output selectors on **Auto cycle all outputs** to show every available sink in that selector row
- set **Preferred Output 1** and **Preferred Output 2** to limit the selector row to just those preferred devices
