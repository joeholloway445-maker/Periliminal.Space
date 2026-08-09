#!/usr/bin/env bash
# Fetch CC0 PBR texture sets from Poly Haven into godot/assets/textures/,
# named for the slots AssetLibrary.material() already reads:
#   <slot>_albedo.jpg  <slot>_normal.jpg  <slot>_rough.jpg  <slot>_metallic.jpg
#
# Poly Haven is CC0 (public domain) — no attribution required, commercial OK.
# API docs: https://redocly.github.io/redoc/?url=https://api.polyhaven.com/api-docs
#
# Resolution: 1k by default. The ship target is a Godot *Web* export, where a
# 2k set per slot quadruples both repo weight and the VRAM-compressed export;
# facades tile heavily and are viewed from tens of metres, so 1k is the honest
# quality/size point. Override for a desktop-only build:
#     RES=2k bash scripts/fetch_polyhaven_textures.sh
#
# Re-running is safe: existing files are skipped unless FORCE=1.

set -uo pipefail

RES="${RES:-1k}"
FORCE="${FORCE:-0}"
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/godot/assets/textures"
API="https://api.polyhaven.com/files"

mkdir -p "$OUT"

# slot|polyhaven_asset_id
SLOTS=(
  # --- city exterior (slots MegaCityBuilder / BuildingBuilder ask for) ---
  "asphalt|asphalt_02"
  "sidewalk|concrete_pavement"
  "facade_concrete|concrete_tile_facade"
  "facade_brick|brick_wall_006"
  "facade_metal|corrugated_iron_02"
  "facade_glass|rectangular_facade_tiles"
  "streetlight|metal_plate"
  "neon|metal_plate"
  "city_prop|painted_concrete_02"
  # --- interiors (venues, apartment, guild hideout) ---
  "interior_floor|wood_floor_deck"
  "interior_wall|plaster_brick_01"
  "interior_carpet|dirty_carpet"
  "interior_marble|marble_01"
  "interior_tile|floor_tiles_02"
)

# polyhaven map name -> our suffix
declare -A MAPS=(
  [Diffuse]=albedo
  [nor_gl]=normal
  [Rough]=rough
  [Metal]=metallic
)

fetched=0; skipped=0; missing=0

for entry in "${SLOTS[@]}"; do
  slot="${entry%%|*}"
  asset="${entry##*|}"

  json="$(curl -sS --retry 3 --retry-delay 2 "$API/$asset")" || { echo "!! $slot: API failed"; continue; }
  if [ -z "$json" ] || [ "${json:0:1}" != "{" ]; then
    echo "!! $slot ($asset): no such asset"; missing=$((missing+1)); continue
  fi

  for map in "${!MAPS[@]}"; do
    suffix="${MAPS[$map]}"
    dest="$OUT/${slot}_${suffix}.jpg"

    if [ -f "$dest" ] && [ "$FORCE" != "1" ]; then
      skipped=$((skipped+1)); continue
    fi

    url="$(printf '%s' "$json" | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception: sys.exit(0)
m=d.get('$map') or {}
e=(m.get('$RES') or {}).get('jpg') or {}
print(e.get('url',''))
")"

    [ -z "$url" ] && continue

    if curl -sS --retry 3 --retry-delay 2 -o "$dest" "$url"; then
      # A truncated/HTML response is not a JPEG — drop it rather than ship it.
      if [ "$(od -An -tx1 -N2 "$dest" | tr -d ' \n')" != "ffd8" ]; then
        echo "!! ${slot}_${suffix}: not a JPEG, discarding"; rm -f "$dest"; continue
      fi
      printf '   %-26s %s (%s)\n' "${slot}_${suffix}.jpg" "$asset" "$(du -h "$dest" | cut -f1)"
      fetched=$((fetched+1))
    else
      echo "!! ${slot}_${suffix}: download failed"; rm -f "$dest"
    fi
  done
done

echo
echo "fetched=$fetched skipped=$skipped missing_assets=$missing  ->  $OUT"
du -sh "$OUT"
