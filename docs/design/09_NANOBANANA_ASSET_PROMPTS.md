# 09 — Nanobanana Pro Asset Prompts (→ Meshy AI image-to-3D)

*The First Layer — production prompt pack for generating reference images that get
converted to 3D game assets.*

**Pipeline:** write prompt → **Nanobanana Pro** (Gemini-3 Pro Image) → pick best
render → **Meshy AI** (Image-to-3D) → game-res `.glb` → drop into `assets/models/`.

---

## Locked art direction (answers to the design questions)

| Decision | Choice |
|---|---|
| **Framing / background** | Clean **neutral studio backdrop** — single object, soft even lighting, no fog. Best for accurate Meshy reconstruction. |
| **Realism target** | **Full photorealism** — Unreal Engine 5 / Nanite-grade, scanned-PBR detail. |
| **"Antler beast"** | **Mystical glowing stag** — the canon **Luminous / Lantern Stag** (light carried in the ribcage). |
| **3D-ready specs** | **Yes** — characters get a T-pose orthographic turnaround; props get a consistent 3/4 hero + side. |

### The shared palette & theme (keep every asset on-model)
- **Two world states** from `DESIGN.md`: *Natural Forest* (warm neutral sun, thin
  grey-green fog) and *First Layer* (cool **violet/blue** glow, runes lit, stronger bloom).
  These assets target the **First Layer** look: realistic materials + heightened
  bioluminescent **violet-blue** magic.
- Recurring motifs: mossy stone, living rootwood, glowing carved **runes/glyphs**,
  bioluminescent veins, drifting motes/spores, a sense the surface is "rendered" over
  hidden machinery (subtle seams of light).

---

## ⚙️ Reusable technical footer (already appended to every prompt below)

> *Photorealistic 3D game asset, Unreal Engine 5 / Nanite quality, physically based
> rendering, scanned-realism micro-detail. Single object centered with even margins,
> fully in frame, nothing cropped. Isolated on a seamless neutral mid-grey studio
> backdrop. Soft, even three-point studio lighting; balanced diffuse exposure that
> preserves true albedo for image-to-3D reconstruction; no blown-out specular
> highlights, no cast shadows on the backdrop, no atmospheric fog, no depth-of-field —
> everything in sharp focus across the whole object. Magical glow rendered as modest
> self-illuminated emissive (runes, veins, crystal cores) without heavy bloom.
> 3/4 front hero angle, slight high camera. Ultra-detailed, 8k, sharp.*

**Meshy tips when you run these images:**
- Keep emissive **modest** — Meshy bakes glow into the texture; heavy bloom washes out geometry.
- A clean neutral background = a cleaner auto-segmented mesh. Avoid busy ground.
- For characters, feed the **front T-pose** as the primary image; use the side/back as
  multi-view references if your Meshy plan supports them.
- Generate at **1:1** for props, **16:9** for the character turnaround sheet.

---

# PROPS & ENVIRONMENT

## 1. Tree — *Rune-Bark Ancient*
```
A single ancient forest tree as a hero game asset — a gnarled, towering fir/oak hybrid
with thick fibrous bark, deep furrowed grooves, and exposed mossy roots gripping a small
mound of soil. Faintly glowing violet-blue runic glyphs are carved naturally into the
bark, following the grain like veins of light, brightest in the deeper grooves. Patches
of luminous lichen and damp emerald moss cling to the north side. A few drifting spore
motes hover near the canopy. Weathered, realistic, alive — a tree that remembers being
watched. The whole tree from root mound to upper canopy is visible.
[+ reusable technical footer]
```

## 2. Rock — *Mossy Seam-Stone*
```
A single large mossy boulder as a game asset — granite-grey scanned stone with sharp
natural fracture planes, cracks, and weathered erosion. Thick cushions of wet emerald
moss and small ferns blanket the top and shaded crevices. A thin hairline seam of
glowing violet-blue light runs through one fracture, as if the rock is a surface
"rendered" over something luminous beneath. Damp, realistic, heavy. Resting on a small
patch of mossy earth.
[+ reusable technical footer]
```

## 3. Mushroom — *Glimmercap (perception-reagent)*
```
A single bioluminescent fantasy mushroom cluster as a game asset — three pale,
translucent caps of varying height growing from a mossy rotting log fragment. The caps
are smooth and waxy with delicate gills underneath; glowing violet-blue veins of light
branch through the translucent flesh and pulse brightest along the cap rims. Faint spore
motes drift upward. A few tiny secondary sprouts and lichen at the base. Realistic
mycology proportions, ethereal magical glow, wet forest-floor detail.
[+ reusable technical footer]
```

## 4. Sword — *Ancient Rootblade (signature weapon)*
```
A single fantasy melee sword as a hero game asset — the "Ancient Rootblade", a
living-wood longsword. The blade is grown rather than forged: dense polished heartwood
with a faint translucent grain, edges hardened into a sharp amber-resin cutting line.
Glowing violet-blue runic light runs up the central grain of the blade like sap. The
hilt and crossguard are woven living roots wrapped in soft moss and thin gold-bronze
binding; a small luminous amber seedpod sits in the pommel as a core. Weathered,
elegant, organic and magical. Presented blade-up, full length visible, slight 3/4 turn.
[+ reusable technical footer]
```

## 5. Portal — *Layer-Seam Gate*
```
A single ancient stone archway portal as a game asset — a freestanding ring of weathered
carved megalithic stones, mossy and root-wrapped, forming a doorway. Spiraling runic
glyphs glow violet-blue along the inner edge of the arch. Within the opening, a vertical
shimmering "seam" of magical energy — a rippling membrane of violet-blue light and faint
geometric lattice patterns, like reality folded open to reveal the layer beneath. Drifting
motes and a soft ground-glow at the base. Mysterious, sacred, photoreal stone with
ethereal portal energy. The entire arch and its stone base are fully in frame.
[+ reusable technical footer]
```

## 6. Fragment of Truth — *collectible* (bonus, fits the set)
```
A single floating crystalline shard as a small game asset — a "Fragment of Truth", a
palm-sized angular gem of semi-translucent violet-blue crystal with internal geometric
lattice and faint scrolling glyph-light suspended inside. Fractured, asymmetric, glowing
softly from its core with thin caustic light. A few tiny orbiting motes. Clean, jewel-like,
high-detail subsurface scattering. Centered, hovering, full object visible.
[+ reusable technical footer]
```

---

# CREATURES

## 7. Mystical Stag — *Luminous / Lantern Stag*
```
A single majestic mystical stag as a hero creature asset — an elk-sized deer with a
realistic muscular anatomy and a deep slate-and-charcoal coat dusted with faint
constellation-like glowing spots. Enormous branching antlers grown like pale living
wood, tipped with soft violet-blue luminescence. Within its ribcage glows a warm
lantern-like core of contained light, visible faintly through the chest as if the
skeleton frames a held flame. Bioluminescent markings trace the legs and spine. Calm,
noble, slightly ethereal — a gentle forest spirit. Standing in a natural neutral pose,
full body and full antlers in frame, side-3/4 angle so the antler silhouette reads clearly.
[+ reusable technical footer]
```

## 8. Golem — *Rootbound Guardian / Render-Golem* (designed to fit canon)
```
A single towering forest golem as a hero creature asset — a heavy humanoid guardian built
from mossy fractured boulders bound together by thick living roots and rootwood limbs.
Plates of grey scanned stone form its shoulders, chest and fists; emerald moss and small
ferns grow in its joints. Between the stone plates, glowing violet-blue "render-seams" of
light leak out, revealing it is a construct of the simulation — geometric lattice faintly
visible in the gaps. Glowing runic glyphs are carved across its chest plate; its eyes are
two calm points of violet light. Ancient, mossy, immense, photoreal. Standing in a stable
neutral A-pose, full body visible head to feet.
[+ reusable technical footer]
```

---

# CHARACTER (with 3D turnaround spec)

## 9. The Seeker — *player character*
```
Character turnaround model sheet of a single fantasy explorer — "The Seeker", a lithe,
weathered wanderer who woke in the forest with no memory. Practical layered traveler's
clothing: a hooded mossy-green cloak over worn leather armor, wrapped forearms, sturdy
boots, a satchel of harvested glowing mushrooms and a few violet-blue Fragment crystals
clipped to the belt. The living-wood Ancient Rootblade sheathed across the back, its runes
faintly glowing. Androgynous, hardy, realistic human proportions, quietly determined
expression. Photorealistic, Unreal Engine 5 / Nanite quality, PBR materials.

Present as a 3D-ready character reference: full body in a clean symmetric T-pose, neutral
expression, on a seamless neutral mid-grey studio backdrop with soft even studio lighting,
no fog, no cast shadows, everything in sharp focus, true albedo. Show three orthographic
views side by side — front, side, and back — at consistent scale and lighting for
image-to-3D and rigging. Modest emissive glow on runes and crystals only. Ultra-detailed,
8k. Aspect ratio 16:9.
```

> **Why T-pose + ortho views:** Meshy and any auto-rigger reconstruct cleaner topology
> and skeletons from a neutral symmetric pose. If you only need a single image, feed the
> **front T-pose**; use side/back as multi-view refs.

---

# OPTIONAL EXTRAS (round out the bottom-row set)

## 10. Corrupted Wisp — *enemy*
```
A single floating corrupted spirit as an enemy game asset — a roughly humanoid wisp of
condensed dark violet smoke and broken geometric lattice, no solid body, with a glowing
unstable core of magenta-violet light at its center and trailing tendrils of corrupted
"render-glitch" fragments. Flickering glyph-shards orbit it. Menacing, ethereal,
semi-transparent edges, sharp luminous core. Centered, full form in frame, hovering.
[+ reusable technical footer]
```

## 11. Mushroom Shrine — *landmark*
```
A single ancient stone shrine as an environment hero asset — a weathered carved
megalithic altar-stone, mossy and root-wrapped, ringed by a cluster of glowing
bioluminescent Glimmercap mushrooms. Spiraling runic glyphs glow violet-blue across the
stone's flat face; a shallow basin on top holds a pool of faintly luminous water (Sight
attunement). Drifting spore motes and a soft ground-glow. Sacred, quiet, photoreal stone
and moss with ethereal glow. Whole shrine and its mushroom ring in frame.
[+ reusable technical footer]
```

---

## Quick workflow checklist
1. Paste one block above (including the reusable footer) into Nanobanana Pro.
2. Generate 3–4 variations; pick the cleanest silhouette with the least bloom.
3. (Optional) ask Nanobanana to "remove background / pure backdrop" if any haze remains.
4. Run through Meshy AI → Image-to-3D → download `.glb`.
5. Decimate to game-res (see `docs/ASSETS.md` gltf-transform pipeline) and place in
   `assets/models/`. Update `docs/ASSETS.md` with the new source/license.
