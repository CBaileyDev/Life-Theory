# Audio

The prototype ships with **no copyrighted audio**. Every sound is wired through
`AudioManager` (autoload) and will play automatically the moment a matching file
is dropped here — no code changes needed. Missing files are a silent no-op, so
the game runs fine with zero audio installed.

## How it resolves files

`AudioManager.play("<cue>")` searches, in order:

- `res://audio/sfx/<cue>.ogg` → `.wav` → `.mp3`
- `res://audio/<cue>.ogg` → `.wav` → `.mp3`

`AudioManager.play_ambience("<name>")` searches `res://audio/ambience/` then
`res://audio/`, and loops the stream.

## Cues referenced by the game

| Cue file (drop in `audio/sfx/`) | Triggered by |
|---|---|
| `footstep` | player movement (hook available) |
| `mushroom_transform` | the transformation event |
| `magic_hum` | dialogue / magical ambience |
| `guide_appear` | Auralis fading into view |
| `fragment_pickup` | collecting a Fragment of Truth |
| `wisp_alert` | a Corrupted Wisp noticing the player |
| `wisp_damage` | hitting a wisp |
| `wisp_death` | a wisp dying |
| `player_attack` | swinging the Rootblade |
| `magic_cast` | casting the Simulation Pulse |
| `upgrade_select` | choosing an upgrade |
| `ui_click` | menu interactions |
| `player_hurt` | taking damage |
| `quest_update` | quest step changes |

## Ambience (drop in `audio/ambience/`)

| File | Used by |
|---|---|
| `forest_day` | looping forest ambience (main menu + level) |

Recommended format: **OGG Vorbis** (small, cross-platform, loops cleanly).
Keep everything royalty-free / CC0 to preserve the no-protected-IP rule.
