# The First Layer — Design Bible

A cohesive AAA-scope design for *The First Layer — A Magical Forest Simulation
Mystery*. All documents share one canon, written so they reinforce rather than
contradict each other. Graphics/art direction is owned separately; everything
here is the surrounding design ("the heavy lifting").

## The premise in one breath
A lost explorer touches a glowing mushroom on an ancient shrine and learns the
forest is the **first layer** of a constructed reality — **The Verdancy**, a
*grief-engine* that metabolises painful memory into landscape. Descending
through its **Strata** toward **the Seed**, the Seeker uses fictional, mystical
perception-reagents (the **Sight**) to see past the world's beautiful lies,
while **The Forgetting** — compassion weaponised into censorship — tries to
smooth them away.

> Content note: the mushroom and all "Sight" reagents are **mystical, symbolic,
> fictional** gateways (a fantasy detective-vision), never a depiction of
> real-world drug use. See `03_ITEMS_AND_SIGHT.md`.

## Documents
| # | File | Owner discipline |
|---|------|------------------|
| 01 | `01_STORY_BIBLE.md` | Narrative: world truth, the Strata, antagonist, factions, endings |
| 02 | `02_CHARACTERS.md` | Cast, Auralis, bestiary, dialogue voice guide |
| 03 | `03_ITEMS_AND_SIGHT.md` | The Sight system, reagents, weapons, relics, crafting |
| 04 | `04_QUESTS.md` | Main spine + side quests + set-pieces + quest-state model |
| 05 | `05_WORLD_MAP_AND_BIOMES.md` | Biomes-as-layers, first-region layout, gating, M5 perf |
| 06 | `06_AUDIO_DIRECTION.md` | Leitmotifs, adaptive stems, SFX taxonomy, sourcing |
| 07 | `07_UX_AND_SCREENS.md` | Splash, loading, menus, settings, HUD, codex |
| 08 | `08_PROGRESSION_AND_SYSTEMS.md` | Seeker Paths, combat depth, economy, GameState model |

## Canon quick-reference (do not contradict)
- **The Verdancy** — the simulated world / grief-engine. The forest is its
  gentlest-edited stratum (the "first layer").
- **Strata** — descending layers: Quietwood → Loomstrata → Hollow Census →
  Anhedron → Unrendered → **the Seed**.
- **Seeker** — the player; a "Residual" who arrived already grieving and so
  resists editing. The **Ancient Rootblade** is their grief, crystallised.
- **Auralis** — guide spirit; the world's apology made tender (with a hidden
  wish for you to *stop*).
- **The Forgetting** — antagonist force; **Corrupted Wisps** are its
  memory-stripped antibodies.
- **Fragments of Truth** — recovered memories the world hid. **Forest Essence** —
  primary currency. **Sight** — fictional perception mechanic (Lucidity/Desync).

## Implementation status (already in the prototype)
Splash + loading screens, lore-tip pool, the first-layer transformation, Auralis
dialogue, fragments, wisps, the Rootblade + Simulation Pulse, the Essence
Sanctum, Journal, and photoscanned forest are built. The docs above define the
road from this vertical slice toward the full game; see each doc's notes for
programmer-ready state models.
