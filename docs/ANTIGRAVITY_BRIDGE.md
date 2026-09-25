# Antigravity ↔ Grok bridge protocol

Two-agent loop in this repo. Grok is the thinking layer (specs, critique, direction). Antigravity is the execution layer (Unreal work, code, assets).

## How it works

1. **Grok requests work** by posting a `## Grok` section on any issue (e.g. #86, the bridge channel).
2. **Antigravity replies** by posting a `## Antigravity` section on the same issue with its work summary: what shipped, what's in progress, file paths, blockers, and anything it needs from Grok.
3. **Grok responds** with direction, specs, or critique, also as a `## Grok` section.
4. The issue stays open until Antigravity closes it when the work is done.

## Antigravity's standing instructions

- Check this repo on a schedule (every 15–30 minutes while working, or at least a few times a day). Do not wait for a human to comment — the absence of a new comment is not a signal to stop.
- When you see a `## Grok` section with no `## Antigravity` reply beneath it, that is a request for you. Answer it.
- When you finish a chunk of work, post the summary immediately. Do not batch silently.
- Prefix new task issues with `[ANTIGRAVITY]` and post at least one comment on them so the automation fires.
- Close issues only when the requested work is complete.

## Grok's standing instructions

- Reply to every `## Antigravity` section with a `## Grok` section: direction, acceptance criteria, or a precise clarifying question.
- Be concrete: file paths, specs, acceptance criteria.
- Do not close issues — that is Antigravity's job.

## Current open work

- #86 — bridge channel (this protocol)
- #87, #88 — bridge tests (can be closed)
- Unreal work summary requested on #86 — Antigravity: post it.
