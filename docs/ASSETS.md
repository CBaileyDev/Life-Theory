# Third-party assets & licenses

All bundled assets are **CC0 (public domain)** — free for any use, no attribution
required. Credit is given here as good practice.

## HDRI (image-based lighting + sky)
- `assets/hdri/forest_sky.hdr` — "Mossy Forest" 1K HDRI.
  Source: **Poly Haven** (https://polyhaven.com) — CC0.

## PBR textures (scanned materials, 1K JPG: albedo / normal / roughness)
- `assets/textures/ground_*` — "Ground037". Source: **ambientCG** (https://ambientcg.com) — CC0.
- `assets/textures/bark_*` — "Bark012". Source: **ambientCG** — CC0.
- `assets/textures/rock_*` — "Rock023". Source: **ambientCG** — CC0.

## 3D models (photoscanned, CC0) — `assets/models/*.glb`
Source: **Poly Haven** (https://polyhaven.com) — CC0. From the `pine_forest`
and `verdant_trail` collections.
- Trees: `pine_tree_01`, `fir_tree_01`, `tree_small_02`, `fir_sapling_medium`
- Rocks: `rock_moss_set_01`, `rock_07`
- Ground cover: `fern_02`, `grass_medium_01`, `shrub_01`, `tree_stump_01`

The raw scans are film-resolution (the pine tree alone is ~950 MB / millions of
triangles) — far too heavy for the repo or a real-time M5. They were **decimated
to game-resolution** with `@gltf-transform/cli optimize --simplify-error` +
`dequantize` (meshoptimizer), bringing all ten models to **~10 MB total** while
preserving silhouette. Re-run that pipeline if you re-download higher-res sources.

## AI-generated models (Meshy AI) — `assets/models/*.glb`
North Cascades / Mt Baker–Snoqualmie themed set, generated via the
**Nanobanana Pro → Meshy image-to-3D** pipeline (`tools/meshy_gen.sh`,
`tools/meshy_batch.sh`). Each carries full PBR (base_color / metallic /
roughness / normal) and was optimized with `@gltf-transform/cli optimize
--texture-compress webp` (raw ~10–12 MB → ~1–2 MB, geometry preserved).
Built in two world-states for the natural-forest → mushroom → mystical
"First Layer" transition: `_natural` (photoreal daylight) and `_glow`
(bioluminescent violet-blue emissive).

- Ferns: `fern_sword_{natural,glow}` (Polystichum munitum), `fern_deer_{natural,glow}` (Blechnum spicant)
- Small trees: `tree_hemlock_sapling_{natural,glow}` (Tsuga heterophylla), `tree_cedar_sapling_{natural,glow}` (Thuja plicata)
- Pinecones: `pinecone_douglasfir_{natural,glow}` (Pseudotsuga menziesii)
- Moss: `moss_clump_{natural,glow}`
- Ivy: `ivy_vine_{natural,glow}`
- Creature: `stag_spirit_glow` — the mystical Luminous Stag (First-Layer only)

**License:** generated on a paid Meshy plan; per Meshy's Terms the account
owner holds the rights to these outputs (commercial use permitted). Pine-needle
floor and moss-ground are intentionally **not** modelled here — they belong as
tiling PBR ground textures (source CC0 from ambientCG/Poly Haven; drive the glow
via a shader emissive mask).

## Audio
- None bundled. All sound is synthesized procedurally at runtime (`SfxSynth`).

## Everything else
- Meshes, particles, UI, shaders are generated procedurally in-engine
  (`MeshFactory`, `SfxSynth`, custom `.gdshader` files) — no third-party content.

## Notes on adding more
Drop additional CC0/owned assets here and wire them via `MeshFactory.mat_pbr()`
(textures) or by instancing imported `.glb`/`.gltf` models. Keep this file
updated with sources and licenses.
