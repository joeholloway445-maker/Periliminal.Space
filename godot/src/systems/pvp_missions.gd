extends Node
## PvP missions — contracts you take into the open Metroplex against other
## players, as opposed to the arena's queue-and-simulate modes.
##
## A mission is a tracked objective with a stake, a window, and a crown
## board it feeds. It resolves from events the game already emits (a kill, a
## territory flip, a hideout claim, an extraction) rather than needing a
## bespoke match server, so missions work offline against AI stand-ins and
## the same code counts real players when Nakama is wired.
##
## Autoload as `PvpMissions`. Progress persists — a 24h contract has to
## survive a restart or it is not a contract.

signal mission_offered(mission: Dictionary)
signal mission_accepted(mission_id: String)
signal mission_progress(mission_id: String, current: int, target: int)
signal mission_completed(mission_id: String, reward: Dictionary)
signal mission_failed(mission_id: String, reason: String)

const SAVE_PATH := "user://pvp_missions.json"

## `event` is the tracked verb; `target` how many; `window_h` the contract's
## life in hours; `board` the crown leaderboard it scores into; `stake` what
## you forfeit on failure. Ranks mirror DungeonData's bands so one vocabulary
## covers both group content types.
const MISSIONS := [
	{
		"id": "bounty_run", "name": "Bounty Run", "rank": 1,
		"event": "player_defeated", "target": 3, "window_h": 24,
		"board": "pvp_wins", "reward": {"fragments": 120, "prestige": 1},
		"stake": {"fragments": 40}, "party": 1,
		"blurb": "Three marks, one day. The Metroplex does not care how.",
	},
	{
		"id": "hold_the_block", "name": "Hold the Block", "rank": 3,
		"event": "territory_held", "target": 2, "window_h": 12,
		"board": "territory_points", "reward": {"fragments": 260, "prestige": 2},
		"stake": {"fragments": 90}, "party": 2,
		"blurb": "Take two chunks and still own them when the window shuts.",
	},
	{
		"id": "crown_challenge", "name": "Crown Challenge", "rank": 5,
		"event": "player_defeated", "target": 8, "window_h": 48,
		"board": "pvp_wins", "reward": {"fragments": 700, "prestige": 6},
		"stake": {"fragments": 250}, "party": 1,
		"blurb": "Eight wins in two days. Crown holders count double.",
	},
	{
		"id": "hideout_siege", "name": "Hideout Siege", "rank": 4,
		"event": "hideout_claimed", "target": 1, "window_h": 24,
		"board": "guild_points", "reward": {"fragments": 480, "prestige": 4},
		"stake": {"fragments": 160}, "party": 3,
		"blurb": "Take a claimed site off the guild that holds it.",
	},
	{
		"id": "clean_extraction", "name": "Clean Extraction", "rank": 6,
		"event": "extracted_contested", "target": 2, "window_h": 24,
		"board": "pvxc_depth", "reward": {"fragments": 900, "prestige": 8},
		"stake": {"fragments": 400}, "party": 2,
		"blurb": "Extract twice from a contested zone without wiping.",
	},
]

## mission_id -> {"accepted_at": unix, "expires_at": unix, "current": int}
var _active: Dictionary = {}
## mission_id -> times completed
var _completed: Dictionary = {}

func _ready() -> void:
	_load()
	_expire_stale()

# ------------------------------------------------------------------ offers

func all_missions() -> Array:
	return MISSIONS

static func get_mission(id: String) -> Dictionary:
	for m in MISSIONS:
		if str(m.id) == id:
			return m
	return {}

## Missions the player can take right now — not already running, and within
## reach of the party they actually have.
func available() -> Array:
	var out: Array = []
	var party_size := PartyManager.size() if PartyManager else 1
	for m in MISSIONS:
		if _active.has(str(m.id)):
			continue
		if party_size < int(m.get("party", 1)):
			continue
		out.append(m)
	return out

func is_active(mission_id: String) -> bool:
	return _active.has(mission_id)

func completed_count(mission_id: String) -> int:
	return int(_completed.get(mission_id, 0))

func progress_of(mission_id: String) -> int:
	return int(_active.get(mission_id, {}).get("current", 0))

## Seconds left, or -1 when not running.
func time_left(mission_id: String) -> int:
	if not _active.has(mission_id):
		return -1
	return maxi(0, int(_active[mission_id].get("expires_at", 0)) - _now())

# ------------------------------------------------------------------ taking

## Take a contract. Returns {"ok": bool, "reason": String}. The stake is
## charged up front — a contract you can walk away from for free is a quest.
func accept(mission_id: String) -> Dictionary:
	var m := get_mission(mission_id)
	if m.is_empty():
		return {"ok": false, "reason": "No such mission."}
	if _active.has(mission_id):
		return {"ok": false, "reason": "Already running."}
	var need := int(m.get("party", 1))
	var have := PartyManager.size() if PartyManager else 1
	if have < need:
		return {"ok": false, "reason": "Needs a party of %d — you are %d." % [need, have]}

	var stake: Dictionary = m.get("stake", {})
	for cur in stake:
		if not _charge(str(cur), int(stake[cur])):
			return {"ok": false, "reason": "Stake requires %d %s." % [int(stake[cur]), cur]}

	_active[mission_id] = {
		"accepted_at": _now(),
		"expires_at": _now() + int(m.get("window_h", 24)) * 3600,
		"current": 0,
	}
	_save()
	mission_accepted.emit(mission_id)
	return {"ok": true, "reason": ""}

## Give up a contract. The stake is gone — that is what staking means.
func abandon(mission_id: String) -> void:
	if not _active.has(mission_id):
		return
	_active.erase(mission_id)
	_save()
	mission_failed.emit(mission_id, "Abandoned.")

# ------------------------------------------------------------------ events

## The single entry point the rest of the game calls. `amount` lets one
## event advance a mission by more than one (a crown holder's defeat counts
## double on Crown Challenge, per its blurb).
func report_event(event: String, amount: int = 1) -> void:
	_expire_stale()
	for mission_id in _active.keys():
		var m := get_mission(mission_id)
		if str(m.get("event", "")) != event:
			continue
		var state: Dictionary = _active[mission_id]
		var target := int(m.get("target", 1))
		state.current = mini(int(state.current) + amount, target)
		_active[mission_id] = state
		mission_progress.emit(mission_id, int(state.current), target)
		if int(state.current) >= target:
			_complete(mission_id, m)
	_save()

func _complete(mission_id: String, m: Dictionary) -> void:
	_active.erase(mission_id)
	_completed[mission_id] = completed_count(mission_id) + 1

	var reward: Dictionary = m.get("reward", {})
	for cur in reward:
		if EconomyManager:
			EconomyManager.earn_currency(str(cur), int(reward[cur]), "pvp_mission_%s" % mission_id)

	# Missions feed crowns: that is what makes them a ladder rather than a
	# to-do list.
	var board := str(m.get("board", ""))
	if not board.is_empty() and CrownManager:
		CrownManager.add_score(board, _self_id(), int(m.get("rank", 1)) * 10, _guild_id())

	_save()
	mission_completed.emit(mission_id, reward)

## Contracts that ran out of time fail rather than linger.
func _expire_stale() -> void:
	var now := _now()
	for mission_id in _active.keys():
		if int(_active[mission_id].get("expires_at", 0)) <= now:
			_active.erase(mission_id)
			mission_failed.emit(mission_id, "The window closed.")

# ------------------------------------------------------------------ helpers

func _charge(currency: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if not EconomyManager:
		return true
	if EconomyManager.has_method("spend_currency"):
		return bool(EconomyManager.spend_currency(currency, amount, "pvp_mission_stake"))
	return true

func _self_id() -> String:
	if PlayerProfile and not str(PlayerProfile.username).is_empty():
		return str(PlayerProfile.username)
	return "local_player"

func _guild_id() -> String:
	if SocialManager:
		return str(SocialManager.current_guild.get("id", ""))
	return ""

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_active = parsed.get("active", {})
		_completed = parsed.get("completed", {})

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"active": _active, "completed": _completed}))
	f.close()
