# Build & export guide

> Summary lives in the root `README.md`. This is the detailed reference.

## Versions
- Built against **Godot 4.2+** (standard build, **not** Mono/.NET).
- `project.godot` declares `config/features = ("4.2", "Forward Plus")`. Opening
  in a newer 4.x is fine; Godot may offer to bump the version.

## Editor run
1. Install Godot 4.2+ from <https://godotengine.org/download>.
2. **Import** `project.godot` → **Import & Edit**.
3. **F5** to play. Main scene is `scenes/MainMenu.tscn`.

## Export templates (required once per machine/version)
**Editor → Manage Export Templates → Download and Install.** Templates **must
match** your editor version exactly.

## Windows 11 export
- **Project → Export → Windows Desktop** (preset 0 in `export_presets.cfg`).
- Architecture `x86_64`, `binary_format/embed_pck = true` → a single `.exe`.
- **Export Project** → `exports/windows/TheFirstLayer.exe`.
- Optional: install `rcedit` (Editor Settings → Export → Windows) so Godot can
  embed the icon/version metadata. Not needed to run.
- Run: copy the `.exe` to Windows 11 and double-click. Windows SmartScreen may
  warn about an unsigned binary (expected for an unsigned prototype).

## macOS export
- **Project → Export → macOS** (preset 1).
- `binary_format/architecture = universal` (Apple Silicon + Intel), min macOS 11.
- **Export Project** → `exports/macos/TheFirstLayer.dmg` (or choose `.zip`/`.app`).
- **Codesigning / notarization** are **disabled** in the preset for instant local
  test builds. For distribution:
  1. In the preset, enable `codesign/codesign` and `notarization/notarization`.
  2. Provide a **Developer ID Application** certificate.
  3. Provide notarization credentials (App Store Connect API key, or Apple ID +
     app-specific password + team ID).
  4. Export; Godot signs, submits for notarization, and staples the ticket.
- **Local test bypass (unsigned):** right-click the `.app` → **Open**, or
  `xattr -dr com.apple.quarantine TheFirstLayer.app`.

## Cross-platform guarantees (enforced in code)
- File I/O only via `res://` (read-only assets) and `user://` (saves/settings),
  which resolve to the correct per-OS locations — **no absolute paths anywhere**.
- Input via the engine `InputMap` (registered in `scripts/autoload/Boot.gd`).
- Audio via `AudioStreamPlayer` (engine-native).
- Rendering via the standard Forward+ renderer; the two `.gdshader` files use only
  portable features (no compute, no platform intrinsics).
- Graphics presets (Low/Medium/High) scale shadows, SSAO, MSAA, glow, and foliage
  density; default is Medium.

## If the first import reports an error
Because this project was authored without a local Godot binary, run a first
import and check the **Errors/Output** panel. The codebase is modular, so any fix
is localized to one script. Common first-import items to glance at: a node-type
or enum name that shifted between 4.x minor versions. None are expected, but this
is the recommended validation pass.
