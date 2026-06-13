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

## Audio
- None bundled. All sound is synthesized procedurally at runtime (`SfxSynth`).

## Everything else
- Meshes, particles, UI, shaders are generated procedurally in-engine
  (`MeshFactory`, `SfxSynth`, custom `.gdshader` files) — no third-party content.

## Notes on adding more
Drop additional CC0/owned assets here and wire them via `MeshFactory.mat_pbr()`
(textures) or by instancing imported `.glb`/`.gltf` models. Keep this file
updated with sources and licenses.
