# 03 — Items & the "Sight" System

*The First Layer* — Systems/Item Design
Protagonist: **Auralis**, the Seeker. Setting: a forest that is the first layer of a simulated reality.

---

## 1. The "Sight" System

**Sight** is the game's core perception mechanic — a fantasy "true-vision" lens, kin to detective-vision in other titles, reframed through the fiction of a simulated world. When Auralis attunes a **perception-reagent** (a mystical mushroom or bloom harvested from the forest), her eyes briefly resolve the world's underlying *render*: the seams where the simulation lies to her.

These reagents are **invented, symbolic, magical objects** — enchanted fungi and motes of light. They are reagents in the same sense a healing potion or a mana crystal is a reagent. There is no real-world substance, dosing, sourcing, or chemistry anywhere in this design. The "trip" is a fantasy of *seeing code*, not of altered chemistry.

### 1.1 What Sight Reveals
Activating Sight overlays a translucent **Seam Layer** on the world for a duration. Depending on tier it reveals:

- **Hidden paths** — bridges, ledges, and doors that render as empty air to ordinary sight.
- **Entity true-forms** — Corrupted Wisps drop their "friendly" disguise and show their wireframe husks; benign-seeming NPCs flicker, revealing which are scripted echoes and which are "real."
- **Glyph-code** — floating runic strings (the simulation's source) cling to objects, spelling puzzle solutions, lock conditions, and lore.
- **Lies in the world** — surfaces tagged `FALSE` shimmer: illusory walls, painted-on chasms, looping skyboxes, mirrored dead-ends.

### 1.2 Activation, Duration, Cost
- **Activation:** Auralis consumes one reagent from a quick-slot (the **Attunement Wheel**). A bloom of light, a held breath, then the Seam Layer fades in over ~1.5s.
- **Duration:** 20–90s depending on reagent tier; a HUD ring (the **Lucidity Meter**) drains as it elapses.
- **Cost:** Reagents are finite and tiered. Higher Sight costs rarer reagents and **Forest Essence** to attune. Combat is harder under Sight (see Desync).

### 1.3 Tiers of Sight
| Tier | Name | Reveals | Gate Role |
|------|------|---------|-----------|
| I | **Glimmer** | Hidden paths, basic glyphs | Early traversal |
| II | **Resolve** | Entity true-forms, `FALSE` surfaces | Combat reads, illusion puzzles |
| III | **Lucid Seam** | Deep glyph-code, layer-edges, scripted-echo flags | Mid-game logic puzzles |
| IV | **Deep Render** | The First Layer's "boundary," seams into the layer below | Story gates, finale |

### 1.4 Desync & Fraying — the *fictional* overuse risk
Overusing Sight is dangerous **only within the fiction**. Each activation raises a hidden **Desync** value:

- **Fraying:** at high Desync the world visibly tears — geometry stutters, textures peel, false sounds bleed in. Auralis can no longer trust which layer she sees; safe ground may render as a pit.
- **Echo-bleed:** Corrupted Wisps gain a chance to ambush from "off-render" while Desynced.
- **Recovery:** Desync decays by resting at a **Rootshrine**, drinking **Stillwater** (a calming reagent), or simply not using Sight. There is no medical framing — Desync is a *simulation-stability* meter, like an overheating engine. Pure mystery-tension, never substance harm.

Sight gates exploration (paths exist only under Glimmer), puzzles (glyph sequences must be read under Lucid Seam), and bosses (a Wisp's weak-seam is only strikeable while its true-form is visible).

---

## 2. Perception-Reagents (Mushrooms & Blooms)

All fictional, mystical flora. Rarity: Common / Uncommon / Rare / Mythic.

1. **Glimmercap** *(Common)* — A pale, vein-lit mushroom on rotting logs. Grants Tier-I Glimmer, ~25s. *Lore:* "The forest's first whisper that it is not solid."
2. **Hollowveil Bloom** *(Common)* — A grey flower that opens only in shadow. Reveals `FALSE` surfaces for 20s; low Desync cost. Found in cave mouths.
3. **Truthspore** *(Uncommon)* — Clustered orange spores on standing stones. Tier-II Resolve, exposes entity true-forms. *Lore:* "What it shows cannot be unseen."
4. **Seamwort** *(Uncommon)* — A thread-like vine glowing at the joints of the world. Extends any active Sight duration by 40%. Grows along map-edge cliffs.
5. **Lucid Morel** *(Rare)* — A crystalline morel found behind illusory walls (catch-22: needs Sight to find). Grants Tier-III Lucid Seam, 60s. High Desync.
6. **Stillwater Lily** *(Uncommon)* — A floating white lily on quiet pools. *Not* a Sight reagent — it **purges Desync** and calms Fraying. The "antidote" item.
7. **Mirrorshade Fungus** *(Rare)* — Grows on mirrored dead-ends. Briefly lets Auralis see the layer *behind* a reflection, revealing hidden rooms. 15s, very high Desync.
8. **Deeproot Truffle** *(Mythic)* — Unearthed at the forest's heart. Grants Tier-IV Deep Render — the only reagent that shows the boundary of the First Layer. Story-locked; one or two exist in the game.
9. **Ashen Puffball** *(Common)* — A throwable utility fungus; bursts into a glyph-revealing cloud, exposing nearby code to *allies/companions* without self-Desync.

---

## 3. Weapons & Tools

Built around the **Ancient Rootblade** — a living-wood sword that "reads" the simulation through its grain.

1. **Ancient Rootblade** *(signature)* — Base melee. Under Sight, its edge glows along enemy weak-seams, dealing bonus damage to revealed true-forms.
2. **Rootblade: Severing Edge** *(upgrade)* — Adds a **Seam-Cut**: a charged strike that severs a Wisp's render-tether, briefly stunning it out of phase.
3. **Rootblade: Echo Form** *(upgrade)* — On parry, spawns a half-second "scripted echo" of Auralis that mirrors the next attack — turning the simulation's own duplication against enemies.
4. **Thornlash Whip** *(tool/weapon)* — A retractable root-vine for pulling distant glyph-anchors and yanking off-balance Wisps; doubles as a traversal grapple to Sight-revealed ledges.
5. **Glyph-Knife** *(tool)* — A short blade etched with editable runes; used to *rewrite* small glyph-code nodes (open a lock, flip a `FALSE` wall to `TRUE`). Limited charges per **Rootshrine** rest.
6. **Resonance Lantern** *(tool)* — Projects a steady cone of low-tier Sight without consuming a reagent, but drains slowly and cannot reveal Tier-III+. The reliable everyday lens.
7. **Pulsecaster Gauntlet** *(tool)* — Channels the **Simulation Pulse** ability: a radial shockwave that momentarily forces *all* nearby render into true-form and interrupts Wisp scripts. Cooldown-based, no reagent.

---

## 4. Gear & Relics

Simulation-themed artifacts (5–7), each a **Fragment-of-Truth–bound** relic.

1. **Wireframe Cloak** — While standing still, Auralis partly de-renders, lowering Wisp detection. The world "forgets" her.
2. **Lucidity Band** — Reduces Desync gain by 25%; turns Fraying's visual chaos into readable static.
3. **Seamwalker Boots** — Lets Auralis briefly stand on Sight-revealed (Glimmer) paths a half-second after Sight ends — buys traversal time.
4. **Echo Locket** — Stores one "snapshot" of a true-form reveal; replay it later to solve a puzzle without re-attuning Sight.
5. **Root-Heart Amulet** — Passive Forest Essence regen near living trees; the forest "funds" the Seeker.
6. **Glyphward Sigil** — Negates the first Echo-bleed ambush per encounter while Desynced.
7. **Fragment Prism** — Endgame relic: socket **Fragments of Truth** to permanently unlock partial passive Sight (always see `FALSE` surfaces, no reagent). The reward for completism.

---

## 5. Attunement, Crafting & Economy

### 5.1 The Attunement Loop
Reagents are rarely used raw at higher tiers. At a **Rootshrine**, Auralis performs **Attunement**:

```
Raw Reagent + Forest Essence (+ optional modifier reagent)  →  Attuned Reagent
```

- **Forest Essence** (currency) is the binding agent — every attunement and most upgrades cost it.
- **Modifier reagents** tune the result: add Seamwort for longer duration; add Stillwater Lily to lower Desync cost; combine two Sight reagents for hybrid reveals (e.g., Truthspore + Hollowveil = "see true-forms *and* lies" in one cast).
- Attuned reagents are slotted to the **Attunement Wheel** (4 quick-slots).

### 5.2 Inventory & Economy Structure
- **Satchel (consumables):** raw + attuned reagents, stack-limited to force resource decisions.
- **Relic Slots:** 3 active gear/relic slots; build identity (stealth, durability, lucidity).
- **Codex (key items):** Fragments of Truth, story keys — never sold.
- **Essence sinks:** attunement, Rootblade/tool upgrades, relic socketing, fast-travel between Rootshrines.
- **Essence sources:** defeated Wisps, harvested flora, dismantled duplicate relics, discovering hidden (Sight-gated) caches — rewarding the very mechanic the economy funds.

This creates a tight loop: **use Sight → discover Essence/reagents → attune deeper Sight → reach gated content** — while Desync keeps Sight from being spammed, forcing the player to spend it like a precious lens, not a flashlight.

---

## 6. Responsible Framing (explicit)

Every "perception-reagent," mushroom, bloom, and "Sight" effect in *The First Layer* is a **purely fictional, mystical game mechanic** — a fantasy true-vision power on par with magic potions or detective-vision in other games. They exist only to let the character perceive hidden layers of a *simulated reality* for the purposes of exploration, puzzles, and story.

Nothing here depicts, references, encourages, or instructs real-world substance use. There is no dosing, sourcing, chemistry, or physiological effect of any kind. "Desync," "Fraying," and "withdrawal-like" tension are **simulation-stability story devices** — the world glitches, not the body. The treatment is symbolic and narrative, consistent with the game's poetic, unsettling, layered-reality tone.
