extends Node
## APEX — Executive Intent Orchestrator
##
## The conductor of the fractal matrix. APEX reads behavioral data from
## DREAM and VISION, determines environment responses, and delegates work
## across the 20,480-node ecosystem.
##
## Gateway Parallel: The conscious will directing energy where it needs to go
## within the holographic matrix.
##
## Autoloaded as "APEX"

signal delegation_made(task: String, target: String, priority: int)
signal environment_response(user_id: String, response_type: String, params: Dictionary)

# ─── Configuration ────────────────────────────────────────────────────────────
enum Priority {
	CRITICAL = 0,
	HIGH = 1,
	NORMAL = 2,
	LOW = 3,
	BACKGROUND = 4,
}

enum ResponseType {
	ENVIRONMENT_SHIFT,   # change the rendered environment
	NPC_BEHAVIOR,        # alter NPC routines
	ECONOMY_ADJUSTMENT,  # modify pricing/availability
	DIFFICULTY_SCALE,    # adjust challenge level
	NARRATIVE_PROMPT,    # trigger a story beat
	SECURITY_LOCKDOWN,   # KNOLL escalation
	TELEMETRY_FOCUS,     # increase tracking resolution
}

# ─── State ────────────────────────────────────────────────────────────────────
var _delegation_queue: Array = []  # pending orchestrations
var _active_delegations: Dictionary = {}  # task_id → Dictionary
var _response_history: Dictionary = {}  # user_id → Array[Dictionary]
var _system_load: float = 0.0  # 0..1 synthetic load metric

func _ready() -> void:
	print_rich("[color=green]APEX[/color]: Executive Intent Orchestrator initialized.")
	print_rich("  Priority Levels: %d | System Baseline: NOMINAL" % [Priority.size()])

func _process(_delta: float) -> void:
	# Process delegation queue
	if _delegation_queue.size() > 0:
		var task: Dictionary = _delegation_queue.pop_front()
		_execute_delegation(task)

# ─── Public API ───────────────────────────────────────────────────────────────

## Process a behavioral observation and determine the system response.
## This is the main entry point — called by Hope or VISION when new data arrives.
func process_observation(user_id: String, observation: Dictionary) -> Dictionary:
	var response: Dictionary = _determine_response(user_id, observation)

	# Log the response
	if not _response_history.has(user_id):
		_response_history[user_id] = []
	_response_history[user_id].append({
		"timestamp": Time.get_unix_time_from_system(),
		"observation": observation,
		"response": response,
	})
	# Keep history bounded
	if _response_history[user_id].size() > 100:
		_response_history[user_id].pop_front()

	# Emit if there's an environment action to take
	if response.get("action") != "none":
		environment_response.emit(user_id, str(response.get("action")), response.get("params", {}))

	return response

## Delegate a task to a subsystem.
func delegate(target: String, task: String, priority: int = Priority.NORMAL, params: Dictionary = {}) -> void:
	var task_id: String = "%s_%d_%d" % [target, Time.get_unix_time_from_system(), randi()]
	var delegation: Dictionary = {
		"task_id": task_id,
		"target": target,
		"task": task,
		"priority": priority,
		"params": params,
		"created_at": Time.get_unix_time_from_system(),
	}

	# Insert by priority
	var inserted: bool = false
	for i in range(_delegation_queue.size()):
		if _delegation_queue[i].get("priority", Priority.BACKGROUND) > priority:
			_delegation_queue.insert(i, delegation)
			inserted = true
			break
	if not inserted:
		_delegation_queue.append(delegation)

	delegation_made.emit(task, target, priority)

## Get the current system load metric.
func get_system_load() -> float:
	return _system_load

## Get the response history for a user.
func get_response_history(user_id: String) -> Array:
	return _response_history.get(user_id, [])

## Get the pending delegation queue.
func get_pending_delegations() -> Array:
	return _delegation_queue.duplicate()

## Get a summary of APEX's current state.
func get_matrix_summary() -> Dictionary:
	return {
		"system_load": _system_load,
		"pending_delegations": _delegation_queue.size(),
		"active_delegations": _active_delegations.size(),
		"users_with_history": _response_history.size(),
		"total_responses_logged": _count_total_responses(),
	}

# ─── Response Determination ──────────────────────────────────────────────────

func _determine_response(user_id: String, observation: Dictionary) -> Dictionary:
	var _action_type: String = str(observation.get("action", ""))
	var hesitation_ms: float = float(observation.get("hesitation_ms", 0.0))
	var entropy: float = float(observation.get("entropy", 0.5))
	var potential: float = float(observation.get("potential", 0.5))
	var trajectory: String = str(observation.get("trajectory", "stable"))

	# Default: no action
	var response: Dictionary = {
		"action": "none",
		"params": {},
		"reasoning": "nominal",
		"priority": Priority.NORMAL,
	}

	# High entropy + dropping potential → disengagement risk
	if entropy > 0.7 and potential < 0.3:
		response.action = "narrative_prompt"
		response.params = {"type": "re_engagement", "urgency": "high"}
		response.reasoning = "high_entropy_low_potential_disengagement_risk"
		response.priority = Priority.HIGH

	# Low entropy + high potential → locked-in flow state
	elif entropy < 0.3 and potential > 0.7:
		response.action = "difficulty_scale"
		response.params = {"direction": "increase", "amount": 0.1}
		response.reasoning = "flow_state_confidence_increase_challenge"
		response.priority = Priority.NORMAL

	# Long hesitation on critical action
	elif hesitation_ms > 5000.0:
		response.action = "narrative_prompt"
		response.params = {"type": "gentle_nudge", "context": str(observation.get("context", ""))}
		response.reasoning = "extended_hesitation_offer_assistance"
		response.priority = Priority.LOW

	# Erratic trajectory → environmental shift to re-focus
	elif trajectory == "erratic":
		response.action = "environment_shift"
		response.params = {"type": "calming", "intensity": 0.3}
		response.reasoning = "erratic_behavior_regrounding_environment"
		response.priority = Priority.NORMAL

	# Destabilizing trend → increase tracking resolution
	elif trajectory == "destabilizing":
		response.action = "telemetry_focus"
		response.params = {"resolution": "high", "target": user_id}
		response.reasoning = "destabilizing_trend_increase_observation_density"
		response.priority = Priority.HIGH

	# Locking-in trajectory → subtle variation to prevent boredom
	elif trajectory == "locking_in":
		response.action = "environment_shift"
		response.params = {"type": "subtle_variation", "intensity": 0.15}
		response.reasoning = "locking_in_pattern_prevent_complacency"
		response.priority = Priority.LOW

	# New user or first observation → onboarding response
	if _response_history.get(user_id, []).is_empty():
		response.action = "narrative_prompt"
		response.params = {"type": "onboarding", "welcome": true}
		response.reasoning = "first_observation_onboarding_sequence"
		response.priority = Priority.HIGH

	return response

# ─── Delegation Execution ────────────────────────────────────────────────────

func _execute_delegation(task: Dictionary) -> void:
	var task_id: String = str(task.get("task_id", ""))
	_active_delegations[task_id] = task

	match str(task.get("target", "")).to_upper():
		"HOPE":
			_delegate_to_hope(task)
		"DREAM":
			_delegate_to_dream(task)
		"VISION":
			_delegate_to_vision(task)
		"KNOLL":
			_delegate_to_knoll(task)
		"GODOT":
			_delegate_to_godot(task)
		_:
			push_warning("APEX: Unknown delegation target: %s" % str(task.get("target", "")))

	# Clean up after execution
	_active_delegations.erase(task_id)

func _delegate_to_hope(task: Dictionary) -> void:
	var Hope = AutoloadGate.get_node("Hope")
	var task_name: String = str(task.get("task", ""))
	var params: Dictionary = task.get("params", {})
	# HOPE receives memory storage or retrieval tasks
	if task_name == "store_observation" and Hope:
		Hope.record(str(params.get("event", "apex_delegation")), params.get("context", {}))
	elif task_name == "retrieve_profile" and Hope:
		var profile: Dictionary = Hope.combat_profile()
		print_rich("  [color=aqua]APEX → HOPE[/color]: Retrieved combat profile: %s" % JSON.stringify(profile))

func _delegate_to_dream(task: Dictionary) -> void:
	var DREAM = AutoloadGate.get_node("DREAM")
	var task_name: String = str(task.get("task", ""))
	var params: Dictionary = task.get("params", {})
	# DREAM receives analysis tasks
	if task_name == "analyze_entropy" and DREAM:
		var user_id: String = str(params.get("user_id", ""))
		if not user_id.is_empty():
			var trajectory: Dictionary = DREAM.get_trajectory(user_id)
			print_rich("  [color=aqua]APEX → DREAM[/color]: Entropy analysis for %s: %.3f" % [user_id, trajectory.get("current_entropy", 0.0)])

func _delegate_to_vision(task: Dictionary) -> void:
	var VISION = AutoloadGate.get_node("VISION")
	var task_name: String = str(task.get("task", ""))
	var params: Dictionary = task.get("params", {})
	# VISION receives observation tasks
	if task_name == "increase_resolution" and VISION:
		var user_id: String = str(params.get("user_id", ""))
		if not user_id.is_empty():
			print_rich("  [color=aqua]APEX → VISION[/color]: Increasing observation resolution for %s" % user_id)

func _delegate_to_knoll(task: Dictionary) -> void:
	var KNOLL = AutoloadGate.get_node("KNOLL")
	var task_name: String = str(task.get("task", ""))
	var params: Dictionary = task.get("params", {})
	# KNOLL receives security validation tasks
	if task_name == "validate_data" and KNOLL:
		var data: Dictionary = params.get("data", {})
		var source: String = str(params.get("source", "unknown"))
		var result: bool = KNOLL.validate_data_flow(data, source)
		if not result:
			push_warning("APEX: KNOLL rejected data flow from %s" % source)

func _delegate_to_godot(task: Dictionary) -> void:
	var task_name: String = str(task.get("task", ""))
	var params: Dictionary = task.get("params", {})
	# Godot receives environment rendering tasks
	if task_name == "environment_shift":
		print_rich("  [color=aqua]APEX → GODOT[/color]: Environment shift: %s" % JSON.stringify(params))

# ─── Utilities ───────────────────────────────────────────────────────────────

func _count_total_responses() -> int:
	var total: int = 0
	for uid in _response_history:
		total += _response_history[uid].size()
	return total
