# 06 — Audio & Music Direction

> *"The forest sounds true. Listen closely, and you'll hear the seams."*

This document is the production bible for all sound in **The First Layer**. It
assumes the current architecture: `AudioManager` (autoload) resolves
`AudioManager.play("<cue>")` against `res://audio/sfx/`, `play_ambience("<name>")`
against `res://audio/ambience/`, and falls back to `SfxSynth` procedural
generation when no file exists. Everything below is wired so a programmer can
drop OGGs in later with zero code changes, and so the synth placeholders can be
extended in the meantime.

---

## 1. Musical Identity

**Emotional thesis:** calm and poetic on the surface, *quietly wrong* underneath.
The Natural Forest should feel like a held breath of beauty; the First Layer
should feel like that same beauty rendered too perfectly — uncannily clean,
faintly mathematical, alive in the wrong way.

### Instrumentation palette
- **Acoustic / organic core (Natural):** felted upright piano, nylon guitar
  harmonics, bowed cello swells, low wood flute, hand percussion, breath/air.
- **Hybrid / processed layer (First Layer):** the *same* instruments resampled,
  granular-stretched, pitch-shifted into glassy pads; bowed crotales, prepared
  piano, sine sub, soft analog-modeled saw drones.
- **Synthetic / truth layer:** pure sine tones, detuned beating pairs (2–4 Hz
  beating = "the simulation breathing"), bit-reduced bell partials, reversed
  reverb tails. This palette is exactly what `SfxSynth.tone()` already produces —
  lean into it as a *diegetic signature*, not a limitation.

### Modes & scales
- **Natural Forest:** Dorian (warm but not saccharine — the minor 6th withheld).
  Root **D**. Open fifths and add9 voicings; no leading tone, so it never
  "resolves" too cleanly. Tempo-free, rubato.
- **First Layer:** Lydian (the raised 4th = wonder + unease). Root **D** so the
  cross-fade is pivot-smooth. Add a recurring **tritone shimmer** (D–G#) on
  perception edges.
- **Corruption / combat:** Phrygian-dominant fragments over a held drone; chromatic
  cluster stabs for Wisp aggression.
- **"Sight" theme:** whole-tone — deliberately rootless and floating, no home key.

### Leitmotifs
1. **Seeker theme** (the player as truth-seeker): a rising 4-note cell,
   **D–E–A–B** (up a 4th, up a 4th, step). Hopeful, incomplete — it never lands
   on the tonic until the narrative does. Played on piano/flute. Used in menus,
   discovery beats, and quest progression.
2. **Auralis theme:** a slow descending answer to the Seeker cell,
   **B–A–F#–E**, harmonized in parallel fifths, on bowed cello + glass pad. Warm,
   maternal, slightly synthetic in the First Layer (granular tail). Triggered on
   `guide_appear`.
3. **Truth / Simulation motif:** two pure sine tones a beating major-2nd apart
   (**D + E**, detuned ~3 Hz), with a third sine fading in a tritone above on
   "reveal." This is the audible "render seam." Surfaces under Fragments of Truth,
   layer transitions, and the Sight moment. Built directly from `SfxSynth.tone()`.

### Tempo map
| Context | Feel | BPM |
|---|---|---|
| Main menu | suspended, rubato | ~50 (free) |
| Natural Forest explore | breathing | 60 |
| First Layer explore | pulsed, glassy | 72 |
| Deeper biomes (future) | colder, slower | 54–66 |
| Combat (Wisps active) | tense ostinato | 96 |
| Sight / transformation | time-dilated | half-time freeze |

---

## 2. Adaptive Music Plan

Music is **stem-based**. One synced multitrack bed per zone; layers fade in/out
(vertical re-orchestration) and whole beds cross-fade on hard state changes
(horizontal transition). Drive it from the existing `GameState.world_state_changed`
signal and combat/proximity state.

### Stem set per bed
- `bed_pad` — sustained harmonic floor (always on, the anchor)
- `bed_melody` — Seeker/Auralis motif voice (fades with discovery & calm)
- `bed_pulse` — rhythmic ostinato (First Layer + combat only)
- `bed_tension` — clusters/drone detune (combat, danger proximity)
- `bed_shimmer` — Truth-motif sines (Fragments near, Sight, reveals)

### State → stem mapping (programmer contract)
| Game state | pad | melody | pulse | tension | shimmer |
|---|---|---|---|---|---|
| Menu | on -6dB | on -10dB | off | off | off |
| Natural explore | on 0dB | on -8dB | off | off | off |
| Natural, Fragment nearby | on | on | off | off | fade -14dB |
| First Layer explore | on 0dB | on -10dB | on -12dB | off | breath -18dB |
| First Layer, Wisp alerted | on | duck -6dB | on -4dB | fade in -8dB | off |
| Combat active | on | off | on 0dB | on -3dB | off |
| Wisp death / calm restored | on | return | duck | fade out (2s) | off |
| Sight active | low-pass on | freeze | off | off | swell 0dB |

**Transition rules**
- *Vertical:* stem volume crossfades over **1.5–2.0 s** (`create_tween` on
  per-stem `AudioStreamPlayer.volume_db`). Keep all stems playing & sample-synced;
  only volume changes, so re-orchestration is seamless.
- *Horizontal (Natural ↔ First Layer):* both beds share BPM (60↔72 via a
  one-bar accelerando stinger) and tonic D, so cross-fade over **3 s** while a
  one-shot `layer_shift_swell` rises. Pivot on the held D pad — never silence.
- *Biome travel (future deeper layers):* hard scene cut allowed; cover with a
  `descend_whoosh` and re-instantiate the new bed at the same harmonic root.

Implementation note: add a small `MusicDirector` node holding 5 looping
`AudioStreamPlayer`s (one per stem), all `.play()`-ed at load and held in sync;
expose `set_state(name)` that tweens the table above. Until real stems exist,
point each player at a distinct `SfxSynth` pad variant (different detune/partials)
so the system is testable today.

---

## 3. "Sight" / Transformation Audio Language

The Sight (the fictional/mystical perception shift — the only place the
"psychedelic" register lives) is a **discrete sonic event**, not a texture. When
perception flips, the world should sound like it is being *re-rendered*:

1. **Pre-shift (0.3 s):** everything ducks; a high-passed intake of air; the
   Truth-motif sines fade up beating faster (3 Hz → 7 Hz).
2. **The flip (impact):** a single reversed-reverb *bloom* + sub drop; all
   ambience momentarily replaced by a clean sine drone (the "render buffer").
3. **Resolve (1.5 s):** the new world bed swells in under a glassy whole-tone
   arpeggio; reverb tail blooms forward; beating settles. Apply a temporary
   master **low-pass sweep** opening from 400 Hz → 18 kHz to mimic vision
   clearing.

This is the existing `mushroom_transform` cue elevated. Extend its synth recipe
(chord + rising shimmer is already there) with a reversed tail and the beating
sine pair. Pair it with a global bus low-pass automation.

---

## 4. SFX Taxonomy & Cue List

Naming: lowercase `snake_case`, `category_action`, matching
`AudioManager.play("cue")`. Existing cues retained verbatim (do not rename).
Files drop into `res://audio/sfx/<cue>.ogg`.

**Player / movement**
- `footstep` — soft pad on soil/moss (pitch-randomized, exists)
- `footstep_layer` — same gait, glassier, First Layer surfaces
- `jump_soft` — light lift, breath of air
- `land_soft` — cushioned settle
- `dash_phase` — short whoosh, slight pitch bend (movement ability)

**Combat — player**
- `player_attack` — Rootblade swing, woody whoosh (exists)
- `player_attack_charged` — heavier, harmonic bloom on release
- `magic_cast` — Simulation Pulse, rising sine glide (exists)
- `magic_hum` — sustained channel/charge loop (exists)
- `player_hurt` — dull low impact + breath (exists)
- `player_heal` — warm ascending chord, Forest Essence restoring

**Combat — Corrupted Wisps**
- `wisp_alert` — detection, falling alarmed tone (exists)
- `wisp_aggro_loop` — low chittering drone while hunting
- `wisp_attack` — sharp dissonant lunge
- `wisp_damage` — bit-crushed hit (exists)
- `wisp_death` — descending dissolve into static (exists)
- `wisp_spawn` — corrupt materialization, reversed swell

**Collectibles / progression**
- `fragment_pickup` — bright rising 5th triad, "truth click" (exists)
- `fragment_nearby_ping` — faint shimmer pulse when close
- `essence_absorb` — warm gulp + glow tail (Forest Essence)
- `upgrade_select` — resolving major chord (exists)
- `quest_update` — two-note notification (exists)
- `quest_complete` — fuller Seeker-motif flourish

**World / narrative**
- `guide_appear` — Auralis theme chord bloom (exists)
- `guide_speak_blip` — soft text-scroll voice tick (pitched per glyph)
- `mushroom_transform` — the Sight flip (exists; see §3)
- `layer_shift_swell` — Natural↔First Layer reveal riser
- `layer_shift_collapse` — reverse, returning to Natural
- `seam_glitch` — brief reality-tear stutter (rare, ambient unease)
- `descend_whoosh` — travel to a deeper biome (future)

**Interactable / object**
- `object_examine` — gentle inspect tick
- `barrier_dissolve` — magical gate opening
- `root_grow` — organic creak + rustle (puzzle/path)

**UI**
- `ui_click` — square blip (exists)
- `ui_hover` — quieter, higher click
- `ui_back` — descending pair
- `ui_open` / `ui_close` — pad swell up / down
- `error_soft` — muted denial tone

*(40 cues; the 14 existing synth cues remain the live fallback.)*

---

## 5. Ambience Beds (per biome)

`AudioManager.play_ambience("<name>")` — loop in `res://audio/ambience/`.

| Bed | World/biome | Character |
|---|---|---|
| `forest_day` | Natural Forest (exists) | birds, breeze, distant water, leaf rustle — warm, real |
| `forest_dusk` | Natural Forest, low-light | crickets, owl, cooler air, sparser birds |
| `first_layer_glade` | First Layer surface | the same forest, but *too clean* — birdsong slightly quantized, a sub hum, faint beating sine under everything |
| `first_layer_deep` | First Layer dense | thicker glass pad, drips reversed, low choir-like whisper |
| `corruption_zone` | Wisp-heavy areas | detuned drone, sparse metallic ticks, unsettled air |
| `cavern_layer` | deeper biome (future) | dripping stone, hollow sub, distant resonant tones |
| `void_seam` | layer-boundary (future) | near-silence + lone beating sine + occasional `seam_glitch` |

Each First Layer bed should carry the Truth-motif beating sine at low level
(-24 dB) — a continuous reminder the world is rendered. Extend
`SfxSynth.ambience()` to accept a `variant` (detune amount, brightness, sub
level) so each bed has a distinct procedural placeholder today.

---

## 6. Sourcing Plan

**Licensing rule:** CC0 / public-domain / royalty-free only. No third-party IP,
no copyrighted music. Log every asset's source + license in
`audio/CREDITS.md` even when not legally required.

**Recommended CC0 / free libraries**
- **Freesound.org** (filter to CC0) — field recordings: forest, birds, wind,
  footsteps, water, foley.
- **OpenGameArt.org** (CC0) — game-ready SFX/loops.
- **Sonniss GDC "Game Audio Bundle"** (royalty-free, free annually) — pro foley.
- **Pixabay Audio** — royalty-free SFX & beds.
- **Composition tools:** LMMS, VCV Rack (free), or any DAW with CC0/own-content
  instruments for the original score stems. All music is **original** — compose
  to the motifs in §1; do not adapt existing tracks.

**Procedural placeholders (today, no files):**
`SfxSynth` already produces every live cue. Extend it by:
1. Adding `match` arms for the new cue names in `sfx()` (reuse `tone`, `_seq`,
   `_chord`, `_mix` — e.g. `wisp_attack` = fast falling square + noise burst).
2. Generalizing `ambience()` to `ambience(variant)` for the beds in §5.
3. Adding a `truth_motif(beat_hz)` helper (two `tone()` sines summed) reused by
   the Sight event and First Layer beds.
Placeholders stay as the fallback — dropping a real OGG of the same name silently
overrides them.

**File placement (no code changes needed)**
- SFX → `res://audio/sfx/<cue>.ogg`
- Ambience → `res://audio/ambience/<bed>.ogg`
- Music stems → `res://audio/music/<bed>_<stem>.ogg` (add `music/` to the
  `MusicDirector` load paths).

**Format:** OGG Vorbis, 44.1 kHz. SFX mono; ambience/music stereo and
loop-trimmed at zero-crossings for seamless looping.
