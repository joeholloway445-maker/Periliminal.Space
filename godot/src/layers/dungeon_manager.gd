extends Node
## Tracks which Periliminal dungeons are open, who has cleared them, and —
## the part that matters — which ones have a confirmed rank.
##
## A dungeon's rank stays PROVISIONAL until its first clear anywhere on the
## server. Until then every entrance plate reads "Rank ?" and the roster
## shows the estimated band in brackets. The first party to walk back out
## sets the real rank via DungeonData.rank_from_clear(), it is written to
## the ledger, and it never moves again.
##
## Autoload as `DungeonManager`. Persistence rides on the same user:// save
## convention the rest of the project uses, so a first clear survives a
## restart and is not silently re-rolled by the next party.

signal dungeon_unlocked(dungeon_id: String)
signal dungeon_cleared(dungeon_id: String, party: Array, rank: int)
signal rank_confirmed(dungeon_id: String, rank: int)

const SAVE_PATH := "user://dungeon_ledger.json"

## dungeon_id -> {"rank": int, "confirmed": bool, "first_party": Array,
##                "first_depth": int, "clears": int}
var _ledger: Dictionary = {}

## The dungeon whose seal is currently open, "" when the party is on an
## ordinary Periliminal wander rather than a sealed descent.
var active_dungeon := ""
var _deaths := 0

func _ready() -> void:
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	_load()
	if PeriliminalRuns:
		# Walking out alive of a run started at a sealed door is the clear
		# that proves the rank; a wipe proves nothing and leaves it unranked.
		PeriliminalRuns.run_survived.connect(_on_run_survived)
		PeriliminalRuns.run_wiped.connect(_on_run_wiped)

## Called by DungeonEntrance the moment a seal opens, so the run that follows
## is attributed to this dungeon rather than to the open Periliminal.
func begin_dungeon(dungeon_id: String) -> void:
	active_dungeon = dungeon_id
	_deaths = 0

func _on_run_survived(depth_reached: int, _fragments: int) -> void:
	var PeriliminalRuns = AutoloadGate.get_node("PeriliminalRuns")
	if active_dungeon.is_empty():
		return
	var party: Array = PeriliminalRuns.party.duplicate() if PeriliminalRuns else []
	record_clear(active_dungeon, party, depth_reached, _deaths)
	active_dungeon = ""
	_deaths = 0

func _on_run_wiped(_depth: int, victims: Array) -> void:
	# A wipe is not a clear. The rank stays unproven — which is the point.
	_deaths += victims.size()
	active_dungeon = ""

# ------------------------------------------------------------------ state

## Confirmed rank if somebody has beaten it, otherwise the estimate.
func rank_of(dungeon_id: String) -> int:
	if _ledger.has(dungeon_id):
		return int(_ledger[dungeon_id].get("rank", 3))
	return int(DungeonData.get_dungeon(dungeon_id).get("provisional", 3))

func is_rank_confirmed(dungeon_id: String) -> bool:
	return bool(_ledger.get(dungeon_id, {}).get("confirmed", false))

## "Rank ?" until proven — the whole point of the mechanic. Once confirmed
## it reads plainly; before that the estimate is shown in brackets so a party
## can still judge roughly what they are walking into.
func rank_text(dungeon_id: String) -> String:
	var label := DungeonData.rank_label(rank_of(dungeon_id))
	if is_rank_confirmed(dungeon_id):
		return "Rank %s" % label
	return "Rank ?  (est. %s)" % label

func clear_count(dungeon_id: String) -> int:
	return int(_ledger.get(dungeon_id, {}).get("clears", 0))

## Who proved the rank, for the entrance plate and the crown hall.
func first_clear_party(dungeon_id: String) -> Array:
	return _ledger.get(dungeon_id, {}).get("first_party", [])

# ------------------------------------------------------------------ gating

## Can this party open the door? Returns {"ok": bool, "reason": String}.
func can_enter(dungeon_id: String, party: Array, level: int, keys: Array) -> Dictionary:
	var d := DungeonData.get_dungeon(dungeon_id)
	if d.is_empty():
		return {"ok": false, "reason": "No such dungeon."}
	if level < int(d.get("min_level", 1)):
		return {"ok": false, "reason": "Requires level %d." % int(d.min_level)}
	var need := int(d.get("party", 1))
	if party.size() < need:
		return {"ok": false, "reason": "Needs a party of %d — you are %d." % [need, party.size()]}
	var key := str(d.get("key", ""))
	if not key.is_empty() and not keys.has(key):
		return {"ok": false, "reason": "Sealed. Needs the %s." % key.replace("_", " ")}
	return {"ok": true, "reason": ""}

## Fires the unlock signal the first time a player satisfies the gate, so
## the entrance can change state without polling.
func note_unlocked(dungeon_id: String) -> void:
	dungeon_unlocked.emit(dungeon_id)

# ------------------------------------------------------------------ clears

## Record a successful descent. The first one confirms the rank forever.
func record_clear(dungeon_id: String, party: Array, depth_reached: int, deaths: int) -> int:
	var d := DungeonData.get_dungeon(dungeon_id)
	if d.is_empty():
		return -1

	var entry: Dictionary = _ledger.get(dungeon_id, {})
	var first := not bool(entry.get("confirmed", false))

	if first:
		var rank := DungeonData.rank_from_clear(d, depth_reached, party.size(), deaths)
		entry = {
			"rank": rank,
			"confirmed": true,
			"first_party": party.duplicate(),
			"first_depth": depth_reached,
			"clears": 1,
		}
		_ledger[dungeon_id] = entry
		_save()
		rank_confirmed.emit(dungeon_id, rank)
		dungeon_cleared.emit(dungeon_id, party, rank)
		return rank

	entry["clears"] = int(entry.get("clears", 0)) + 1
	_ledger[dungeon_id] = entry
	_save()
	dungeon_cleared.emit(dungeon_id, party, int(entry.get("rank", 3)))
	return int(entry.get("rank", 3))

## Every dungeon still awaiting a first clear — the "unproven" board.
func unproven() -> Array:
	var out: Array = []
	for d in DungeonData.all():
		if not is_rank_confirmed(str(d.id)):
			out.append(d)
	return out

# ------------------------------------------------------------------ save

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_ledger = parsed

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_ledger))
	f.close()
