#!/usr/bin/env bash
# Batch-generate the North Cascades asset set (natural + glow variants).
# Runs MAXJOBS pipelines in parallel; writes per-asset + final status to batch.log.
set -uo pipefail
ROOT="/home/user/Life-Theory"; cd "$ROOT"
BLOG="$ROOT/tools/meshy/batch.log"; : > "$BLOG"
MAXJOBS=4

NSUF="Pacific Northwest North Cascades old-growth rainforest species, botanically accurate. Isolated on a seamless neutral mid-grey studio backdrop, soft even three-point studio lighting, balanced exposure preserving true albedo, no harsh cast shadows, no fog, full subject centered and entirely in frame, tack-sharp focus throughout, hyper-detailed realistic materials, 8k, photogrammetry-ready, AAA game asset quality."
GSUF="The mystical First Layer night state: photoreal materials but lit from within by bioluminescent violet-blue glow (veins, edges, undersides), faint drifting magical spores, soft self-illuminated emissive, dark moody cinematic. Isolated on a seamless neutral dark-grey studio backdrop, soft even lighting so the form reads clearly, full subject centered and entirely in frame, tack-sharp focus, hyper-detailed, 8k, photogrammetry-ready, AAA quality."

# slug|poly|prompt
ASSETS=(
"fern_sword_glow|24000|A single Western sword fern (Polystichum munitum), lush arching evergreen fronds radiating from a central crown, deep green pinnate leaflets glowing along the midribs and frond edges, growing from mossy soil. $GSUF"
"fern_deer_natural|24000|A single deer fern (Blechnum spicant), a rosette of slender finely-divided evergreen fronds arching outward with taller narrow upright fertile fronds at the center, growing from dark mossy forest soil. $NSUF"
"fern_deer_glow|24000|A single deer fern (Blechnum spicant), a rosette of slender finely-divided fronds with taller upright fertile fronds at the center, glowing softly along the leaflets, growing from mossy soil. $GSUF"
"tree_hemlock_sapling_natural|30000|A single young western hemlock sapling (Tsuga heterophylla), about waist-height, slender drooping leader tip, soft flat short needles on delicate branches, thin reddish-brown bark, small root base in mossy soil. $NSUF"
"tree_hemlock_sapling_glow|30000|A single young western hemlock sapling (Tsuga heterophylla), waist-height with a drooping leader tip and soft flat needles, the needle tips and branches glowing faintly, small mossy root base. $GSUF"
"tree_cedar_sapling_natural|30000|A single young western red cedar sapling (Thuja plicata), about waist-height, flat sprays of scale-like green foliage drooping gracefully, fibrous reddish bark on a slim trunk, small mossy root base. $NSUF"
"tree_cedar_sapling_glow|30000|A single young western red cedar sapling (Thuja plicata), waist-height with drooping flat sprays of scale-like foliage, glowing softly along the foliage edges, fibrous reddish bark, mossy root base. $GSUF"
"pinecone_douglasfir_natural|18000|A small cluster of three Douglas fir cones (Pseudotsuga menziesii) resting on a patch of pine needles and moss, brown woody overlapping scales with the distinctive three-pointed bracts protruding between the scales, realistic dry papery texture. $NSUF"
"pinecone_douglasfir_glow|18000|A small cluster of three Douglas fir cones (Pseudotsuga menziesii) on pine needles and moss, woody scales with three-pointed bracts, glowing violet-blue from between the scales. $GSUF"
"moss_clump_natural|20000|A lush clump of forest moss and small liverworts, a thick cushion of vivid green feather moss and sphagnum with fine detailed strands, a few tiny fern shoots, on a fragment of damp bark and soil. $NSUF"
"moss_clump_glow|20000|A lush clump of forest moss and liverworts, thick cushion of fine green strands with bioluminescent glowing tips, a few tiny shoots, on a fragment of damp bark. $GSUF"
"ivy_vine_natural|22000|A trailing forest vine, a long winding woody stem of climbing ivy and moss with overlapping green leaves and fine aerial rootlets, draped as if pulled from a tree trunk, damp realistic detail. $NSUF"
"ivy_vine_glow|22000|A trailing forest vine of climbing ivy and moss, winding woody stem with overlapping leaves and aerial rootlets, the leaf veins glowing violet-blue, draped naturally. $GSUF"
"stag_spirit_glow|60000|A single majestic mystical spirit stag, elk-sized deer with realistic muscular anatomy and a deep slate-charcoal coat dusted with faint glowing constellation spots, enormous branching antlers grown like pale living wood tipped with soft violet-blue luminescence, a warm lantern-like core of light glowing within its ribcage and visible through the chest, bioluminescent markings tracing the legs and spine, calm and noble, standing in a natural alert pose. The mystical First Layer forest spirit, photoreal fur and materials with magical emissive glow, dark moody cinematic. Isolated on a seamless neutral dark-grey studio backdrop, soft even studio lighting so the full body and complete antlers read clearly in a side three-quarter view, the entire animal and antlers centered and fully in frame, tack-sharp focus, hyper-detailed, 8k, AAA creature asset quality, photogrammetry-ready."
)

run_asset(){ # slug poly prompt
  local slug="$1" poly="$2" prompt="$3"
  echo "START $slug" >> "$BLOG"
  bash tools/meshy_gen.sh "$slug" "$poly" "$prompt" >/dev/null 2>&1
  if [ -s "assets/models/$slug.glb" ]; then echo "ASSET_DONE $slug" >> "$BLOG"; else echo "ASSET_FAILED $slug" >> "$BLOG"; fi
}

total=${#ASSETS[@]}
for entry in "${ASSETS[@]}"; do
  IFS='|' read -r slug poly prompt <<< "$entry"
  run_asset "$slug" "$poly" "$prompt" &
  while [ "$(jobs -r | wc -l)" -ge "$MAXJOBS" ]; do sleep 5; done
done
wait
done=$(grep -c ASSET_DONE "$BLOG" || true); fail=$(grep -c ASSET_FAILED "$BLOG" || true)
echo "BATCH COMPLETE done=$done failed=$fail total=$total" >> "$BLOG"
