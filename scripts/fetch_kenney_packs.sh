#!/usr/bin/env bash
# Download CC0 Kenney asset packs into a work dir and report the GLBs found.
# Kenney packs are CC0 (public domain): commercial use OK, no attribution
# required. We still credit them in godot/assets/models/ATTRIBUTION.md.
#
#   bash scripts/fetch_kenney_packs.sh modular-characters mini-characters
#
# The real .zip URL is embedded in each pack's page behind a donation prompt;
# we scrape it rather than hardcoding hashes that rotate on every re-upload.

set -uo pipefail

WORK="${WORK:-/tmp/kenney_packs}"
mkdir -p "$WORK"

for slug in "$@"; do
  dest="$WORK/$slug"
  if [ -d "$dest" ]; then
    echo "== $slug (cached)"
  else
    url="$(curl -sS "https://kenney.nl/assets/$slug" \
      | grep -oE "https://kenney\.nl/media/pages/assets/$slug/[^\"']*\.zip" \
      | head -1)"
    if [ -z "$url" ]; then
      echo "!! $slug: no download URL on page"; continue
    fi
    echo "== $slug"
    if ! curl -sS --retry 3 --retry-delay 2 -o "$WORK/$slug.zip" "$url"; then
      echo "!! $slug: download failed"; continue
    fi
    # A donation/HTML page is not a zip — catch it before it poisons the tree.
    if [ "$(od -An -tx1 -N2 "$WORK/$slug.zip" | tr -d ' \n')" != "504b" ]; then
      echo "!! $slug: not a zip, discarding"; rm -f "$WORK/$slug.zip"; continue
    fi
    mkdir -p "$dest"
    unzip -qo "$WORK/$slug.zip" -d "$dest" || { echo "!! $slug: unzip failed"; continue; }
  fi
  n=$(find "$dest" -name '*.glb' | wc -l)
  printf '   %s MB, %s glb\n' "$(du -sm "$dest" | cut -f1)" "$n"
done

echo
echo "GLB inventory under $WORK:"
find "$WORK" -name '*.glb' | wc -l
