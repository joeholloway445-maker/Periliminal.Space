#!/usr/bin/env bash
# Generate the complete identity matrix, committing as it goes.
#
#   20 races x 20 frames x 20 morph rigs x 2 sexes = 16,000 images
#
# That is roughly a 16-hour run at the sustainable rate, so it is built to
# survive being interrupted: every pass skips targets that already exist, and
# it commits and pushes every 200 images. Killing it and re-running loses
# nothing but the images in flight.
#
#   nohup setsid bash scripts/run_full_stack.sh > /tmp/full_stack.log 2>&1 &
#
# Order matters. The partial sets (race, race+frame, race+mod) are generated
# first because IdentityArt falls back through them — a player picking a
# combination the full stack has not reached yet still sees the closest
# available art rather than nothing.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="$REPO/godot/assets/entities"
WORKERS="${WORKERS:-16}"
COMMIT_EVERY="${COMMIT_EVERY:-200}"

cd "$REPO" || exit 1

count() { ls "$ART"/*.png 2>/dev/null | wc -l | tr -d ' '; }

commit_push() {
  local n
  n="$(git status --porcelain "$ART" | wc -l | tr -d ' ')"
  [ "$n" -eq 0 ] && return 0
  for i in 1 2 3; do
    git add "$ART" >/dev/null 2>&1
    git commit -q -m "assets: identity matrix — $(count) images

Full race x frame x morph rig x sex stack, generated with Pollinations from
scripts/prompt_templates.py per STYLE_BIBLE.md.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MzchtHYwveEvLaZ2VP1MHY" 2>/dev/null && break
    sleep 3
  done
  for i in 1 2 3 4; do
    git push -q origin HEAD 2>/dev/null && break
    sleep $((2 ** i))
  done
  echo "  committed at $(count) images  $(date +%H:%M)"
}

remaining() {
  python3 - "$1" <<'PY'
import json, os, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
print(sum(1 for r in rows if not os.path.exists(r["sprite_target"])))
PY
}

# Partial sets first so the fallback chain is dense before the deep matrix.
for JOBS in build/rm_sexed.jsonl build/full_stack.jsonl; do
  echo "== $JOBS  ($(remaining "$JOBS") remaining)  $(date +%H:%M)"
  for pass in $(seq 1 20); do
    left="$(remaining "$JOBS")"
    [ "$left" -eq 0 ] && { echo "   done"; break; }
    echo "   [pass $pass] $left left  $(date +%H:%M)"

    last="$(count)"
    python3 scripts/generate_assets.py --jobs "$JOBS" --kind all \
        --workers "$WORKERS" >> /tmp/stack_gen.log 2>&1 &
    gen=$!
    while kill -0 "$gen" 2>/dev/null; do
      sleep 45
      now="$(count)"
      if [ $((now - last)) -ge "$COMMIT_EVERY" ]; then
        commit_push
        last="$now"
      fi
    done
    wait "$gen"
    commit_push
  done
done

echo "== COMPLETE $(count) images  $(date +%H:%M)"
