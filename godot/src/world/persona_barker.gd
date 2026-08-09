class_name PersonaBarker
extends Node3D
## Makes a world character mutter in character. Every so often it floats a
## short line from its race's mood pool (RacePersona.bark_line) above its
## anchor and, when the player is close enough to hear, speaks it in the
## race's PersonaVoice. Fidgety races (high idle_energy) bark more often;
## stoic ones rarely.
##
## Drop it under any Node3D (an NPC root, a RemotePlayer) and call setup():
##   var b := PersonaBarker.new(); anchor.add_child(b)
##   b.setup(canon_race, 2.0)   # 2.0 m label height

## How near the player must be for a bark to be voiced (metres). Text still
## floats regardless — you can read a far mutter, just not hear it.
const HEAR_RADIUS := 9.0
const BASE_INTERVAL := Vector2(7.0, 15.0)  # seconds between barks at neutral energy

## When true the barker mutters on its own timer (world NPCs). Set false for
## a player/emote barker that should only speak when told to via say()/bark().
var auto := true

var canon := ""
var _label_height := 2.0
var _voice: PersonaVoice
var _cooldown := 0.0
var _energy := 1.0
var _seed := 0

func setup(canon_name: String, label_height := 2.0) -> void:
	canon = canon_name
	_label_height = label_height
	_energy = float(RacePersona.movement(canon).get("idle_energy", 1.0))
	_seed = (canon + str(get_instance_id())).hash()
	# Reuse the voice across re-setups (profile/visual-mode changes) so we don't
	# orphan a still-processing AudioStreamPlayer each time.
	if _voice == null or not is_instance_valid(_voice):
		_voice = PersonaVoice.new()
		add_child(_voice)
	_voice.configure(RacePersona.voice(canon))
	_reset_cooldown()

func _reset_cooldown() -> void:
	# Livelier races bark more often, so divide the wait by their energy.
	var e := maxf(0.4, _energy)
	_cooldown = randf_range(BASE_INTERVAL.x, BASE_INTERVAL.y) / e

func _process(delta: float) -> void:
	if canon.is_empty() or not auto:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_reset_cooldown()
	bark()

## Force a line now (used for greetings/reactions as well as the idle timer).
func bark() -> void:
	if canon.is_empty():
		return
	_seed = _seed * 1664525 + 1013904223  # advance so each bark varies
	var line := RacePersona.bark_line(canon, _seed)
	_float_text(line)
	if _voice != null and _within_hearing():
		var chars := maxi(line.length(), 1)
		_voice.start_speaking(chars, clampf(float(chars) / 45.0, 0.25, 2.5))

## Speak an exact line right now (emotes, greetings, scripted reactions).
## Floats the text and voices it if in earshot, regardless of the idle timer.
func say(text: String) -> void:
	if text.is_empty():
		return
	_float_text(text)
	if _voice != null and _within_hearing():
		var chars := maxi(text.length(), 1)
		_voice.start_speaking(chars, clampf(float(chars) / 45.0, 0.25, 2.5))

func _within_hearing() -> bool:
	var vp := get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp != null else null
	if cam == null:
		return false
	return cam.global_position.distance_to(global_position) <= HEAR_RADIUS

## Spawn a billboarded line that drifts up and fades, then frees itself — no
## scene file needed.
func _float_text(text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.006
	lbl.modulate = Color(1, 1, 1, 0.0)
	lbl.outline_size = 6
	lbl.position = Vector3(0, _label_height, 0)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.9, 0.3)          # fade in
	tw.parallel().tween_property(lbl, "position:y", _label_height + 0.55, 2.4)  # drift up
	tw.tween_interval(0.9)                                   # hold
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)          # fade out
	tw.tween_callback(lbl.queue_free)
