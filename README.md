# The First Layer
### *A Magical Forest Simulation Mystery* — playable vertical slice

You wake in a quiet forest: trees, mist, a narrow trail. At the end of the path,
an ancient shrine cradles a glowing mushroom. Touch it, and the world *shifts* —
fog turns violet, runes bloom on the trees, a luminous trail unfurls, and a
spirit of light named **Auralis** tells you the truth:

> *"The forest is not the world. It is the first layer."*

Gather three Fragments of Truth, survive the Corrupted Wisps that now stalk the
clearing, return to the shrine, and choose what kind of seeker you become.

This repository is a **complete, runnable Godot 4.x prototype** — the first
10–15 minutes of a premium magical-forest RPG/survival-mystery — built to run on
**macOS (Apple Silicon)** and **Windows 11**.

---

## Engine & required tools

| | |
|---|---|
| **Engine** | **Godot 4.x** (use 4.2+; **validated headlessly against 4.3-stable**) |
| **Renderer** | Forward+ (Vulkan / Metal via MoltenVK on macOS) |
| **Language** | GDScript only — no native plugins, no platform-specific code |
| **Art assets** | **None required** — the entire world is generated procedurally from engine primitives + custom materials/shaders |
| **Audio assets** | **None required** — every cue + ambience is **synthesized procedurally at runtime** (royalty-free), and is transparently overridden if you drop files into `audio/` (see `audio/README.md`) |

Download Godot 4.x (Standard, *not* the .NET/C# build) from <https://godotengine.org/download>.

---

## How to run in the editor

1. Install Godot 4.2+ (standard build).
2. `git clone` this repository.
3. Launch Godot → **Import** → select `project.godot` in the project root → **Import & Edit**.
4. Press **F5** (Play). The game boots to the main menu; click **Start Game**.

> First launch compiles shaders and imports the SVG icon — give it a few seconds.

There is **no build step** and **no external dependency** to fetch.

---

## Controls

| Action | Key / Button |
|---|---|
| Move | **W A S D** (or arrow keys) |
| Look | **Mouse** |
| Sprint | **Shift** (hold, while moving forward) |
| Jump | **Space** |
| Interact | **E** |
| Attack (Rootblade) | **Left Mouse** |
| Cast Simulation Pulse *(after upgrade)* | **Right Mouse** |
| Toggle camera (1st/3rd person) | **C** |
| Inventory / menu action | **Tab** / **I** |
| Pause | **Esc** |
| Quick save / load | **F5** / **F9** |

---

## Gameplay walkthrough (the full vertical slice)

1. **Start** from the main menu → spawn at the trailhead.
2. **Walk the path** (forward) into the central clearing.
3. **Find the glowing mushroom** on the shrine; press **E** to touch it.
4. **The transformation:** screen distortion + flash, a particle burst, the
   lighting cools to violet, runes ignite on the trees, and a **luminous trail**
   appears. *(World State 1 → World State 2.)*
5. **Meet Auralis**, the glowing deer-spirit guide (press **E**). It explains the
   first layer and points you to the fragments.
6. **Collect 3 Fragments of Truth** — floating golden shards around the clearing
   (walk into them). The HUD counter tracks `x/3`.
7. **A Corrupted Wisp** (or more) detects you and attacks — **Left-Click** with
   the Ancient Rootblade to destroy it (3 hits).
8. **Return to the shrine** and press **E** to commune.
9. **Choose your first upgrade** from four paths; it applies immediately.
10. Pause anytime (**Esc**), change graphics quality, save/load, and explore.

A passive **Luminous Stag** also roams the First Layer and flees if approached.

---

## Graphics settings

Set in the main menu or pause menu → **Settings**. Defaults to **Medium**.

| Preset | Shadows | Glow (bloom) | SSAO | MSAA | Foliage density* |
|---|---|---|---|---|---|
| **Low** | off | off | off | off | ~0.55× |
| **Medium** | on | on | off | 2× | ~0.85× |
| **High** | on | on | on | 4× | ~1.2× |

**High** additionally enables **volumetric fog** for soft light shafts in the
mist (the most expensive effect — kept off below High for the MacBook target).
All presets use a cinematic colour grade (contrast/saturation), bloom, a
procedural moss/dirt **ground shader**, and **wind-swayed foliage**.

\* Foliage/tree density is chosen when the forest is built. Changing quality
mid-run updates lighting/AA instantly; the new density takes effect next time
you enter the forest. Also configurable: **mouse sensitivity, field of view,
invert-Y look, master volume, fullscreen toggle, resolution selector, and
third-person camera toggle**. All settings persist to `user://settings.cfg`
(cross-platform).

### Navigation aids

- A **luminous trail** of runed stones appears at the transformation.
- A glowing **objective beacon** (light beam + bobbing diamond) marks the
  current goal in the First Layer — turn toward the glow to find Auralis, the
  nearest fragment, or the shrine.

---

## Performance notes

- **Base MacBook Pro M5:** target **Low/Medium**. Forward+ runs on Metal via
  MoltenVK; glow and shadows are the main costs, both off at Low.
- **Windows 11 gaming PC:** **Medium/High** comfortably.
- The world is ~140 trees + foliage at full density, all simple primitives with
  trunk-only collision, so geometry cost is modest. The biggest tunables are
  shadows, MSAA, and the screen-distortion effect (only active for ~1.5s during
  the transformation).

---

## How to build for macOS

1. Open the project in Godot 4.x **of the same version** you'll export with.
2. **Editor → Manage Export Templates → Download and Install** (matches your version).
3. **Project → Export**. The `macOS` preset is already defined
   (`export_presets.cfg`): universal binary (Apple Silicon + Intel), min macOS 11.
4. Click **Export Project** → output to `exports/macos/TheFirstLayer.dmg` (or `.zip`).
5. **Signing / notarization (for distribution):** the preset ships with codesign
   and notarization **disabled** so you can build a local test app immediately.
   To distribute outside your machine you must:
   - Set `codesign/codesign` and `notarization/notarization` in the preset,
   - Provide an Apple Developer ID certificate + an App-Store-Connect API key /
     Apple ID app-specific password,
   - Or, for local testing only, right-click the app → **Open** to bypass
     Gatekeeper, or run `xattr -dr com.apple.quarantine TheFirstLayer.app`.

## How to build for Windows 11

1. Same Godot version; install export templates as above.
2. **Project → Export** → **Windows Desktop** preset (already defined): x86_64,
   PCK embedded in the `.exe`.
3. **Export Project** → output to `exports/windows/TheFirstLayer.exe`.
4. Copy the single `.exe` to the target Windows 11 machine and double-click it.
   (Optional: install `rcedit` so Godot can stamp the icon/metadata; not required
   to run.)

> Cross-platform guarantees in the code: all file access uses `res://` / `user://`
> (never absolute OS paths), input is registered via the engine `InputMap`
> (`scripts/autoload/Boot.gd`), audio uses `AudioStreamPlayer`, rendering uses the
> standard renderer, and the two shaders avoid platform-specific features.

---

## Project structure

```
project.godot            # engine config, autoloads, renderer, window
export_presets.cfg       # macOS + Windows export presets
icon.svg
scenes/
  MainMenu.tscn          # entry scene (root + script; UI built in code)
  Forest.tscn            # gameplay level (root + script; world built in code)
scripts/
  autoload/              # globals (singletons)
    Boot.gd              #   registers the input map in code
    SettingsManager.gd   #   graphics/input/audio settings + persistence
    AudioManager.gd      #   audio cue hooks (file-driven, silent if missing)
    SaveManager.gd       #   cross-platform ConfigFile save/load
    GameState.gd         #   world/quest/inventory/health — source of truth
  player/Player.gd       # FPS/TPS controller, combat, interaction, magic
  world/
    WorldBuilder.gd      # procedural forest, path, boundaries, hidden layer
    Forest.gd            # level orchestration + transformation + graphics
  interaction/
    MushroomShrine.gd    # the artifact + shrine (interactable)
    Fragment.gd          # collectible Fragments of Truth
  entities/
    Auralis.gd           # the guide spirit + dialogue
    CorruptedWisp.gd     # hostile creature AI (idle/chase/attack/death)
    LuminousStag.gd      # passive ambient creature
  combat/Projectile.gd   # Simulation Pulse magic projectile
  ui/                    # MainMenu, HUD, DialogueBox, PauseMenu, UpgradeMenu,
                         # SettingsPanel, UITheme (dark-fantasy styling)
  util/MeshFactory.gd    # primitive mesh + material factory
  util/SfxSynth.gd       # procedural 16-bit PCM sfx + ambience synthesis
shaders/
  screen_transition.gdshader  # transformation distortion/flash (canvas_item)
  rune_glow.gdshader          # pulsing tree runes (spatial)
  foliage_wind.gdshader       # per-instance wind sway for trees/bushes/grass
  ground.gdshader             # procedural moss/dirt fBm forest floor
audio/                   # empty hooks + README (drop OGG/WAV here)
assets/  materials/      # placeholders; prototype is fully procedural
docs/                    # DESIGN, DECISIONS, BUILD
```

Systems are separated (player, interaction, quest/world state, enemy AI, combat,
upgrades, UI, settings, save) and no file is a monolith.

---

## Known issues / limitations

- **Validation:** the project was authored without an editor GUI, but it has been
  validated against **Godot 4.3-stable** headlessly: a clean `--import` (no parse
  errors), clean runs of both scenes, and a scripted smoke test of the full quest
  flow (transformation → guide → 3 fragments → shrine → upgrade → combat) and all
  audio cues. It has not been play-tested with a mouse/keyboard on a real GPU, so
  expect to tune feel (movement speed, combat timing, fog/exposure) to taste.
- **Procedural audio is intentionally simple** (synthesized tones/pads). It's
  meant as honest placeholder feedback; drop royalty-free OGGs in `audio/` to
  override any cue with real sound.
- Graphics-quality **foliage density** changes apply on next level entry, not live
  (lighting/AA do update live).
- The headless console prints harmless `Parameter "m" is null` renderer messages
  because there's no GPU in headless mode; these do not occur in a normal run.

---

## Recommended next development steps

1. Add royalty-free audio (ambience + the catalogued SFX) to `audio/` — it
   transparently overrides the synthesized fallback, zero code changes.
2. Surface-aware footstep sounds (grass vs. dirt vs. stone).
3. Replace primitive trees/creatures with authored/CC0 models via the same
   `MeshFactory`/scene seams.
4. A proper save/continue slot UI (single-slot quick save/load already works).
5. More creature variety and a light stamina/essence economy.
6. A short opening title card / cinematic for the transformation.
7. Gamepad bindings (the `InputMap` is already centralised in `Boot.gd`).

---

## Content note

The mushroom is a **mystical fantasy artifact** and a symbolic gateway to a
hidden "simulation" layer — it is not a depiction of real drug use. The game
treats it as magical, symbolic, and fictional. No third-party names, characters,
music, UI, lore, or assets are used; all inspiration sources informed *systems
and atmosphere only*.
