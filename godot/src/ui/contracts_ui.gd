class_name ContractsUI
extends Control
## One board for the three things a group signs up to: PvP mission
## contracts, the party you would run them with, and the dungeons whose
## ranks nobody has proved yet.
##
## Built entirely in code (following arena_hub_ui.gd) so it needs no .tscn
## and can be dropped in with `add_child(ContractsUI.new())`.
##
## Everything here reads live state — contracts show their real countdown,
## dungeon ranks show "?" until proven — so this doubles as the readout for
## whether PvpMissions and DungeonManager are actually firing.

const REFRESH_SECONDS := 1.0

var _mission_list: VBoxContainer
var _party_list: VBoxContainer
var _dungeon_list: VBoxContainer
var _tick := 0.0

func _ready() -> void:
	var PvpMissions = AutoloadGate.get_node("PvpMissions")
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var DungeonManager = AutoloadGate.get_node("DungeonManager")
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	var title := Label.new()
	title.text = "CONTRACTS"
	title.add_theme_font_size_override("font_size", 34)
	root.add_child(title)

	_mission_list = _section(root, "PvP Missions",
		"Staked contracts in the open Metroplex. The stake is charged when you accept.")
	_party_list = _section(root, "Party",
		"Who you would take in. Dungeons and the heavier missions check this.")
	_dungeon_list = _section(root, "Periliminal Dungeons",
		"Ranks read “?” until a party walks back out of one.")

	_refresh_all()

	if PvpMissions:
		PvpMissions.mission_accepted.connect(func(_id): _refresh_missions())
		PvpMissions.mission_completed.connect(func(_id, _r): _refresh_missions())
		PvpMissions.mission_failed.connect(func(_id, _r): _refresh_missions())
		PvpMissions.mission_progress.connect(func(_i, _c, _t): _refresh_missions())
	if PartyManager:
		# Party size gates which missions can be accepted, so both lists move.
		PartyManager.party_changed.connect(func(_m):
			_refresh_party()
			_refresh_missions())
	if DungeonManager:
		DungeonManager.rank_confirmed.connect(func(_id, _r): _refresh_dungeons())

## Countdowns are the only thing that changes without a signal.
func _process(delta: float) -> void:
	_tick += delta
	if _tick < REFRESH_SECONDS:
		return
	_tick = 0.0
	# Only a running contract has a countdown that needs redrawing.
	if _has_active():
		_refresh_missions()

func _has_active() -> bool:
	var PvpMissions = AutoloadGate.get_node("PvpMissions")
	if not PvpMissions:
		return false
	for m in PvpMissions.all_missions():
		if PvpMissions.is_active(str(m.id)):
			return true
	return false

# ------------------------------------------------------------------ layout

func _section(parent: Node, heading: String, blurb: String) -> VBoxContainer:
	var head := Label.new()
	head.text = heading
	head.add_theme_font_size_override("font_size", 22)
	parent.add_child(head)

	var sub := Label.new()
	sub.text = blurb
	sub.add_theme_font_size_override("font_size", 13)
	sub.modulate = Color(1, 1, 1, 0.62)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(sub)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	parent.add_child(list)
	return list

static func _clear(list: Node) -> void:
	for c in list.get_children():
		c.queue_free()

func _row(list: Node, text: String, dim := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if dim:
		label.modulate = Color(1, 1, 1, 0.55)
	row.add_child(label)
	list.add_child(row)
	return row

# ------------------------------------------------------------------ content

func _refresh_all() -> void:
	_refresh_missions()
	_refresh_party()
	_refresh_dungeons()

func _refresh_missions() -> void:
	var PvpMissions = AutoloadGate.get_node("PvpMissions")
	var PartyManager = AutoloadGate.get_node("PartyManager")
	if _mission_list == null or not PvpMissions:
		return
	_clear(_mission_list)

	for m in PvpMissions.all_missions():
		var id := str(m.id)
		var target := int(m.get("target", 1))
		var stake: Dictionary = m.get("stake", {})
		var reward: Dictionary = m.get("reward", {})

		if PvpMissions.is_active(id):
			var left = PvpMissions.time_left(id)
			var row := _row(_mission_list, "%s   %d/%d   %s left\n%s" % [
				str(m.name), PvpMissions.progress_of(id), target,
				_hms(left), str(m.blurb)])
			var give_up := Button.new()
			give_up.text = "Abandon"
			give_up.pressed.connect(func(): PvpMissions.abandon(id))
			row.add_child(give_up)
			continue

		var done = PvpMissions.completed_count(id)
		var line := "%s   Rank %s   stake %s → %s%s\n%s" % [
			str(m.name), DungeonData.rank_label(int(m.get("rank", 1))),
			_currency(stake), _currency(reward),
			("   (cleared %dx)" % done) if done > 0 else "",
			str(m.blurb)]

		var party_needed := int(m.get("party", 1))
		var party_have = PartyManager.size() if PartyManager else 1
		var short = party_have < party_needed
		var row2 := _row(_mission_list, line, short)

		var take := Button.new()
		take.text = "Accept"
		take.disabled = short
		if short:
			take.tooltip_text = "Needs a party of %d — you are %d." % [party_needed, party_have]
		take.pressed.connect(_accept_mission.bind(id))
		row2.add_child(take)

func _accept_mission(id: String) -> void:
	var PvpMissions = AutoloadGate.get_node("PvpMissions")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	var res: Dictionary = await PvpMissions.accept(id)
	if not bool(res.ok) and NotificationUI:
		NotificationUI.notify_error(str(res.reason))

func _refresh_party() -> void:
	var PartyManager = AutoloadGate.get_node("PartyManager")
	var NotificationUI = AutoloadGate.get_node("NotificationUI")
	if _party_list == null:
		return
	_clear(_party_list)
	if not PartyManager:
		_row(_party_list, "Party system unavailable.", true)
		return

	for pid in PartyManager.members():
		var tag := "  (leader)" if PartyManager.leader() == pid else ""
		var row := _row(_party_list, "%s%s" % [pid, tag])
		if PartyManager.is_in_party() and PartyManager.leader() != pid:
			var kick := Button.new()
			kick.text = "Remove"
			kick.pressed.connect(func(): PartyManager.remove_member(pid))
			row.add_child(kick)

	# No matchmaking yet, so invites are by name — honest about what exists.
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 8)
	var field := LineEdit.new()
	field.placeholder_text = "player name"
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(field)
	var add := Button.new()
	add.text = "Add to party"
	add.pressed.connect(func():
		var res: Dictionary = PartyManager.add_member(field.text.strip_edges())
		if not bool(res.ok) and NotificationUI:
			NotificationUI.notify_error(str(res.reason))
		field.text = "")
	add_row.add_child(add)
	_party_list.add_child(add_row)

	if PartyManager.is_in_party():
		var leave := Button.new()
		leave.text = "Leave party"
		leave.pressed.connect(func(): PartyManager.leave())
		_party_list.add_child(leave)

func _refresh_dungeons() -> void:
	var DungeonManager = AutoloadGate.get_node("DungeonManager")
	if _dungeon_list == null:
		return
	_clear(_dungeon_list)
	for d in DungeonData.all():
		var id := str(d.id)
		var rank := "Rank ?"
		var clears := 0
		if DungeonManager:
			rank = DungeonManager.rank_text(id)
			clears = DungeonManager.clear_count(id)
		var proved := ""
		if DungeonManager and DungeonManager.is_rank_confirmed(id):
			var party: Array = DungeonManager.first_clear_party(id)
			if not party.is_empty():
				proved = "   first cleared by %s" % ", ".join(party)
		_row(_dungeon_list, "%s  (%s)\n%s   depth %d   %s%s%s" % [
			str(d.name), str(d.hub).capitalize().replace("_", " "),
			rank, int(d.get("depth", 0)),
			DungeonData.requirement_text(d),
			("   %dx cleared" % clears) if clears > 0 else "",
			proved], clears == 0)

# ------------------------------------------------------------------ format

static func _currency(bag: Dictionary) -> String:
	if bag.is_empty():
		return "nothing"
	var parts := []
	for k in bag:
		parts.append("%d %s" % [int(bag[k]), k])
	return ", ".join(parts)

static func _hms(seconds: int) -> String:
	if seconds <= 0:
		return "0m"
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm" % maxi(m, 1)
