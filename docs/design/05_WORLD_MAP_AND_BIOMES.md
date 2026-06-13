# 05 — World Map & Biomes

> *"A forest is only the surface tension of something deeper. Press on it long enough and your finger goes through."*

## 1. World Structure: Descending the Layers

**The First Layer** is a simulated reality rendered as a forest. The player, guiding **Auralis**, learns that the world has *strata* — layers of the simulation stacked beneath one another. Descending is not literal digging; it is **resolution loss**. The deeper you go, the more the simulation stops pretending to be nature and reveals the machinery underneath. **Sight** (granted by mystical reagents at the mushroom shrine — a fictional perceptual gateway, never a substance with real-world effect) lets Auralis perceive and pass through the seams between layers.

The game is **not** an open world. It is a chain of **streaming pockets** linked by chokepoints (root-tunnels, fog-walls, fault-seams) that double as load/occlusion boundaries. Each biome is a hand-authored zone sized for a base **MacBook Pro M5** — tight sightlines, deliberate fog lines, framed vistas instead of infinite draw distance.

### The Eight Biomes (Layers L0 → L7)

| # | Biome | Layer | One-line role |
|---|-------|-------|----------------|
| 0 | The Verdant Skin | L0 | Tutorial forest, the lie of "nature" |
| 1 | The Glitched Understory | L1 | Where the seams first show |
| 2 | The Mourning Marsh | L2 | Memory leaks into water |
| 3 | The Hollow Library | L3 | Stored truths, decaying index |
| 4 | The Wireframe Stratum | L4 | The simulation drops its textures |
| 5 | The Drowned Data-Grotto | L5 | Flooded servers, bioluminescent rot |
| 6 | The Cathedral of Loops | L6 | Recursive geometry, broken causality |
| 7 | The Architect's Core | L7 | The thing that dreams the forest |

---

### 0 — The Verdant Skin *(First Region — current slice lives here)*
- **Mood:** Warm, beautiful, *slightly too perfect*. Birdsong on a loop you eventually notice repeating.
- **Palette:** Sun-dappled emerald, amber moss, soft volumetric god-rays, warm bark browns.
- **Hazard:** Corrupted Wisps — drifting motes that drain Forest Essence on contact.
- **Creature:** The **Luminous Stag** (passive, herald; flees toward hidden seams).
- **Resource:** **Forest Essence** (baseline currency/health-light).
- **Landmark:** The **Mushroom Shrine** in the central clearing — a ring of bioluminescent caps around a stone where Sight is first attuned.

### 1 — The Glitched Understory
- **Mood:** Unsettling familiarity. The same forest, *wrong* — flickering foliage, popped-in trees, a smell of ozone.
- **Palette:** Desaturated greens shot through with magenta z-fighting flicker, chromatic-aberration edges.
- **Hazard:** **Stutter-fields** — zones where time micro-freezes, locking Auralis mid-step.
- **Creature:** **Clipped Deer** — Luminous Stags rendered with missing limbs that phase through trees.
- **Resource:** **Fragments of Truth** (story-bearing shards; the core collectible) begin appearing here.
- **Landmark:** **The Repeating Glade** — three identical clearings looped seamlessly; the exit is the one that *isn't* quite right.

### 2 — The Mourning Marsh
- **Mood:** Grief made geography. Slow, heavy, beautiful in a drowned way.
- **Palette:** Teal water, bone-grey reeds, low lilac fog, single warm lantern-points.
- **Hazard:** **Sinking memory-silt** — stand still and the simulation "forgets" the ground beneath you.
- **Creature:** **Echo-Wisps** — Corrupted Wisps wearing the shapes of people the simulation once held.
- **Resource:** **Tearwater** (refines Sight duration).
- **Landmark:** **The Half-Sunken Door** — a domestic doorway standing in open water, leading nowhere yet.

### 3 — The Hollow Library
- **Mood:** Reverent decay. A place that stored every true thing and is losing the file.
- **Palette:** Sepia, candle-gold, dust motes, deep shadowed stacks.
- **Hazard:** **Redaction fog** — black bands that erase what they pass over, including platforms.
- **Creature:** **Indexers** — wisp-clusters that "shelve" Auralis by teleporting her backward.
- **Resource:** **Bound Fragments** (clustered Fragments of Truth, lore-dense).
- **Landmark:** **The Endless Stair**, whose top floor is visibly the bottom floor.

### 4 — The Wireframe Stratum
- **Mood:** Awe and exposure. The art is *gone*; you see the bones of the world.
- **Palette:** Black void, cyan/white edge-lines, faint grid floor, occasional un-textured grey blockout.
- **Hazard:** **Untextured falls** — gaps you only see because the wireframe outlines them.
- **Creature:** **Naked Wisps** — Corrupted Wisps shown as raw particle emitters and debug spheres.
- **Resource:** **Vertex Dust** (sharpens the **Ancient Rootblade**).
- **Landmark:** **The Origin Cube** — a perfect untextured cube at world coordinate (0,0,0).

### 5 — The Drowned Data-Grotto
- **Mood:** Claustral, luminous, alive-but-not. A flooded server farm reclaimed by light.
- **Palette:** Inky blue-black water, electric cyan/violet bioluminescence, hot-white data-sparks.
- **Hazard:** **Current-surges** — periodic data-floods that sweep loose platforms (and Auralis).
- **Creature:** **Leviathan-Wisp** — a slow whale-scale corrupted mass; mini-boss presence.
- **Resource:** **Cold Light** (powers deep-layer Sight).
- **Landmark:** **The Sunken Server-Spires** — drowned monoliths blinking in lost languages.

### 6 — The Cathedral of Loops
- **Mood:** Sublime wrongness. Causality bends; the architecture is a thought repeating.
- **Palette:** Impossible whites and golds, Escher shadowing, prismatic seams.
- **Hazard:** **Recursion traps** — corridors that return you to their own entrance unless Sight reveals the true exit.
- **Creature:** **The Choir** — synchronized wisps that mirror Auralis's last action against her.
- **Resource:** **Loop-Thread** (final Rootblade upgrade material).
- **Landmark:** **The Nave That Eats Itself** — a vaulted hall folding endlessly inward.

### 7 — The Architect's Core
- **Mood:** Intimate dread. Quiet. The center of everything, and it knows your name.
- **Palette:** Near-monochrome white, single deep-red heartbeat-pulse, slow.
- **Hazard:** **Truth-pressure** — standing in raw truth costs Forest Essence each second.
- **Creature:** **The Architect** (the simulation's keeper / final encounter).
- **Resource:** **The Whole Truth** (assembled Fragments).
- **Landmark:** **The Dreaming Seed** — the kernel rendering the forest above.

---

## 2. First Region Layout — "The Verdant Skin"

Extends the current vertical slice (spawn → mossy path → clearing) outward into a hub region.

- **Z0 — Spawn Hollow:** Wake point. Soft tutorial, fenced by fallen logs and fog. Golden path leads east.
- **Z1 — The Mossy Path:** Linear traversal corridor. Teaches movement; first **Corrupted Wisp** sighting at a distance (caged behind a ravine).
- **Z2 — Central Clearing (HUB):** The mushroom shrine, **Auralis's** attunement, **3 Fragments of Truth**, the scripted **wisp encounter**, and the passive **Luminous Stag** grazing at the tree line. Four exits radiate out.
- **Z3 — Brookside Glen (optional):** North spur. Forest Essence farm, a hidden Fragment behind a waterfall (**Secret S1**).
- **Z4 — The Cairn Ridge (optional):** South spur, mild verticality. First **vista** over the canopy; the seam to L1 is visible but not yet reachable.
- **Z5 — The Old Trailhead (gated):** West. A fog-wall seam — the **first Sight gate** out of the region into the Glitched Understory.
- **POIs:** Shrine (Z2), Stag-meadow (Z2), Waterfall grotto (Z3), Overlook stone (Z4).
- **Secrets:** S1 waterfall Fragment; **S2** a "wrong" tree near Z4 that, when struck with the **Ancient Rootblade**, dissolves into a Fragment cache.

---

## 3. Traversal, Gating & Vistas

- **Sight is the master key.** Each tier of Sight (earned via shrine reagents + assembled Fragments) reveals and stabilizes the next layer's seam. L0→L1 needs **Sight I**; deeper layers escalate.
- **Ability gating:** The **Ancient Rootblade** cuts corrupted growth blocking paths; a later **Phase-step** (gained in L1) crosses Stutter-fields and Untextured falls.
- **Verticality:** Each region has one signature climb (Cairn Ridge here) ending in a framed vista that *previews the next biome* — a deliberate "wow" sell. The L4 Wireframe reveal and the L5 grotto descent are the showcase moments.
- **Wow vistas:** (1) First seam-glimpse from Cairn Ridge; (2) the canopy peeling into wireframe; (3) the Server-Spires lighting up across black water.

---

## 4. Performance Guidance (MacBook Pro M5)

- **Streaming pockets:** Every biome is a self-contained pocket. Chokepoints (root-tunnels, fog-walls, descent shafts) are **load curtains** — async-stream the next pocket while the player crosses, unload the previous.
- **Fog lines:** Each region uses volumetric fog tuned as a hard draw-distance budget. Fog is *diegetic* (the simulation's edge), so culling reads as intentional, not cheap.
- **Occlusion:** Author dense foliage and ridgelines as natural occluders; never allow a sightline across more than one pocket. Vistas use **skyboxes / impostor cards** for distant biomes — no live geometry.
- **Budget tiers:** L0–L2 (foliage-heavy) cap dynamic lights and use baked GI + cascaded shadows near-only. L4 Wireframe is deliberately cheap (line shader, no textures) — a built-in perf "exhale" after dense biomes. L5/L6 lean on bioluminescent emissive + limited reflections, not full screen-space reflection.
- **Instancing:** Trees, mushrooms, reeds, server-spires all GPU-instanced; wisps share a single particle system pool.

---

## 5. First Region — ASCII Map

```
                          N
                          ^
            ┌──────────────────────────┐
            │   Z3  BROOKSIDE GLEN      │
            │   ~waterfall~  [S1]       │
            │      (optional)           │
            └────────────┬──────────────┘
                         │ (creek crossing)
 ┌────────────┐   ┌──────┴───────┐   ┌─────────────────────┐
 │  Z5 OLD    │   │   Z2 CENTRAL  │   │   Z1  MOSSY PATH    │
 │ TRAILHEAD  │≈≈≈│   CLEARING    │───│  (linear corridor)  │
 │ [fog-wall] │SI │  HUB          │   │  · distant wisp     │
 │  → L1 gate │   │  ◉ Shrine     │   └──────────┬──────────┘
 └────────────┘   │  ✦✦✦ Fragments│              │
       W          │  ☼ Stag       │        ┌─────┴──────┐
                  │  ✺ Wisp fight │        │ Z0  SPAWN  │
                  └──────┬────────┘        │   HOLLOW   │
                         │                 └────────────┘
            ┌────────────┴──────────────┐
            │   Z4  CAIRN RIDGE          │
            │   ⛰ vista → (L1 seam)     │
            │   [S2 wrong-tree cache]    │
            │      (optional)            │
            └────────────────────────────┘

 LEGEND  ◉ shrine  ✦ Fragment  ☼ Luminous Stag  ✺ scripted wisp
         ≈ fog-wall seam  SI = Sight I gate  ⛰ vista  [S] secret
         ─── golden path   │ optional spur
```

*Golden path: Z0 → Z1 → Z2 → (collect 3 Fragments, attune Sight at shrine) → Z5 seam → descend to L1. Z3 and Z4 are optional, rewarding exploration with Fragments, Essence, and the first look down.*
