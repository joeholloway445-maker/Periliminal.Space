extends Node
## KNOLL — Security Boundary Enforcer
##
## The absolute boundary enforcer and firewall for the entire Periliminal.Space
## matrix. KNOLL ensures data from the 20,480 nodes doesn't bleed across
## reality layers unauthorized, node hallucinations are locked down before
## they cascade, and the matrix doesn't collapse under infinite possibilities.
##
## Gateway Parallel: The psychological ego/safeguard that keeps the mind from
## fragmenting when navigating expanded states of consciousness.
##
## KNOLL doesn't decide what the system does. It just ensures every door
## locks behind every data flow exactly when it should.
##
## Autoloaded as "KNOLL"

signal boundary_violation(source: String, target_layer: String, reason: String)
signal data_flow_validated(source: String, target: String, allowed: bool)
signal lockdown_initiated(layer: String, reason: String)

# ─── Configuration ────────────────────────────────────────────────────────────
const VALID_LAYERS: Array = ["subliminal", "liminal", "supraliminal", "hyperliminal", "extraliminal", "periliminal"]
const VALID_PILLARS: Array = ["HOPE", "DREAM", "VISION", "APEX", "KNOLL"]
const MAX_NODE_TRAFFIC_PER_SECOND: int = 1000
const MAX_DATA_SIZE_PER_FLOW: int = 1048576  # 1MB max per data flow

# ─── State ────────────────────────────────────────────────────────────────────
var _flow_log: Array = []
var _blocked_flows: int = 0
var _allowed_flows: int = 0
var _active_lockdowns: Dictionary = {}  # layer → Dictionary{reason, started_at}
var _layer_isolation: Dictionary = {}  # layer → Array[authorized_sources]

func _ready() -> void:
	print_rich("[color=red]KNOLL[/color]: Security Boundary Enforcer initialized.")
	print_rich("  Layers Protected: %s | Pillars Monitored: %s" % [str(VALID_LAYERS.size()), str(VALID_PILLARS.size())])

	# Initialize isolation for each layer
	for layer in VALID_LAYERS:
		_layer_isolation[layer] = []

# ─── Public API ───────────────────────────────────────────────────────────────

## Validate a data flow between two points in the matrix.
## Returns true if the flow is permitted, false if it violates boundaries.
func validate_data_flow(data: Dictionary, source: String) -> bool:
	var target_layer: String = str(data.get("target_layer", ""))
	var source_layer: String = str(data.get("source_layer", ""))
	var data_size: int = JSON.stringify(data).length()
	var flow_id: String = "%s→%s" % [source, target_layer]

	# Check 1: Valid layers
	if not target_layer.is_empty() and target_layer not in VALID_LAYERS:
		_log_violation(source, target_layer, "invalid_target_layer")
		return false

	# Check 2: Data size limit
	if data_size > MAX_DATA_SIZE_PER_FLOW:
		_log_violation(source, target_layer, "data_size_exceeded: %d bytes" % data_size)
		return false

	# Check 3: Layer isolation — only specific source pillars can cross layers
	if not target_layer.is_empty() and not source_layer.is_empty():
		if source_layer != target_layer:
			# Cross-layer flow requires explicit authorization
			if not _is_cross_layer_authorized(source, source_layer, target_layer):
				_log_violation(source, target_layer, "unauthorized_cross_layer_flow: %s → %s" % [source_layer, target_layer])
				return false

	# Check 4: Active lockdown check
	if not target_layer.is_empty() and _active_lockdowns.has(target_layer):
		_log_violation(source, target_layer, "layer_under_lockdown: %s" % str(_active_lockdowns[target_layer].get("reason", "")))
		return false

	# Check 5: Source is a known pillar
	if source not in VALID_PILLARS:
		_log_violation(source, target_layer, "unknown_source_pillar")
		return false

	# Flow allowed
	_allowed_flows += 1
	_flow_log.append({
		"timestamp": Time.get_unix_time_from_system(),
		"flow_id": flow_id,
		"source": source,
		"target_layer": target_layer,
		"data_size": data_size,
		"allowed": true,
	})
	# Keep log bounded
	if _flow_log.size() > 1000:
		_flow_log.pop_front()

	data_flow_validated.emit(source, target_layer, true)
	return true

## Initiate a lockdown on a specific reality layer.
## While locked down, no data flows into or out of that layer.
func initiate_lockdown(layer: String, reason: String) -> void:
	if layer not in VALID_LAYERS:
		push_warning("KNOLL: Cannot lockdown invalid layer: %s" % layer)
		return

	_active_lockdowns[layer] = {
		"reason": reason,
		"started_at": Time.get_unix_time_from_system(),
	}
	lockdown_initiated.emit(layer, reason)
	print_rich("[color=red]KNOLL LOCKDOWN[/color]: Layer '%s' isolated. Reason: %s" % [layer, reason])

## Release a lockdown on a layer.
func release_lockdown(layer: String) -> bool:
	if not _active_lockdowns.has(layer):
		return false
	_active_lockdowns.erase(layer)
	print_rich("[color=green]KNOLL RELEASE[/color]: Layer '%s' lockdown lifted." % layer)
	return true

## Check if a layer is currently locked down.
func is_layer_locked(layer: String) -> bool:
	return _active_lockdowns.has(layer)

## Check if a node ID is within valid operating parameters.
func validate_node_heartbeat(node_id: String, pillar: String, sys_load: float) -> bool:
	if pillar not in VALID_PILLARS:
		return false
	if sys_load < 0.0 or sys_load > 1.0:
		return false
	return true

## Report a potential node hallucination or anomalous behavior.
func report_anomaly(node_id: String, anomaly_type: String, data: Dictionary) -> void:
	var APEX = AutoloadGate.get_node("APEX")
	print_rich("[color=red]KNOLL ANOMALY[/color]: [%s] %s — %s" % [node_id, anomaly_type, JSON.stringify(data)])
	# Escalate to APEX for handling
	if APEX:
		APEX.delegate("KNOLL", "handle_anomaly", APEX.Priority.HIGH, {
			"node_id": node_id,
			"anomaly_type": anomaly_type,
			"data": data,
		})

## Authorize a source to cross layers.
func authorize_cross_layer(source: String, from_layer: String, to_layer: String) -> void:
	if not _layer_isolation.has(from_layer):
		_layer_isolation[from_layer] = []
	var entry: String = "%s→%s" % [source, to_layer]
	if entry not in _layer_isolation[from_layer]:
		_layer_isolation[from_layer].append(entry)

## Get KNOLL's current security summary.
func get_matrix_summary() -> Dictionary:
	return {
		"active_lockdowns": _active_lockdowns.size(),
		"locked_layers": _active_lockdowns.keys(),
		"blocked_flows": _blocked_flows,
		"allowed_flows": _allowed_flows,
		"total_flows_logged": _flow_log.size(),
		"layers_monitored": VALID_LAYERS.size(),
		"status": "LOCKED" if _active_lockdowns.size() > 0 else "NOMINAL",
	}

func get_violation_log(count: int = 10) -> Array:
	var violations: Array = []
	for entry in _flow_log.slice(maxi(0, _flow_log.size() - count), _flow_log.size()):
		if not entry.get("allowed", true):
			violations.append(entry)
	return violations

# ─── Internal ────────────────────────────────────────────────────────────────

func _log_violation(source: String, target_layer: String, reason: String) -> void:
	_blocked_flows += 1
	_flow_log.append({
		"timestamp": Time.get_unix_time_from_system(),
		"flow_id": "%s→%s" % [source, target_layer],
		"source": source,
		"target_layer": target_layer,
		"reason": reason,
		"allowed": false,
	})
	if _flow_log.size() > 1000:
		_flow_log.pop_front()

	boundary_violation.emit(source, target_layer, reason)

func _is_cross_layer_authorized(source: String, from_layer: String, to_layer: String) -> bool:
	var isolations: Array = _layer_isolation.get(from_layer, [])
	var entry: String = "%s→%s" % [source, to_layer]
	return entry in isolations
