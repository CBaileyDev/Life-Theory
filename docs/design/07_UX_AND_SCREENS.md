# THE FIRST LAYER — UX & Screens

> *"Every menu is a seam. Look long enough and you'll see the loom behind it."*

This document specifies the front-end UX: splash, loading, main menu, settings, HUD, Codex, dialogue, and progression screens. All UI is code-built against `UITheme` (dark-fantasy palette: ink-black grounds, bone-white type, verdigris and bruise-violet accents; the **Sight** state shifts accents toward bioluminescent spore-cyan and adds chromatic flicker). Tone across every string: poetic, quiet, faintly wrong.

---

## 1. Splash Sequence

A single uninterrupted run, skippable after the first second by any input. Target ~7s total. Black grounds throughout; no music, only a low sub-bass drone and a single wood-creak.

| # | Duration | On-screen text | Notes |
|---|----------|----------------|-------|
| 1 | 1.6s | **TEND COLLECTIVE** *(studio)* | Bone-white wordmark fades up over black, fades out. |
| 2 | 1.4s | **Made with Godot Engine** | Required engine attribution, centered, low opacity. |
| 3 | 3.5s | **THE FIRST LAYER** / *A Magical Forest Simulation Mystery* | Title resolves via the **Sight-flicker reveal** (below). |

**Sight-flicker reveal.** The title field begins as soft forest noise — a still frame of green dark, indistinct. For ~0.8s the letters of **THE FIRST LAYER** strobe in and out as if the renderer is *deciding whether to draw them*: each glyph flickers individually with a 1-frame chromatic split (cyan/violet fringe), some glyphs arriving a beat late, before all snap to crisp bone-white. The subtitle then types in with a single soft chime. The effect implies the words were always there, under the image, waiting to be perceived — the game's whole thesis in one second.

---

## 2. Loading Screens

**Layout.** Full-bleed dark plate. Lower third reserved for UI. A single italic **LORE TIP** sits left-aligned at lower-left, max two lines. The diegetic progress concept sits bottom-center. Upper area holds a slow, near-still vignette of the destination stratum (parallax drift only). No spinner.

**Diegetic progress — "The Pulse."** Instead of a bar, a thin horizontal line of faint glyphs (the world's lattice) fills left-to-right as a **Simulation Pulse** travels along it, brightening glyphs as it passes. The label reads **RENDERING THE LAYER…** then, at completion, **THE LAYER HOLDS.** Loads under ~2s show only the held state. Tips rotate every 4s, no repeat until pool exhausts.

**Lore tip pool (rotating, in-world):**

1. *The forest was here before you arrived, and rehearsed for you.*
2. *Corrupted Wisps are not angry. They are only loops that forgot their reason.*
3. *A Fragment of Truth weighs nothing until you carry two.*
4. *Forest Essence is grief that learned to photosynthesize.*
5. *The Rootblade does not cut things. It cuts the rendering of things.*
6. *Auralis remembers every path you took. Auralis does not remember why.*
7. *Sight is not a light you switch on. It is a numbness that finally fades.*
8. *Beauty is the layer's oldest defense. Distrust the calmest glade.*
9. *Every shrine is an apology no one was alive to receive.*
10. *The Pulse is the world breathing. Hold still and you'll feel it count you.*
11. *Nothing in the First Layer is false. It is only unfinished.*
12. *A path you have walked twice will start to walk back.*
13. *The deeper strata are not darker. They are simply less polite.*
14. *Wisps gather where someone was loved too imprecisely.*
15. *You did not find the shrine. The shrine ran out of ways to avoid you.*
16. *Essence spent is memory you agree to stop keeping.*
17. *The map is accurate. The territory is the lie.*
18. *To see the seam is to be seen by it.*
19. *Quietwood is the kindest thing the Tend could bring themselves to build.*
20. *The mushrooms do not grant the Sight. They confess it.*
21. *Save often. The layer edits what you are not watching.*
22. *An ending is a place you stop tending, not a place that stops.*

---

## 3. Main Menu

**Structure.** Vertical option stack, lower-left. Title wordmark upper-left. The remaining frame is a living scene: a slow camera push through Quietwood, drifting spores, a distant **beacon** pulse on the horizon. Hovering an option warms its label and nudges a faint Sight-fringe onto the live scene behind it.

**Idle / motion behavior.** After ~30s of no input, the scene "notices": ambient audio thins, a single Corrupted Wisp drifts across frame, and one menu glyph flickers as in the splash. Returns to calm on any input. Subtle, never alarming.

**IA + microcopy:**

| Option | Behavior | Microcopy / state |
|--------|----------|-------------------|
| **Continue** | Loads most recent save. Top of list when a save exists; hidden on first launch. | Sub: *"Return to the layer. It kept your place."* |
| **New Game** | Difficulty + brief intent prompt, then descent. | Sub: *"Step in for the first time."* Confirm if overwriting: *"This will fold an existing path. Begin anew?"* |
| **Chapters** | Replay unlocked strata from any checkpoint. Locked entries shown as redacted glyphs. | Locked tooltip: *"This layer has not yet held for you."* |
| **Settings** | Opens Settings hub (§4). | — |
| **Extras** | Bestiary gallery, concept art, sound test, credits. | Sub: *"What the layer let you keep."* |
| **Quit** | Confirm dialog. | Confirm: *"Leave the layer rendering? It will continue without you."* / **Stay** · **Leave** |

---

## 4. Settings

Hub with grouped tabs. Every control shows a one-line tooltip on focus. **Apply** / **Revert** / **Defaults** footer; unsaved changes warn on exit.

**Display**
- **Window Mode** — *Fullscreen, Borderless, Windowed.* — "How the layer fills your screen."
- **Resolution** — native list. — "Pixel grid of the rendered world."
- **Monitor** — output select. — "Which screen the layer holds on."
- **V-Sync** — On/Off/Adaptive. — "Stop the image from tearing along its seam."
- **Frame Rate Cap** — 30/60/120/144/Unlimited. — "Limit how often the world redraws."

**Graphics**
- **Quality Preset** — *Low / Medium / High / Custom.* — "A bundle of the settings below."
- **Render Scale** — 50%–200% slider. — "Render sharper or softer than your screen, then resample."
- **Shadows / Foliage Density / Effects / Post-Processing** — Low/Med/High each. — "Detail of cast dark / undergrowth / particles / final image grade."
- **Sight Bloom Intensity** — slider. — "How brightly the Sight overlay blooms. Lower it if it overwhelms."

**Audio**
- **Master / Music / Ambience / SFX / Dialogue** — sliders. — "Overall / score / forest tone / sound effects / spoken lines."
- **Subtitle Audio Cues** — On/Off. — "Show captions for important non-speech sound."
- **Dynamic Range** — Full/Night. — "Night flattens loud peaks for quiet listening."

**Controls**
- **Input Device** — Keyboard+Mouse / Gamepad (auto-detect).
- **Mouse Sensitivity / Invert Y / Gamepad Sensitivity / Stick Deadzone** — sliders & toggles.
- **Rebind Keys** — per-action list (Move, Look, Interact, Attack, **Sight**, Journal, Beacon, Sprint, Dodge, Pause). Press-to-bind, conflict warning, **Reset Binding** per row. — "Reassign any action. Conflicts are flagged in violet."

**Gameplay**
- **Difficulty** — *Wanderer / Seeker / Residual.* — "Wanderer: forgiving. Seeker: intended. Residual: the layer pushes back."
- **Sight Assist** — Off / Subtle / Guided. — "How strongly the Sight highlights seams, paths, and Fragments."
- **Combat Hints** — On/Off. — "Telegraph Wisp attacks more visibly."
- **Auto-Save Frequency** — Frequent/Normal/Checkpoint-only. — "How often the layer records your place."

**Accessibility**
- **Colorblind Mode** — Off / Protanopia / Deuteranopia / Tritanopia. — "Re-tunes the verdigris/violet palette for clarity."
- **Subtitles** — On/Off. — "Show all spoken dialogue as text."
- **Subtitle Size** — S/M/L/XL. · **Subtitle Background** — None/Soft/Solid. — "Readability of caption text and its backing."
- **Speaker Names** — On/Off. — "Label who is speaking."
- **Text Size (UI)** — S/M/L/XL. — "Scale all menu and HUD text."
- **Motion Reduction** — On/Off. — "Calms idle drift, parallax, and the Sight flicker."
- **Screen Shake** — slider 0–100%. — "Reduce or remove camera shake."
- **Flash Reduction** — On/Off. — "Dim the Sight strobe and Pulse flares."
- **Hold vs Toggle** — per-action (Sight, Sprint, Crouch). — "Press once to toggle, or hold to sustain."
- **Aim/Interact Assist** — Off/Light/Strong. — "Gently steer the crosshair toward valid targets."

---

## 5. HUD

Minimal, fades when idle. **Health** (lower-left, a vein-like bone arc) and **Stamina** (thin sub-arc beneath) only render when not full or in combat. **Crosshair** is a faint four-spore reticle; **hitmarker** is a brief violet bloom, kill = cyan dissolve. **Quest tracker** upper-right: current objective in one poetic line plus a distance-to-**beacon** chevron. **Sight meter** lower-center: a small filling glyph showing remaining Sight charge; pulses when low. A persistent **vignette** darkens edges, intensifying in Sight and at low health. **Essence/Fragment** counters appear only briefly on pickup, then fade.

---

## 6. Codex / Journal (Tab key)

Left-rail tabbed reader; pages render as aged lattice-paper with bone type. New entries glow until read.

- **Story** — chronological recovered narrative; redacted lines un-redact as Fragments are found.
- **Characters** — Auralis, the Seeker, the Tend; entries grow more unsettling with progress.
- **Bestiary** — Corrupted Wisps and variants; weaknesses revealed only after defeating each type.
- **Items** — Ancient Rootblade, Forest Essence, Fragments of Truth, consumables; flavor + function.
- **Sight** — catalog of seams perceived; doubles as a Sight-tutorial and lore index.
- **Map** — stylized stratum map; "accurate map, lying territory." Beacons, shrines, save points pinned. Fog over unrendered regions.

Footer hint: *"Knowledge here is partial. So is everything."*

---

## 7. Dialogue UX

Letterboxed lower-third panel. Speaker name (toggleable) in verdigris; lines **typewriter**-reveal with a soft per-glyph tick. Tap input to fast-complete the current line, tap again to advance. Auralis's lines occasionally glitch one word into a corrected word (e.g., ~~remember~~ *render*) to seed unease. Choice prompts appear as 2–3 stacked options with brief consequence-agnostic phrasing; a faint Pulse marks the line the layer "prefers." Skippable, fully subtitled, with a backlog scroll on hold.

---

## 8. Upgrade / Skill UX

A diegetic **shrine** node-tree, not a stat list. Forest Essence is the currency; Fragments of Truth unlock gated branches. Nodes are dim glyphs that bloom cyan when affordable. Three boughs: **Edge** (Rootblade combat), **Sight** (perception range, seam-reading, slow-time glimpses), **Root** (vitality, stamina, Essence efficiency). Selecting a node shows name, cost, current→next values, and an in-world descriptor (*"The blade learns the shape of unreal things."*). Refund allowed at any shrine for partial Essence: *"Unlearn? The layer rarely minds."*

---

## 9. Build Order

1. **UITheme + Main Menu shell** — establishes palette, fonts, navigation, button states.
2. **Settings (Display/Audio/Accessibility first)** — needed for QA on varied hardware; Controls/rebinding next.
3. **HUD core** — health/stamina, crosshair/hitmarker, vignette; unblocks playtesting.
4. **Pause menu** — reuses Settings + Main Menu components.
5. **Dialogue system** — typewriter + subtitles; gates narrative testing.
6. **Loading screens + lore tips** — cheap, high-polish, hides streaming.
7. **Codex/Journal** — content-driven, can grow alongside the game.
8. **Upgrade shrine** — last, once combat/economy values are tuned.
9. **Splash sequence** — final polish pass; trivial to slot in, best tuned against shipped audio.
