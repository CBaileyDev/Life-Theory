# THE FIRST LAYER — Progression & Game Systems

> *"You do not level up. You become harder to forget."*

This document defines the progression, combat, economy, and state systems for *The First Layer*. It extends the existing prototype (`GameState`, melee + magic, sprint stamina, the Essence shrine) rather than replacing it. All numbers are first-pass and intended to be tuned in a `BalanceConfig` resource. Target hardware is a base MacBook Pro M5; every system below is encounter-budgeted (no global simulation, capped active actors).

---

## 1. Core Loops

**Moment loop (seconds):** *read the space → strike / dodge / pulse → manage stamina → recover.* Combat is deliberate, not frantic.

**Session loop (minutes):** **Explore → Uncover → Fight → Attune → Descend.**
- **Explore** a stratum's hand-built clearings, following luminous trails and listening for the world's "tells" (looping birdsong, tiling textures).
- **Uncover** by raising the **Sight** to reveal seams, hidden Fragments, rune-locks, and enemy weak points.
- **Fight** the Forgetting's antibodies (Corrupted Wisps and heavier constructs) over contested truth.
- **Attune** at a shrine: spend resources to unlock Seeker Path nodes and re-tune your build.
- **Descend** through a stratum gate once enough **Fragments of Truth** are recovered, carrying your build downward.

**Meta loop (a run / the campaign):** each stratum (Quietwood → Loomstrata → Hollow Census → Anhedron → Unrendered → the Seed) is a self-contained arc that deepens the central mystery, hands out a Revelation beat, and raises both threat and Sight cost. The meta-choice is **Continuation vs. Excavation vs. Dissolution** — the endings — which the player commits to only at the Seed. Builds persist across strata; the world's *believability* degrades as you go, which is the real "difficulty curve."

---

## 2. Seeker Paths (Skill Trees)

Progression is **node-based attunement**, not XP levels. Nodes are bought with **Forest Essence** (numeric) gated by **Fragments of Truth** (milestone). A node costs Essence; a *tier* unlock costs Fragments. There are four Paths; the four existing upgrades are each the **Tier-1 keystone** of their Path, so nothing in the prototype is orphaned. Players freely mix Paths but Essence scarcity forces specialization (~2 Paths deep by endgame).

### A. Warden (Rootblade / bruiser)
1. **Rootblade Strength** *(existing, +40 melee)* — keystone.
2. Barkskin — +12% damage reduction while stamina > 50%.
3. Cleaving Root — light attacks hit a wider cone.
4. Rooted Stance — heavy attack gains hyper-armor frames.
5. Sap-Drinker — melee kills restore 8 stamina.
6. Weight of Memory — heavies stagger and break enemy guard.
7. **Ultimate — Grief Made Edge:** a charged overhead that one-shots non-elite Wisps and reveals the killed enemy's buried memory (lore + bonus Essence).

### B. Hidden Path (mobility / stealth)
1. **Fleet of the Hidden Path** *(existing, 1.6× sprint)* — keystone.
2. Soft Tread — the Forgetting detects you at reduced range.
3. Phase-Dodge — i-frames extended; dodge through enemies.
4. Trailwalker — sprinting costs less stamina, regen starts sooner.
5. Unseen Strike — first hit from undetected deals 2.25×.
6. Slip the Census — brief invisibility after a perfect dodge.
7. **Ultimate — Between Frames:** short time-dilation; the world "stutters" and enemies freeze mid-render while you reposition or land free hits.

### C. Simulation (magic / control)
1. **Simulation Pulse** *(existing, 45-dmg projectile)* — keystone.
2. Forked Pulse — projectile splits on impact.
3. Overwrite — pulses apply *Dimming* (a DoT mirroring how Wisps "dim").
4. Resonant Cost — pulses cost stamina instead of a separate pool (keeps the prototype's two-meter model; see §4).
5. Lattice Snare — a thrown rune that roots enemies.
6. Decompile — bonus damage vs. revealed weak points.
7. **Ultimate — Null Render:** a zone that briefly un-renders enemy projectiles and slows constructs; the world flickers to wireframe.

### D. Seer (the Sight)
1. **Open the Sight** — keystone; turns Sight from a story toggle into a sustained, costed ability.
2. Long Sight — reveals seams, Fragments, and rune-locks at greater range.
3. Truesight — enemy weak points glow and stay tagged after Sight ends.
4. Steady Gaze — reduces the Sight's stamina/clarity drain.
5. Reader of Loops — highlights the "tell" of a looping construct, opening a punish window.
6. Bleed-Through — passively reveals nearby hidden Essence/Fragments without activating Sight.
7. **Ultimate — Seam Walk:** for a few seconds you perceive the layer's true geometry — walk through specific "rendered" walls and see every weak point at once.

> **Sight is fictional/mystical only** — a perception mechanic born from the shrine mushroom. No real-world substance simulation.

---

## 3. Combat Depth

**Inputs:** Light (LMB, ~0.45s cadence, existing), Heavy (hold LMB; slower, staggers), Parry (tap RMB-equivalent; tight window negates a hit and refunds stamina), Dodge (roll with i-frames), Pulse (magic; keystone-gated), Sight (hold, drains clarity).

**Stamina** is the spine. It gates sprint (existing), dodge, heavy, and parry-recovery. Light attacks cost little; heavies and dodges cost a lot. Empty stamina = no dodge/heavy = exposure. Regen pauses ~0.8s after any spend. This makes every fight a resource-rhythm puzzle rather than a button-mash.

**The Sight in combat:** activating Sight reveals enemy **weak points** (a glowing seam). Hitting a revealed weak point deals ~1.8× and builds *Stagger* faster. But Sight drains a **Clarity** meter and slightly desaturates/distorts the screen (tying mechanics to the "cost of attention" theme). High risk/high reward: you fight better seeing the truth, but seeing it wears you down.

**Enemy archetypes (Corrupted Wisps and kin):**
- **Mote** — basic Wisp (100 HP, telegraphed 12-dmg strike; existing). Fodder.
- **Dimmer** — applies a vision-fog debuff; priority target.
- **Census-Echo** — duplicates itself on a loop; the *real* one is only visible under Sight.
- **Bulwark Construct** — armored; must be staggered or weak-point-struck to damage.
- **Quorum Sentinel** (elite/mini-boss) — multi-phase, punishes greedy melee, rewards parry.

**Mini "Director":** a lightweight encounter manager keeps a *threat budget* per clearing (e.g., max 6 active actors on M5). It spawns from a weighted pool, escalates only when the player is winning comfortably (low recent damage taken + fast kills), and backs off after a death or low HP — giving a hand-tuned tension curve without a global AI sim. Director state is per-encounter and not saved.

---

## 4. Economy

**Forest Essence** (numeric, exists) — the spendable "perception sap."
- *Sources:* Wisp kills (+15, existing), Fragment pickup (+10, existing), Sight-revealed hidden caches, weak-point kills, exploration finds.
- *Sinks:* Seeker Path nodes (primary), shrine consumables, re-tuning (respec) fees.

**Fragments of Truth** (milestone, exists) — gate Path *tiers* and stratum descent. Not spent freely; they're progression keys. ~3 per clearing-cluster, ~8–12 per stratum.

**Two added resources:**
- **Clarity** — a regenerating in-fight meter consumed by the Sight; ties the Seer fantasy to a real cost. (Lives beside stamina; light survival flavor.)
- **Resonant Dust** — a *crafting* material from un-rendered objects and elite kills. Spent at shrines to **attune** (forge) node modifiers — e.g., Dust + Essence converts Cleaving Root into a piercing variant. Keeps Essence as the broad currency and Dust as the rarer specialization gate.

**Attunement / crafting cost example (tunable):**
| Action | Essence | Fragments | Dust |
|---|---|---|---|
| Tier-1 keystone | 60 *(existing)* | 1 | 0 |
| Tier-2 node | 90 | 0 | 0 |
| Tier-3 node | 140 | 1 | 1 |
| Ultimate | 300 | 3 | 4 |
| Respec (full) | 50% Essence refunded | 0 | 0 |

**Balance guidance:** target ~one keystone per ~1.5 clearings of normal play. A clearing yields ~75–120 Essence; a stratum yields ~600–900. That funds ~1 Path to mid-tier + dabbling, forcing the 2-Path specialization. Keep ultimates a once-per-stratum aspiration. Tune in `BalanceConfig`; never hardcode in gameplay scripts.

---

## 5. Survival-Lite Layer (kept light)

Per scope, survival is *atmospheric pressure*, not a chore. Three meters only:
- **Health** (exists) — heals at shrines / via consumables; no regen in the open keeps exploration tense.
- **Stamina** (exists) — moment-to-moment combat economy.
- **Clarity** — drains while using the Sight; regenerates in safe light. Low Clarity distorts the screen and hides Fragments — narratively, the world is "smoothing" you. No hunger/thirst/temperature systems; they'd dilute the poetic tone and burn M5 budget.

---

## 6. Difficulty & Accessibility

**Difficulty bands** (single multiplier set, no separate balance tables): *Wanderer / Seeker / Residual.* They scale enemy damage (×0.7 / ×1.0 / ×1.4), parry window width, Director threat budget, and Sight Clarity drain. Story beats and economy ratios stay constant.

**Accessibility (decoupled from difficulty):** parry-window assist slider, dodge i-frame extension, auto-Sight-tag weak points, reduced screen distortion / desaturation intensity (motion-sensitivity), hold-vs-toggle for sprint/Sight/heavy, damage-number and subtitle scaling, "guided trail" brightness. All are independent toggles so players tune challenge without changing the story or shutting off systems.

**Performance scaling (M5):** Director actor cap, particle density tiers, and Sight post-process quality all read from settings so the target stays a smooth 60fps on integrated GPU.

---

## 7. Data / State Model

Extending the existing `GameState` autoload (current fields kept verbatim). New fields are additive and save/load-bridged in `to_dict`/`from_dict`.

**Existing (keep):** `world`, `quest_step`, `fragments`, `mushroom_activated`, `guide_met`, `quest_complete`, `selected_upgrade`, `acquired_upgrades`, `max_health`, `health`, `sprint_multiplier`, `melee_damage`, `magic_unlocked`, `forest_essence`, `collected_ids`.

**Add — resources & meters:**
- `max_stamina: float`, `stamina: float`
- `max_clarity: float`, `clarity: float`
- `resonant_dust: int`

**Add — progression:**
- `current_stratum: int` (enum: QUIETWOOD … THE_SEED)
- `path_nodes: Dictionary` — `{ node_id: bool }` (supersedes the flat `acquired_upgrades`; the four keystones map onto it for back-compat)
- `path_tiers: Dictionary` — `{ "warden": int, "hidden_path": int, "simulation": int, "seer": int }`
- `sight_unlocked: bool`
- `ending_committed: String` ("" until the Seed)

**Add — node-driven stats** (derived, recomputed from `path_nodes` so saves stay declarative):
- `damage_reduction: float`, `dodge_iframes: float`, `weakpoint_mult: float`, `stamina_costs: Dictionary`.

**Signals to add:** `stamina_changed`, `clarity_changed`, `resonant_dust_changed`, `node_unlocked(id)`, `stratum_changed(index)`, `sight_toggled(active: bool)`, `ending_committed(kind)`.

**Methods to add:** `buy_node(id) -> bool`, `respec() -> void`, `recompute_stats() -> void`, `descend() -> bool`, `set_sight(active: bool)`, `spend_dust(n) -> bool`. Keep `buy_upgrade`/`choose_upgrade` as thin wrappers over `buy_node` so the prototype's shrine flow and saves keep working.

**Not persisted (runtime only):** Director threat budget, active enemy roster, current Sight-tagged weak points — these live on the encounter manager, never in `GameState`.
