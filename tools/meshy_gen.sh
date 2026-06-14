#!/usr/bin/env bash
# Meshy asset generation pipeline:
#   Nanobanana Pro (text-to-image) -> Meshy image-to-3D -> download GLB + textures
#
# Usage: meshy_gen.sh <slug> <polycount> <prompt...>
# Outputs:
#   assets/models/<slug>.glb        final textured mesh
#   tools/shots/<slug>.png          Meshy render thumbnail (for quick review)
#   tools/meshy/<slug>.json         full task metadata + credit usage
set -uo pipefail

SLUG="$1"; POLY="$2"; shift 2; PROMPT="$*"
ROOT="/home/user/Life-Theory"
KEY="$(node -e "console.log(require('$ROOT/.claude/settings.local.json').env.MESHY_API_KEY)")"
API="https://api.meshy.ai/openapi/v1"
mkdir -p "$ROOT/assets/models" "$ROOT/tools/shots" "$ROOT/tools/meshy"
LOG="$ROOT/tools/meshy/$SLUG.log"; : > "$LOG"
say(){ echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

jget(){ node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(eval('JSON.parse(d)$1'))}catch(e){console.log('')}})"; }

# ---- 1. Nanobanana Pro image ------------------------------------------------
say "submitting text-to-image (nano-banana-pro): $SLUG"
IMG_RESP=$(curl -s -X POST "$API/text-to-image" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "$(node -e "process.stdout.write(JSON.stringify({ai_model:'nano-banana-pro',prompt:process.argv[1],aspect_ratio:'1:1'}))" "$PROMPT")")
IMG_ID=$(echo "$IMG_RESP" | jget ".result"); say "image task: $IMG_ID"
[ -z "$IMG_ID" ] && { say "FAILED to submit image: $IMG_RESP"; exit 1; }

for i in $(seq 1 80); do
  sleep 5
  R=$(curl -s "$API/text-to-image/$IMG_ID" -H "Authorization: Bearer $KEY")
  ST=$(echo "$R" | jget ".status"); PR=$(echo "$R" | jget ".progress")
  say "  image $ST $PR%"
  if [ "$ST" = "SUCCEEDED" ]; then IMG_URL=$(echo "$R" | jget ".image_urls[0]"); break; fi
  if [ "$ST" = "FAILED" ] || [ "$ST" = "CANCELED" ]; then say "image FAILED: $R"; exit 1; fi
done
[ -z "${IMG_URL:-}" ] && { say "image timed out"; exit 1; }
say "image url ok"
curl -s "$IMG_URL" -o "$ROOT/tools/shots/${SLUG}_src.png"

# ---- 2. Image -> 3D ---------------------------------------------------------
say "submitting image-to-3d: $SLUG (poly=$POLY)"
M_RESP=$(curl -s -X POST "$API/image-to-3d" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "$(node -e "process.stdout.write(JSON.stringify({image_url:process.argv[1],ai_model:'meshy-5',should_texture:true,enable_pbr:true,topology:'triangle',target_polycount:parseInt(process.argv[2]),target_formats:['glb']}))" "$IMG_URL" "$POLY")")
M_ID=$(echo "$M_RESP" | jget ".result"); say "3d task: $M_ID"
[ -z "$M_ID" ] && { say "FAILED to submit 3d: $M_RESP"; exit 1; }

for i in $(seq 1 180); do
  sleep 6
  R=$(curl -s "$API/image-to-3d/$M_ID" -H "Authorization: Bearer $KEY")
  ST=$(echo "$R" | jget ".status"); PR=$(echo "$R" | jget ".progress")
  say "  3d $ST $PR%"
  if [ "$ST" = "SUCCEEDED" ]; then
    echo "$R" > "$ROOT/tools/meshy/$SLUG.json"
    GLB=$(echo "$R" | jget ".model_urls.glb"); THUMB=$(echo "$R" | jget ".thumbnail_url")
    CR=$(echo "$R" | jget ".consumed_credits")
    curl -s "$GLB" -o "$ROOT/assets/models/${SLUG}.glb"
    [ -n "$THUMB" ] && curl -s "$THUMB" -o "$ROOT/tools/shots/${SLUG}.png"
    SZ=$(du -h "$ROOT/assets/models/${SLUG}.glb" | cut -f1)
    say "DONE: assets/models/${SLUG}.glb ($SZ), 3d credits=$CR"
    exit 0
  fi
  if [ "$ST" = "FAILED" ] || [ "$ST" = "CANCELED" ]; then say "3d FAILED: $R"; exit 1; fi
done
say "3d timed out"; exit 1
