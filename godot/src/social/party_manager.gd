extends Node
## Parties — the small group that runs a dungeon or a PvP mission together.
##
## Distinct from guilds (SocialManager, persistent, dozens of members) and
## from a PVXC run's party list (PeriliminalRuns.party, which is the roster
## of whoever is currently descending). This is the lobby you form BEFORE
## you open a door, and it is what DungeonManager's gate counts.
##
## Autoload as `PartyManager`. Deliberately in-memory: a party is a thing you
## are in right now, not a thing you save. Reconnect logic belongs to the
## networking layer if and when parties go cross-session.

signal party_changed(members: Array)
signal member_joined(player_id: String)
signal member_left(player_id: String)
signal party_disbanded()

const MAX_SIZE := 6

## player ids, leader first. Empty means "solo" — every read path treats an
## empty party and a party of just you identically, so nothing has to
## special-case being alone.
var _members: Array[String] = []

## Everyone in the party, or just you when there is no party.
func members() -> Array[String]:
	if _members.is_empty():
		return [_self_id()] as Array[String]
	return _members.duplicate()

func size() -> int:
	return members().size()

func is_in_party() -> bool:
	return _members.size() > 1

func leader() -> String:
	return _members[0] if not _members.is_empty() else _self_id()

func is_leader(player_id: String = "") -> bool:
	var who := player_id if not player_id.is_empty() else _self_id()
	return leader() == who

func has_member(player_id: String) -> bool:
	return members().has(player_id)

## Starts a party containing just you. Idempotent.
func create() -> void:
	if not _members.is_empty():
		return
	_members = [_self_id()] as Array[String]
	party_changed.emit(members())

## Returns {"ok": bool, "reason": String} so callers can show why it failed.
func add_member(player_id: String) -> Dictionary:
	if player_id.is_empty():
		return {"ok": false, "reason": "No such player."}
	if _members.is_empty():
		create()
	if _members.has(player_id):
		return {"ok": false, "reason": "%s is already in the party." % player_id}
	if _members.size() >= MAX_SIZE:
		return {"ok": false, "reason": "Party is full (%d)." % MAX_SIZE}
	_members.append(player_id)
	member_joined.emit(player_id)
	party_changed.emit(members())
	return {"ok": true, "reason": ""}

func remove_member(player_id: String) -> void:
	if not _members.has(player_id):
		return
	_members.erase(player_id)
	member_left.emit(player_id)
	# A party of one is just a person; collapse it so the gate sees solo.
	if _members.size() <= 1:
		disband()
		return
	party_changed.emit(members())

## Leaving as the leader hands the party to the next member rather than
## stranding it — nobody loses a group because one person walked away.
func leave() -> void:
	remove_member(_self_id())

func disband() -> void:
	if _members.is_empty():
		return
	_members.clear()
	party_disbanded.emit()
	party_changed.emit(members())

func _self_id() -> String:
	if PlayerProfile and not str(PlayerProfile.username).is_empty():
		return str(PlayerProfile.username)
	return "local_player"
