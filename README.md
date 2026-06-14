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
| **Engine** | **Godot 4.6** (Forward+) |
| **Renderer** | Forward+ (Vulkan / Metal via MoltenVK on macOS) |
| **Language** | GDScript only — no native plugins, no platform-specific code |
| **Art assets** | Bundled **CC0** photoscanned models (trees, rocks, ferns, grass) + CC0 PBR terrain textures + a CC0 sky HDRI, all in `assets/`. The world is still **assembled procedurally in code** (`WorldBuilder`): a custom splat-terrain shader, MultiMesh scatter, a reflective pond, glowing seams, god-ray shafts. No editor-authored scene tree. |
| **Audio assets** | **None required** — every cue, ambience and music layer is **synthesized procedurally at runtime** (royalty-free) through a `Master→{Music,Ambience,SFX,UI}` bus mix; transparently overridden if you drop files into `audio/`. |

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
| Dodge (i-frames) | **Left Ctrl** |
| Interact | **E** |
| Attack (Rootblade) | **Left Mouse** |
| Cast Simulation Pulse *(after upgrade)* | **Right Mouse** |
| The Sight (reveals wisp weak-seams) | **Q** / **F** · **R** = Lucid Cap |
| Toggle camera (1st/3rd person) | **C** |
| Journal / Inventory | **Tab** / **I** |
| Pause | **Esc** |
| Quick save / load | **F5** / **F9** |
| Toggle FPS counter | **F3** (or Settings → *Show FPS*) |
| **Gamepad** | Left stick move · right stick look · **A** jump · **B** dodge · **X** interact · **Y** Sight · **RB/RT** attack · **LB/LT** Pulse |

> **Combat tip:** open **the Sight** (Q) during a fight — wisps expose a glowing
> weak-seam and take far more damage, but the Sight drains Lucidity and raises
> Desync; let it fray too far and it collapses. Pick **Stillwater Lilies** at the
> pond to recover. Watch for the cold-violet **Dimmer**, which blinds you on a hit.

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
10. Afterwards, the shrine becomes an **Essence Sanctum** — spend Forest Essence
    (earned by defeating wisps) to acquire the other upgrades.
11. Pause anytime (**Esc**), open the **Journal** (Tab), change graphics, save/load.

A passive **Luminous Stag** also roams the First Layer and flees if approached.
The encounter now features **three Corrupted Wisps**; sprinting consumes
**stamina**; hits show **damage numbers** and a **hitmarker**; collected fragments
and seeker stats are logged in the **Journal** (Tab); defeated wisps drop
**Forest Essence**.

### Extra polish in this build

- Rolling **terrain** (flat in the clearing/path) with everything placed on the
  surface; **wind-swayed foliage**; procedural **moss/dirt ground**.
- A live **3D forest backdrop** behind the main menu.
- **Volumetric light shafts** (High), colour grading, vignette, and a **title
  card** + sky/fog shift at the transformation.
- **Camera shake** and a **death overlay** on hits; **objective beacon**;
  **typewriter** dialogue; ambient **birdsong/wind**.
- Procedurally-synthesized **audio** (no shipped files) for every cue + ambience.

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
you enter the forest. Also configurable: **render scale (50–100%, a perf lever
for weak hardware), mouse sensitivity, field of view, invert-Y look, master
volume, fullscreen toggle, resolution selector, and third-person camera
toggle**. All settings persist to `user://settings.cfg` (cross-platform).

### Navigation aids

- A **luminous trail** of runed stones appears at the transformation.
- A glowing **objective beacon** (light beam + bobbing diamond) marks the
  current goal in the First Layer — turn toward the glow to find Auralis, the
  nearest fragment, or the shrine.

---

## Performance notes

- **First launch auto-detects the GPU** (`SettingsManager._auto_detect_quality`)
  and picks a safe default: **Low + 70% render scale** on Apple Silicon /
  integrated GPUs, **High** on a discrete desktop card, Medium otherwise. The
  choice persists to `user://settings.cfg`; change it any time in Settings.
- **Measured on a base MacBook Pro M5** (Metal, Forward+): the scene renders
  comfortably at the 120 Hz display cap at **every** preset (GPU frame time well
  under the budget), i.e. far above the 30 fps floor — there is ample headroom.
- **Windows 11 gaming PC (e.g. 9950X3D / RTX 4080):** **High** with full density,
  4× MSAA, volumetric fog, and extended draw distance.
- Cost controls, cheapest-impactful first: the two fullscreen screen-read shaders
  (Sight + transformation) are **skipped while idle**; scattered foliage uses
  **distance culling** (`visibility_range`, pulled in further on Low); shadows
  drop to 2-split @1536 (Medium) / off (Low); MSAA and **render scale** are
  per-preset levers; textures are VRAM-compressed + mipmapped. Turn the **FPS
  counter** on (F3) to watch the budget while tuning.

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
    Fragment.gd          # collectible Fragments of Truth (+ lore)
  entities/
    Auralis.gd           # the guide spirit + dialogue + aura
    CorruptedWisp.gd     # hostile AI (idle/chase/telegraphed attack/death)
    LuminousStag.gd      # passive ambient creature
  combat/
    Projectile.gd        # Simulation Pulse magic projectile
    DamageNumber.gd      # floating combat numbers
  ui/                    # MainMenu, MenuBackdrop (3D), HUD, DialogueBox,
                         # PauseMenu, UpgradeMenu, Journal, SettingsPanel, UITheme
  util/MeshFactory.gd    # primitive mesh + material/aura factory
  util/SfxSynth.gd       # procedural 16-bit PCM sfx + ambience synthesis
  util/Content.gd        # all narrative strings (lore/dialogue)
shaders/
  screen_transition.gdshader  # transformation distortion/flash (canvas_item)
  rune_glow.gdshader          # pulsing tree runes (spatial)
  foliage_wind.gdshader       # per-instance wind sway for trees/bushes/grass
  sight.gdshader              # "the Sight" perceive-the-simulation overlay
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
