#!/usr/bin/env bash
# Finish a generation job list, retrying what the image service throttles.
#
# Concurrency is deliberately moderate. Measured against Pollinations: 80
# concurrent workers start fast then collapse to a ~21% success rate as the
# service throttles, so most of the work becomes retries. 16 sustains a high
# success rate and finishes sooner despite the lower burst.
#
# Each pass skips targets that already exist, so passes get cheaper as the
# set fills. Stops early when nothing is left.
#
#   bash scripts/finish_generation.sh build/all_remaining.jsonl [workers]

set -uo pipefail

JOBS="${1:?usage: finish_generation.sh <jobs.jsonl> [workers]}"
WORKERS="${2:-16}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG=/tmp/finish_gen.log

cd "$REPO" || exit 1
: > "$LOG"

remaining() {
  python3 - "$JOBS" <<'PY'
import json, os, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
print(sum(1 for r in rows if not os.path.exists(r["sprite_target"])))
PY
}

for pass in $(seq 1 12); do
  left="$(remaining)"
  echo "[pass $pass] $left remaining  $(date +%H:%M:%S)"
  [ "$left" -eq 0 ] && break
  python3 scripts/generate_assets.py --jobs "$JOBS" --kind all \
      --workers "$WORKERS" >> "$LOG" 2>&1
  sleep 5
done

echo "COMPLETE — $(ls godot/assets/entities/*.png 2>/dev/null | wc -l) images  $(date +%H:%M:%S)"
