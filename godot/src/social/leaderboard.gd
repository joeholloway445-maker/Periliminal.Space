class_name Leaderboard
extends Node
## Leaderboard reads and writes, server-first with a real offline fallback.
##
## Crowns are decided by CrownManager's local standings whether or not a
## server is reachable (`crown_manager.gd`), so those standings ARE the
## honest board when offline. Previously this class went silent without a
## Nakama host — the crown race was being computed on every score and had
## nowhere to surface.
##
## Every submit also posts to CrownManager, so a score counts toward the
## crown it feeds even in a solo or offline session.

signal loaded(entries: Array[Dictionary])

func fetch(board_id: String = "global_wins", limit: int = 20) -> void:
	if not _online():
		loaded.emit(_local(board_id, limit))
		return
	NetworkManager.call_rpc("get_leaderboard", {board_id = board_id, limit = limit},
		func(result: Dictionary):
			var records: Array[Dictionary] = []
			for rec in result.get("records", []):
				records.append({
					rank = rec.get("rank", 0),
					username = rec.get("username", "Unknown"),
					score = rec.get("score", 0),
					subscore = rec.get("subscore", 0),
				})
			# A fresh host with an empty board should not look like nobody
			# is competing while we still hold local standings.
			if records.is_empty():
				records = _local(board_id, limit)
			loaded.emit(records)
	)

func submit_score(board_id: String, score: int) -> void:
	# Local first: crowns are decided on this, and it must not wait on a
	# round trip or vanish when there is no host.
	if CrownManager:
		CrownManager.add_score(board_id, _self_id(), score, _guild_id())
	if _online():
		NetworkManager.call_rpc("submit_score", {board_id = board_id, score = score},
			func(_r): pass)

## CrownManager's standings, shaped like server records.
func _local(board_id: String, limit: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not CrownManager:
		return out
	for row in CrownManager.standings(board_id, limit):
		out.append({
			rank = int(row.get("rank", 0)),
			username = str(row.get("player_id", "Unknown")),
			score = int(row.get("score", 0)),
			subscore = 0,
		})
	return out

func _online() -> bool:
	return NetworkManager != null and NetworkManager.is_connected_to_server()

func _self_id() -> String:
	if PlayerProfile and not str(PlayerProfile.username).is_empty():
		return str(PlayerProfile.username)
	return "local_player"

func _guild_id() -> String:
	if SocialManager:
		return str(SocialManager.current_guild.get("id", ""))
	return ""
