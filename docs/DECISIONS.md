# Engineering decisions & rationale

A log of the strong, reasonable decisions made while building the prototype,
so the choices are auditable and easy to revisit.

## Engine: Godot 4.x (Forward+)
- **Why Godot over Unity URP:** the brief expressed a strong preference for
  Godot, and Godot's project is 100% text (`.tscn`/`.gd`/`.tres`/`.gdshader`),
  which is ideal for a reviewable, diff-able, dependency-free prototype. It
  exports natively to macOS (universal / Apple Silicon) and Windows with no paid
  tiers or native plugins.
- **Why not Unreal:** too heavy for a base MacBook Pro M5 vertical slice, per the
  brief's own guidance.
- **Renderer = Forward+:** good lighting/glow on both Metal (macOS via MoltenVK)
  and Vulkan/D3D12 (Windows). Quality presets scale shadows/SSAO/MSAA/glow rather
  than swapping renderers (the renderer is a project-level setting in Godot and
  cannot change at runtime).

## Procedural everything (no binary art)
- The world, creatures, UI, and effects are built from engine primitives,
  code-generated `StandardMaterial3D`s, particles, and two small shaders.
- **Why:** guarantees zero copyrighted/third-party assets, keeps the repo tiny,
  and makes the project import-and-run anywhere. `MeshFactory` and the entity
  scripts are the seams where authored/CC0 models can later drop in.

## Code-built scenes & UI
- `.tscn` files are intentionally minimal (a root node + a script); each script
  builds its subtree in `_ready()`.
- **Why:** hand-authoring large `.tscn`/Control trees as text is error-prone;
  code-building is deterministic, fully reviewable, and avoids fragile editor
  serialization. UI styling lives in one place (`UITheme`).

## Input map registered in code (`Boot.gd`)
- Actions (move/jump/sprint/interact/attack/cast/pause/etc.) are added via
  `InputMap` at startup instead of being serialized into `project.godot`.
- **Why:** the binary-ish input serialization in `project.godot` is brittle to
  hand-write; registering in code is robust across 4.x point releases and is a
  single, readable source of truth (also the seam for future gamepad support).

## Central `GameState` autoload with signals
- One source of truth for world state, quest step, fragments, health, and the
  chosen upgrade; UI/gameplay observe it via signals.
- **Why:** decouples systems (the shrine doesn't know about the HUD), survives
  scene changes, and makes save/load a simple `to_dict`/`from_dict`.

## Forgiving prototype rules
- Invisible boundary walls + a fall-reset respawn keep the player in-bounds.
- Death respawns at the trailhead at full health rather than ending the run —
  appropriate for a 10–15 minute slice.

## Static typing & duck-typing
- Cross-node calls that rely on duck-typing (e.g. the player calling the HUD's
  `set_prompt`) use untyped variables or explicit `as` casts, because GDScript's
  analyzer rejects unknown members on statically-typed base classes. This was a
  deliberate, audited choice rather than dropping typing everywhere.

## Verification approach (important)
- This was authored in a headless environment **without a Godot binary**, so it
  could not be run or imported here. Every script was hand-reviewed for Godot
  4.x API correctness (node types, enums, signal/`Tween`/particle APIs, typed-vs-
  duck-typed access, in-tree requirements for `look_at`). Known residual risks
  are listed in the README's *Known issues*. The first editor import is the
  natural place to catch anything missed; the architecture keeps any such fixes
  local and small.
