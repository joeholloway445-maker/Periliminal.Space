extends Node

# ── Signals ────────────────────────────────────────────────────────────────────
signal state_changed(old_state: GameState, new_state: GameState)
signal initialization_complete()
signal critical_error(message: String)

# ── Enums ──────────────────────────────────────────────────────────────────────
enum GameState {
	LOADING,
	LOGIN,
	WORLD,
	GAME,
	SOCIAL,
	SETTINGS,
}

# ── State ──────────────────────────────────────────────────────────────────────
var game_state: GameState   = GameState.LOADING
var _init_complete: bool    = false
var _init_errors: Array[String] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Deferred: GameManager is autoload #4, but AccountManager/DistrictManager
	# init LATER in the [autoload] list — at this exact moment they're still
	# null, so connecting here silently no-ops (the old `if AccountManager:`
	# guard "passed" by skipping the connection entirely). One deferred hop
	# lands after every autoload's _ready has run.
	_connect_manager_signals.call_deferred()

func _connect_manager_signals() -> void:
	# Ensure all 1920×1080 content is always fully visible — `expand` crops
	# the bottom on screens narrower than 16:9 (common on laptops).
	var AccountManager = AutoloadGate.get_node("AccountManager")
	var DistrictManager = AutoloadGate.get_node("DistrictManager")
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if AccountManager:
		AccountManager.authenticated.connect(_on_authenticated)
		AccountManager.session_expired.connect(_on_session_expired)
	if DistrictManager:
		DistrictManager.district_loaded.connect(_on_district_loaded)

func _process(_delta: float) -> void:
	pass

# ── Initialization ─────────────────────────────────────────────────────────────
func initialize() -> void:
	_set_state(GameState.LOADING)
	var steps := [
		_init_account_manager,
		_init_economy_manager,
		_init_companion_system,
		_init_game_factory,
		_init_district_manager,
		_init_liveops_manager,
		_init_social_manager,
	]
	for step in steps:
		await step.call()
		await get_tree().process_frame

	if _init_errors.is_empty():
		_init_complete = true
		emit_signal("initialization_complete")
		_set_state(GameState.LOGIN)
	else:
		push_error("GameManager: initialization errors: %s" % str(_init_errors))
		emit_signal("critical_error", "\n".join(_init_errors))

# ── State Machine ──────────────────────────────────────────────────────────────
func set_state(new_state: GameState) -> void:
	_set_state(new_state)

func is_in_state(state: GameState) -> bool:
	return game_state == state

func enter_game(game_type: int, variant_id: int, scene_path: String = "") -> void:
	var GameFactory = AutoloadGate.get_node("GameFactory")
	_set_state(GameState.GAME)
	# Prefer a real packed scene (lobby catalog) over a blank factory stub.
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
		return
	if GameFactory and GameFactory.has_method("create_game_from_catalog"):
		var catalog_node = GameFactory.create_game_from_catalog(game_type, variant_id)
		if catalog_node:
			if get_tree().current_scene:
				get_tree().current_scene.add_child(catalog_node)
			return
	if GameFactory:
		var game_node = GameFactory.create_game(game_type, variant_id)
		if game_node and get_tree().current_scene:
			get_tree().current_scene.add_child(game_node)

func exit_game() -> void:
	_set_state(GameState.WORLD)

func open_social() -> void:
	_set_state(GameState.SOCIAL)

func close_social() -> void:
	_set_state(GameState.WORLD)

# ── Init Steps ─────────────────────────────────────────────────────────────────
func _init_account_manager() -> void:
	var AccountManager = AutoloadGate.get_node("AccountManager")
	if not AccountManager:
		_init_errors.append("AccountManager not found")
		return
	await AccountManager.initialize()

func _init_economy_manager() -> void:
	# Offline/guest boot must still arm EconomyManager so spend/earn works
	# before (or without) Nakama auth. initialize(null) keeps local cache.
	var EconomyManager = AutoloadGate.get_node("EconomyManager")
	var AccountManager = AutoloadGate.get_node("AccountManager")
	if not EconomyManager:
		_init_errors.append("EconomyManager not found")
		return
	var client = AccountManager.get_nakama_client() if AccountManager else null
	EconomyManager.initialize(client)

func _init_companion_system() -> void:
	var CompanionSystem = AutoloadGate.get_node("CompanionSystem")
	if not CompanionSystem:
		return
	await CompanionSystem.initialize()

func _init_game_factory() -> void:
	var GameFactory = AutoloadGate.get_node("GameFactory")
	if not GameFactory:
		return
	await GameFactory.initialize()

func _init_district_manager() -> void:
	var DistrictManager = AutoloadGate.get_node("DistrictManager")
	if not DistrictManager:
		return
	await DistrictManager.initialize()

func _init_liveops_manager() -> void:
	var LiveOpsManager = AutoloadGate.get_node("LiveOpsManager")
	if not LiveOpsManager:
		return
	await LiveOpsManager.initialize()

func _init_social_manager() -> void:
	var SocialManager = AutoloadGate.get_node("SocialManager")
	if not SocialManager:
		return
	await SocialManager.initialize()

# ── Handlers ──────────────────────────────────────────────────────────────────
func _on_authenticated(_session: Dictionary) -> void:
	# LOGIN is the normal post-init state. LOADING covers restored sessions
	# that authenticate while initialize() is still running (or splash is up).
	if game_state == GameState.LOGIN or game_state == GameState.LOADING:
		_set_state(GameState.WORLD)
		# The front door is the phone-style title screen (home) — the player
		# chooses Start New Venture, Continue Expedition, or browses the apps.
		# Character creation is a CHOICE from there, never an auto-entry.
		get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")

func _on_session_expired() -> void:
	_set_state(GameState.LOGIN)

func _on_district_loaded(_district: int) -> void:
	if game_state == GameState.LOADING:
		_set_state(GameState.WORLD)

# ── Private ────────────────────────────────────────────────────────────────────
func _set_state(new_state: GameState) -> void:
	if new_state == game_state:
		return
	var old := game_state
	game_state = new_state
	emit_signal("state_changed", old, new_state)
