extends Node
## DREAM Engine — Deterministic Reasoning and Ephemeral Analysis Matrix
##
## The quantum subconscious of Periliminal.Space. DREAM processes the
## ephemeral probabilities, Shannon entropy calculations, and Hidden Markov
## Model state transitions beneath the surface — before anything materializes
## in the active game world.
##
## Gateway Parallel: Focus 15 — the state of no-time where logic, probabilities,
## and patterns are formed before projecting into reality.
##
## Autoloaded as "DREAM"

signal trajectory_updated(user_id: String, entropy: float, predicted_state: String)
signal drift_detected(user_id: String, drift_vector: Dictionary)

# ─── Configuration ────────────────────────────────────────────────────────────
const ENTROPY_WINDOW_SIZE: int = 12       # sliding window for entropy calc
const HMM_STATE_COUNT: int = 5             # hidden psychological states
const DRIFT_THRESHOLD: float = 0.15        # Δ entropy that triggers a drift event

# ─── State ────────────────────────────────────────────────────────────────────
var _action_logs: Dictionary = {}  # user_id → Array[Dictionary{action, timestamp, hesitation_ms, amount}]
var _entropy_cache: Dictionary = {}  # user_id → float (current entropy)
var _hmm_state_cache: Dictionary = {}  # user_id → Dictionary{state_probs: Array, last_prediction: String}
var _user_trajectories: Dictionary = {}  # user_id → Dictionary{trend: String, confidence: float}

func _ready() -> void:
	print_rich("[color=aqua]DREAM[/color]: Deterministic Reasoning & Ephemeral Analysis Matrix initialized.")
	print_rich("  States: %d | Entropy Window: %d | Drift Threshold: %.2f" % [HMM_STATE_COUNT, ENTROPY_WINDOW_SIZE, DRIFT_THRESHOLD])

# ─── Public API ───────────────────────────────────────────────────────────────

## Ingest a behavioral observation. Called by Hope, VISION, or direct telemetry.
## Returns the updated trajectory prediction for this user.
func observe(user_id: String, action: String, hesitation_ms: float = 0.0, amount: float = 0.0) -> Dictionary:
	if not _action_logs.has(user_id):
		_action_logs[user_id] = []
		_entropy_cache[user_id] = 0.5
		_hmm_state_cache[user_id] = _default_hmm_state()
		_user_trajectories[user_id] = _default_trajectory()

	var action_log: Array = _action_logs[user_id]
	action_log.append({
		"action": action,
		"hesitation_ms": hesitation_ms,
		"amount": amount,
		"timestamp": Time.get_unix_time_from_system(),
	})

	# Keep sliding window bounded
	while action_log.size() > ENTROPY_WINDOW_SIZE * 2:
		action_log.pop_front()

	# Recalculate
	var entropy: float = _calculate_shannon_entropy(user_id)
	var hmm_state: Dictionary = _update_hmm_state(user_id, action)
	var trajectory: Dictionary = _update_trajectory(user_id, entropy, hmm_state)

	_entropy_cache[user_id] = entropy
	_hmm_state_cache[user_id] = hmm_state

	# Detect drift
	var drift: Dictionary = _check_drift(user_id, trajectory)
	if not drift.is_empty():
		drift_detected.emit(user_id, drift)

	trajectory_updated.emit(user_id, entropy, trajectory.get("predicted_state", "unknown"))

	return trajectory

## Get the current Shannon entropy for a user (0.0 = completely predictable,
## 1.0 = maximum uncertainty).
func get_entropy(user_id: String) -> float:
	return _entropy_cache.get(user_id, 0.5)

## Get the current HMM state probabilities for a user.
func get_hmm_state(user_id: String) -> Dictionary:
	return _hmm_state_cache.get(user_id, _default_hmm_state())

## Get the full trajectory prediction for a user.
func get_trajectory(user_id: String) -> Dictionary:
	return _user_trajectories.get(user_id, _default_trajectory())

## Get a summary of all tracked users and their states.
func get_matrix_summary() -> Dictionary:
	var summary: Dictionary = {
		"total_tracked": _action_logs.size(),
		"total_actions": 0,
		"average_entropy": 0.0,
		"states": {},
		"users": {},
	}
	var entropy_sum: float = 0.0
	for uid in _action_logs:
		var action_log: Array = _action_logs[uid]
		summary.total_actions += action_log.size()
		var ent: float = get_entropy(uid)
		entropy_sum += ent
		var traj: Dictionary = get_trajectory(uid)
		summary.users[uid] = {
			"entropy": ent,
			"actions_logged": action_log.size(),
			"trend": traj.get("trend", "stable"),
			"predicted_state": traj.get("predicted_state", "unknown"),
			"confidence": traj.get("confidence", 0.0),
		}
		var trend: String = traj.get("trend", "stable")
		summary.states[trend] = summary.states.get(trend, 0) + 1

	if summary.total_tracked > 0:
		summary.average_entropy = entropy_sum / summary.total_tracked

	return summary

# ─── Shannon Entropy Calculation ─────────────────────────────────────────────

func _calculate_shannon_entropy(user_id: String) -> float:
	var action_log: Array = _action_logs.get(user_id, [])
	if action_log.is_empty():
		return 0.5

	# Take only the most recent ENTROPY_WINDOW_SIZE actions
	var window: Array = action_log.slice(maxi(0, action_log.size() - ENTROPY_WINDOW_SIZE), action_log.size())
	if window.is_empty():
		return 0.5

	# Count action type frequencies
	var freq: Dictionary = {}
	var total: int = 0
	for entry in window:
		var action_type: String = _classify_action(entry)
		freq[action_type] = freq.get(action_type, 0) + 1
		total += 1

	# Calculate H(X) = -Σ P(xᵢ) log₂ P(xᵢ)
	var entropy: float = 0.0
	for action_type in freq:
		var p: float = float(freq[action_type]) / float(total)
		if p > 0.0:
			entropy -= p * log(p) / log(2.0)  # log₂(p)

	# Normalize to 0..1 range
	# Max entropy for N categories = log₂(N)
	var num_categories: int = freq.size()
	if num_categories > 1:
		var max_entropy: float = log(float(num_categories)) / log(2.0)
		entropy = entropy / max_entropy
	else:
		entropy = 0.0  # Only one action type = completely predictable

	return clampf(entropy, 0.0, 1.0)

# ─── Hidden Markov Model (Simplified Forward Algorithm) ─────────────────────

func _default_hmm_state() -> Dictionary:
	return {
		"state_probs": [0.2, 0.2, 0.2, 0.2, 0.2],  # 5 hidden states
		"last_prediction": "stable",
		"transition_history": [],
	}

## Simplified HMM — tracks hidden psychological states based on observable actions.
## Hidden states: 0=exploratory, 1=conservative, 2=impulsive, 3=fatigued, 4=engaged
func _update_hmm_state(user_id: String, action: String) -> Dictionary:
	var state: Dictionary = _hmm_state_cache.get(user_id, _default_hmm_state())
	var probs: Array = state.state_probs.duplicate()

	# Transition matrix: probability of moving from state i to state j
	# Simplified — in production this would be learned from data
	var transition_matrix: Array = [
		[0.4, 0.2, 0.2, 0.1, 0.1],  # from exploratory
		[0.2, 0.5, 0.1, 0.1, 0.1],  # from conservative
		[0.3, 0.1, 0.4, 0.1, 0.1],  # from impulsive
		[0.1, 0.2, 0.1, 0.5, 0.1],  # from fatigued
		[0.2, 0.1, 0.2, 0.1, 0.4],  # from engaged
	]

	# Emission probabilities: given hidden state, what's the likelihood of this action?
	var emission_probs: Array = _get_emission_probs(action)

	# Forward algorithm step: αₜ(j) = Σᵢ αₜ₋₁(i) · aᵢⱼ · bⱼ(oₜ)
	var new_probs: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
	for j in range(HMM_STATE_COUNT):
		var sum: float = 0.0
		for i in range(HMM_STATE_COUNT):
			sum += probs[i] * transition_matrix[i][j]
		new_probs[j] = sum * emission_probs[j]

	# Normalize
	var total: float = 0.0
	for p in new_probs:
		total += p
	if total > 0.0:
		for j in range(HMM_STATE_COUNT):
			new_probs[j] = new_probs[j] / total

	# Determine most likely state and prediction label
	var best_idx: int = 0
	var best_prob: float = 0.0
	for j in range(HMM_STATE_COUNT):
		if new_probs[j] > best_prob:
			best_prob = new_probs[j]
			best_idx = j

	var state_labels: Array = ["exploring", "conserving", "impulsing", "fatiguing", "engaging"]
	var prediction: String = str(state_labels[best_idx])

	# Track transition history
	var history: Array = state.get("transition_history", [])
	history.append({
		"from": state.get("last_prediction", "unknown"),
		"to": prediction,
		"confidence": best_prob,
		"timestamp": Time.get_unix_time_from_system(),
	})
	if history.size() > 20:
		history.pop_front()

	return {
		"state_probs": new_probs,
		"last_prediction": prediction,
		"confidence": best_prob,
		"transition_history": history,
	}

## Emission probabilities for common action types.
## Maps observable actions to hidden state likelihoods.
func _get_emission_probs(action: String) -> Array:
	var action_lower: String = action.to_lower()

	# Default: uniform emission
	var default_emit: Array = [0.2, 0.2, 0.2, 0.2, 0.2]

	# Action-to-state mapping heuristics
	var action_map: Dictionary = {
		"purchase":        [0.3, 0.4, 0.1, 0.1, 0.1],  # likely conservative or exploratory
		"premium_purchase": [0.1, 0.1, 0.5, 0.1, 0.2],  # likely impulsive
		"explore":         [0.6, 0.1, 0.1, 0.1, 0.1],  # likely exploratory
		"combat":          [0.2, 0.1, 0.3, 0.1, 0.3],  # split impulsive/engaged
		"retreat":         [0.1, 0.5, 0.1, 0.2, 0.1],  # likely conservative or fatigued
		"idle":            [0.1, 0.2, 0.1, 0.5, 0.1],  # likely fatigued
		"hesitate":        [0.1, 0.5, 0.1, 0.3, 0.0],  # likely conservative or fatigued
		"socialize":       [0.3, 0.1, 0.1, 0.1, 0.4],  # exploratory or engaged
		"collect":         [0.4, 0.3, 0.1, 0.1, 0.1],  # exploratory or conservative
		"skip":            [0.1, 0.1, 0.3, 0.4, 0.1],  # impulsive or fatigued
		"repeat_action":   [0.1, 0.6, 0.1, 0.1, 0.1],  # strongly conservative
		"novel_action":    [0.6, 0.1, 0.2, 0.0, 0.1],  # strongly exploratory
	}

	return action_map.get(action_lower, default_emit)

# ─── Trajectory Prediction ───────────────────────────────────────────────────

func _default_trajectory() -> Dictionary:
	return {
		"trend": "stable",
		"predicted_state": "unknown",
		"confidence": 0.0,
		"entropy_trend": "flat",
		"volatility": 0.0,
	}

func _update_trajectory(user_id: String, current_entropy: float, hmm_state: Dictionary) -> Dictionary:
	var action_log: Array = _action_logs.get(user_id, [])
	var prev_entropy: float = _entropy_cache.get(user_id, 0.5)

	# Determine entropy trend
	var entropy_trend: String = "flat"
	var delta: float = current_entropy - prev_entropy
	if delta > 0.05:
		entropy_trend = "rising"    # becoming more unpredictable
	elif delta < -0.05:
		entropy_trend = "falling"   # becoming more predictable

	# Calculate volatility: standard deviation of recent entropy changes
	var volatility: float = _calc_volatility(user_id, current_entropy)

	# Overall trend from trajectory
	var trend: String = "stable"
	if current_entropy > 0.7 and entropy_trend == "rising":
		trend = "destabilizing"
	elif current_entropy < 0.3 and entropy_trend == "falling":
		trend = "locking_in"
	elif volatility > 0.3:
		trend = "erratic"

	# Predicted next state from HMM
	var predicted: String = str(hmm_state.get("last_prediction", "unknown"))
	var confidence: float = float(hmm_state.get("confidence", 0.0))

	return {
		"trend": trend,
		"predicted_state": predicted,
		"confidence": confidence,
		"entropy_trend": entropy_trend,
		"volatility": volatility,
		"current_entropy": current_entropy,
		"total_actions_logged": action_log.size(),
	}

# ─── Drift Detection ─────────────────────────────────────────────────────────

func _check_drift(user_id: String, trajectory: Dictionary) -> Dictionary:
	var prev: Dictionary = _user_trajectories.get(user_id, _default_trajectory())

	var drift: Dictionary = {}

	# Check entropy drift
	var prev_entropy: float = _entropy_cache.get(user_id, 0.5)
	var current_entropy: float = trajectory.get("current_entropy", prev_entropy)
	var entropy_delta: float = absf(current_entropy - prev_entropy)

	if entropy_delta > DRIFT_THRESHOLD:
		drift["entropy_shift"] = {
			"from": prev_entropy,
			"to": current_entropy,
			"delta": entropy_delta,
			"direction": "up" if current_entropy > prev_entropy else "down",
		}

	# Check state transition drift
	var prev_state: String = prev.get("predicted_state", "unknown")
	var current_state: String = trajectory.get("predicted_state", "unknown")
	if prev_state != current_state and prev_state != "unknown":
		drift["state_transition"] = {
			"from": prev_state,
			"to": current_state,
		}

	# Check volatility breach
	var volatility: float = trajectory.get("volatility", 0.0)
	if volatility > 0.4:
		drift["volatility_breach"] = {
			"volatility": volatility,
			"threshold": 0.4,
		}

	return drift

# ─── Volatility Calculation ──────────────────────────────────────────────────

func _calc_volatility(user_id: String, _current_entropy: float) -> float:
	var action_log: Array = _action_logs.get(user_id, [])
	if action_log.size() < 3:
		return 0.0

	# Use last N/2 entropy values approximated from action diversity
	var window_size: int = mini(6, action_log.size() / 2)
	var window: Array = action_log.slice(action_log.size() - window_size, action_log.size())
	if window.is_empty():
		return 0.0

	# Count action types in each half of the window to estimate variance
	var first_half: Array = window.slice(0, window_size / 2)
	var second_half: Array = window.slice(window_size / 2, window_size)

	var first_types: Dictionary = {}
	var second_types: Dictionary = {}

	for entry in first_half:
		var t: String = _classify_action(entry)
		first_types[t] = first_types.get(t, 0) + 1
	for entry in second_half:
		var t: String = _classify_action(entry)
		second_types[t] = second_types.get(t, 0) + 1

	# Jaccard dissimilarity between the two halves
	var union: Dictionary = {}
	for k in first_types:
		union[k] = true
	for k in second_types:
		union[k] = true
	var intersection_count: int = 0
	for k in first_types:
		if second_types.has(k):
			intersection_count += 1

	var union_count: int = union.size()
	var jaccard: float = float(intersection_count) / float(maxi(union_count, 1))
	var volatility: float = 1.0 - jaccard  # 0 = same patterns, 1 = completely different

	return volatility

# ─── Action Classification ───────────────────────────────────────────────────

func _classify_action(entry: Dictionary) -> String:
	var action: String = str(entry.get("action", "unknown")).to_lower()
	var hesitation: float = float(entry.get("hesitation_ms", 0.0))
	var amount: float = float(entry.get("amount", 0.0))

	# Classify by heuristics
	if hesitation > 5000.0:
		return "hesitate"
	if action.contains("purchase") or action.contains("buy"):
		if amount > 50.0:
			return "premium_purchase"
		return "purchase"
	if action.contains("fight") or action.contains("attack") or action.contains("combat"):
		return "combat"
	if action.contains("move") or action.contains("explore") or action.contains("enter"):
		return "explore"
	if action.contains("collect") or action.contains("loot") or action.contains("pickup"):
		return "collect"
	if action.contains("talk") or action.contains("chat") or action.contains("group"):
		return "socialize"
	if action.contains("flee") or action.contains("run") or action.contains("exit"):
		return "retreat"
	if action.contains("wait") or action.contains("idle") or action.contains("afk"):
		return "idle"
	if action.contains("skip") or action.contains("pass"):
		return "skip"

	return action
