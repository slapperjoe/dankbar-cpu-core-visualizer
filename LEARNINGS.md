# DMS Plugin Development Learnings

## Critical Architecture Facts (AvengeMedia/DankMaterialShell)

### Plugin Manifest Requirements
- `type` must be a **string** ("widget", "daemon", "launcher", "desktop"). Arrays like `["widget", "desktop-widget"]` cause silent rejection by the plugin scanner.
- `permissions` array controls what the plugin can do. `settings_write` is required for saving settings.

### PluginComponent (Widget QML)
- **No `stringSetting()`, `boolSetting()`, `setString()`, `setBool()`** — these methods do NOT exist on `PluginComponent`.
- Read settings via: `pluginData["key"] || defaultValue`
- Write settings via: `pluginService.savePluginData(pluginId, key, value)`
- `pluginData` is a dict-like object populated from `SettingsData.getPluginSettingsForPlugin(pluginId)`
- `pluginService` is injected by `PluginService.loadPlugin()` with `{ "pluginService": root }`

### PluginSettings (Settings QML)
- Extends `Item`, provides `saveValue(key, value)` and `loadValue(key, defaultValue)` methods
- Does NOT have `pluginData.stringSetting()` — these methods don't exist
- Use `StringSetting` and `ToggleSetting` components from `qs.Modules.Plugins` for settings UI
- `StringSetting`: auto-handles load/save via `findSettings()` → `settings.saveValue()`
- `ToggleSetting`: same pattern, handles bool settings
- `PluginSettingsRow`, `PluginSettingsSelector`, `PluginSettingsToggle` do NOT exist in DMS — these are custom/named-wrong components

### Audio / Pipewire API
- `Pipewire.sinks` does NOT exist as a property
- Get sinks via: `Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream)`
- `PwNode` properties: `name`, `description`, `audio`, `isSink`, `isStream`
- Change default sink: `Pipewire.preferredDefaultAudioSink = node`
- `Pipewire.defaultAudioSink` returns the current default `PwNode`
- `AudioService` is a DMS-side singleton wrapping Pipewire for sound playback and volume control

### Plugin Loading Flow
1. `PluginService.resyncAll()` scans `~/.config/DankMaterialShell/plugins/` for `plugin.json`
2. Manifests are parsed; if `type` is an array, manifest is marked `bad` and skipped
3. `enablePlugin()` calls `SettingsData.setPluginSetting(pluginId, "enabled", true)` then `loadPlugin()`
4. `loadPlugin()` uses `Qt.createComponent(url, Component.PreferSynchronous)`
5. If QML has compile-time errors (e.g., referencing non-existent components/properties), component creation fails with `Component.Error`
6. Failed loads trigger `pluginLoadFailed()` signal → DMS shows "Failed to enable plugin: <name>"
7. Bump `version` in `plugin.json` to force cache busting after QML fixes
8. `console.error()` in `Component.onCompleted` writes to stderr — visible in DMS terminal output

### Minimal Working Plugin
- Stripped widget to bare-bones `PluginComponent` with only `horizontalBarPill`
- No `Pipewire` import, no `QtQuick.Layouts`, no `ColumnLayout`
- Settings reduced to single `StringSetting` inside `PluginSettings`
- `pluginData["key"] || default` for reading, `pluginService.savePluginData()` for writing

### Common Pitfalls
- Shadowing `pluginData` property kills settings access
- Calling non-existent methods (`stringSetting`, `setString`) causes QML compilation failure → plugin won't load
- Using non-existent components (`PluginSettingsRow`, `PluginSettingsSelector`, `PluginSettingsToggle`) → compilation failure
- `Pipewire.sinks` doesn't exist → use `Pipewire.nodes.values.filter(...)`
- `HoverHandler` does NOT exist in DMS → use standard `MouseArea` with `hoverEnabled: true`
- `barHovered` property does NOT exist on `PluginComponent` → don't reference it
- Missing `import QtQuick.Layouts` when using `ColumnLayout`, `RowLayout`, or `Layout.fillWidth` → causes silent QML compilation failure
- `PopoutComponent` is available via `qs.Modules.Plugins` and provides `closePopout()` callback for closing the popout
- `MouseArea.onWheel` receives an `event` object with `angleDelta.y` for scroll direction

## Bar Pill Rendering & Click Handling (DMS BasePill)

### BasePill QML Structure
- `BasePill.qml` is the visual wrapper for bar widgets. It:
  1. Uses `ContentLoader` (`pillContentLoader`) to load the pill component from `horizontalBarPill` / `verticalBarPill`
  2. Wraps the `ContentLoader` in a `MouseArea` that handles **all** interaction:
     - Left-click → `pillClickAction` callback
     - Right-click → `pillRightClickAction` callback
     - Mouse wheel → cycles through sinks or scrolls
      - Hover → changes background transparency (does NOT auto-show popout)
   3. Popout is NOT shown on hover — it must be explicitly triggered via `pillClickAction` or `pillRightClickAction` calling `root.triggerPopout()`
  4. `popoutWidth` and `popoutHeight` control popout dimensions

### Pill Content Requirements
- The pill component (e.g., `horizontalBarPill`) MUST have implicit dimensions
- A bare `MouseArea` has **no implicit size** → pill renders invisible/empty
- Use `Row` with `DankIcon` and `StyledText` (has natural implicit width from text)
- **Do NOT** put a `MouseArea` inside the pill — `BasePill` already provides one
- Interaction is routed through `pillClickAction` and `pillRightClickAction` callbacks

### Popout Content
- `popoutContent` takes a `Component` with `PopoutComponent`
- `PopoutComponent` has `closePopout()` to dismiss the popout after selecting a sink
- The popout is shown on hover by default; `pillRightClickAction` can be used to toggle it
- `PopoutComponent` extends `Column`, provides `headerText`, `detailsText`, `showCloseButton`, `closePopout`, `parentPopout`
- `closePopout` callback is injected by `PluginPopout.onLoaded` — calling it closes the popout
- `parentPopout` reference is also injected for accessing the parent `DankPopout`

## DankIcon & Material Symbols Icons
- `DankIcon` wraps `StyledText` with Material Symbols Rounded font
- **Icon names MUST be valid Material Symbols names** — `"audio"` is NOT a valid name
- Valid names: `"volume_up"`, `"volume_down"`, `"headphones"`, `"speaker"`, `"headset"`, `"cast_connected"`, etc.
- Find available icons in `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].codepoints`
- `DankIcon` properties: `name` (icon text), `size` (font pixelSize), `color`, `filled` (FILL axis 0 or 1)
- `DankIcon` has `implicitWidth` and `implicitHeight` based on `size`

## PluginPopout & Popout Triggering
- `PluginPopout` wraps `DankPopout` and manages `popoutContent` loading
- `popoutTarget` on `BasePill` is set to `pluginPopout` for context/position setup
- Popout is **not** shown on hover — it must be explicitly triggered
- Call `root.triggerPopout()` from `pillRightClickAction` to show the popout on right-click
- `PopoutComponent` is the content wrapper with header, details, and `closePopout()` callback

## triggerPopout() Early-Return Bug
- `PluginComponent.triggerPopout()` checks `if (pillClickAction)` and calls it, then returns early
- This means if `pillClickAction` is defined, calling `triggerPopout()` will **never** reach the popout toggle code
- **Workaround**: call `pluginPopout.toggle()` directly from `pillRightClickAction` instead of `root.triggerPopout()`
- `pluginPopout` is a child `PluginPopout` in `PluginComponent` — accessible by `id` from the extending widget

## Popout Positioning Requirements
- `pluginPopout.toggle()` alone is insufficient — popout must be positioned first
- Call `pluginPopout.setTriggerPosition(x, y, width, section, screen, barPosition, barThickness, barSpacing, barConfig)`
- Use `SettingsData.getPopupTriggerPosition()` to compute the correct screen position based on bar edge
- Without `setTriggerPosition`, the popout appears at (0,0) — effectively invisible
- `barPosition` is derived from `axis?.edge`: top=0, bottom=1, left=2, right=3
- `qs.Services` must be imported for `SettingsData`

## pillRightClickAction Signature
- `BasePill.onRightClicked` checks `pillRightClickAction.length`
- If length is 0, calls `pillRightClickAction()` with no arguments
- If length > 0, calls `pillRightClickAction(pos.x, pos.y, pos.width, section, currentScreen)`
- The 5-arg version receives position data from `SettingsData.getPopupTriggerPosition()`
- Inside the action, `pluginPopout`, `barConfig`, `barThickness`, `barSpacing`, `section`, and `axis` are all inherited from `PluginComponent`
- `pluginPopout` is accessible by ID from the widget file

## Plugin Caching & Version
- Version bump in `plugin.json` may NOT bust the QML cache
- DMS uses `Qt.createComponent(url, Component.PreferSynchronous)` which caches components
- To force reload: restart DMS completely or clear `~/.cache/quickshell/`
- Cached QML files may persist across sessions unless explicitly cleared
