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

## Audio
- None bundled. All sound is synthesized procedurally at runtime (`SfxSynth`).

## Everything else
- Meshes, particles, UI, shaders are generated procedurally in-engine
  (`MeshFactory`, `SfxSynth`, custom `.gdshader` files) — no third-party content.

## Notes on adding more
Drop additional CC0/owned assets here and wire them via `MeshFactory.mat_pbr()`
(textures) or by instancing imported `.glb`/`.gltf` models. Keep this file
updated with sources and licenses.
