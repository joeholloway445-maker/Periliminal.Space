#!/usr/bin/env bash
# Run a generation batch and commit every N new images.
#
# The generator writes straight into godot/assets/entities/, so a long run
# leaves hundreds of untracked files sitting in the tree. This watches the
# count and commits in batches, which keeps the working tree clean during a
# multi-hour run and means an interrupted run has already banked its work.
#
#   bash scripts/generate_and_commit.sh build/race_frames.jsonl 50 "race x frame"
#
# Safe to interrupt: the generator skips targets that already exist, so
# re-running the same job file resumes rather than repeating.

set -uo pipefail

JOBS="${1:?usage: generate_and_commit.sh <jobs.jsonl> [batch] [label]}"
BATCH="${2:-50}"
LABEL="${3:-$(basename "$JOBS" .jsonl)}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="$REPO/godot/assets/entities"
LOG="/tmp/gen_$(basename "$JOBS" .jsonl).log"

cd "$REPO" || exit 1
mkdir -p "$ART"

count() { ls "$ART"/*.png 2>/dev/null | wc -l | tr -d ' '; }

commit_batch() {
  local n
  n="$(git status --porcelain "$ART" | wc -l | tr -d ' ')"
  [ "$n" -eq 0 ] && return 0
  git add "$ART" >/dev/null 2>&1
  git commit -q -m "assets: $LABEL sprites (+$n)

Generated with Pollinations from scripts/prompt_templates.py, composed per
STYLE_BIBLE.md. Batch-committed during a long run so the tree stays clean
and an interrupted run keeps its work.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01MzchtHYwveEvLaZ2VP1MHY" || return 0
  for i in 1 2 3 4; do
    git push -q origin HEAD 2>/dev/null && break
    sleep $((2 ** i))
  done
  echo "  committed +$n  (total $(count))"
}

echo "== $LABEL — $(grep -c . "$JOBS") jobs, committing every $BATCH"
python3 scripts/generate_assets.py --jobs "$JOBS" --kind all --workers "${WORKERS:-8}" > "$LOG" 2>&1 &
GEN=$!

last="$(count)"
while kill -0 "$GEN" 2>/dev/null; do
  sleep 30
  now="$(count)"
  if [ $((now - last)) -ge "$BATCH" ]; then
    commit_batch
    last="$now"
  fi
done

wait "$GEN"
commit_batch
echo "== $LABEL done — $(count) images total"
tail -2 "$LOG"
