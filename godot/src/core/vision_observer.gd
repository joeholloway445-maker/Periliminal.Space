extends Node
## VISION — Vectorized, Infrastructure Systems, Integration and Operations Network
##
## The Observer Effect. VISION watches the "hundred dots" (player potential)
## within the dynamically shifting space, monitoring how long they take to
## observe and act. This timing data feeds back into the psychological model
## and informs how the reality layer generates around them.
##
## Gateway Parallel: The Observer Effect — the universe tracks the awareness
## and hesitation of the observer, using that data to collapse probability
## waves into rendered reality.
##
## Autoloaded as "VISION"

signal dot_registered(user_id: String, dot_count: int)
signal hesitation_recorded(user_id: String, hesitation_ms: float, context: String)
signal potential_shift(user_id: String, previous_potential: float, current_potential: float)

# ─── Configuration ────────────────────────────────────────────────────────────
const MAX_DOTS_PER_USER: int = 100        # The "hundred dots" — max potential states tracked
const HESITATION_WINDOW: float = 30.0     # seconds to keep hesitation history
const POTENTIAL_DECAY_RATE: float = 0.95  # per-frame decay when inactive
const ENGAGEMENT_THRESHOLD_MS: float = 3000.0  # hesitation beyond this = disengagement signal

# ─── State ────────────────────────────────────────────────────────────────────
var _user_dots: Dictionary = {}       # user_id → Array[Dictionary] (active dots/potentials)
var _user_hesitation: Dictionary = {} # user_id → Array[Dictionary{timestamp, ms, context}]
var _user_potential: Dictionary = {}  # user_id → float (current potential score 0..1)
var _user_timing: Dictionary = {}     # user_id → Dictionary{last_action_ts, avg_reaction_ms, avg_hesitation_ms}

func _ready() -> void:
	print_rich("[color=yellow]VISION[/color]: Vectorized Infrastructure Systems & Operations Network initialized.")
	print_rich("  Max Dots: %d | Hesitation Window: %.1fs | Engagement Threshold: %.0fms" % [MAX_DOTS_PER_USER, HESITATION_WINDOW, ENGAGEMENT_THRESHOLD_MS])

func _process(delta: float) -> void:
	# Decay potential for inactive users each frame
	var now: float = Time.get_unix_time_from_system()
	for user_id in _user_dots:
		var timing: Dictionary = _user_timing.get(user_id, {})
		var last_action: float = float(timing.get("last_action_ts", 0.0))
		var idle_seconds: float = now - last_action

		# Decay potential after 10 seconds of inactivity
		if idle_seconds > 10.0 and user_id in _user_potential:
			var prev: float = _user_potential[user_id]
			var decay_factor: float = pow(POTENTIAL_DECAY_RATE, delta)
			_user_potential[user_id] = maxf(0.0, prev * decay_factor)

			if _user_potential[user_id] < 0.01 and prev >= 0.01:
				potential_shift.emit(user_id, prev, 0.0)

	# Cull expired hesitation records
	var cutoff: float = now - HESITATION_WINDOW
	for user_id in _user_hesitation:
		var h_list: Array = _user_hesitation[user_id]
		while h_list.size() > 0 and float(h_list[0].get("timestamp", 0)) < cutoff:
			h_list.pop_front()

# ─── Public API ───────────────────────────────────────────────────────────────

## Register a "dot" — a potential state for a user.
## Dots represent branching possibilities the user could explore.
func register_dot(user_id: String, dot_data: Dictionary = {}) -> int:
	if not _user_dots.has(user_id):
		_user_dots[user_id] = []
		_user_potential[user_id] = 0.5
		_user_timing[user_id] = {
			"last_action_ts": Time.get_unix_time_from_system(),
			"avg_reaction_ms": 0.0,
			"avg_hesitation_ms": 0.0,
			"total_actions": 0,
		}

	var dots: Array = _user_dots[user_id]

	# Don't exceed max dots — pop oldest if full
	if dots.size() >= MAX_DOTS_PER_USER:
		dots.pop_front()

	dots.append({
		"created_at": Time.get_unix_time_from_system(),
		"data": dot_data,
		"state": "potential",  # potential | active | collapsed
	})

	# Boost potential when new dots are registered
	if user_id in _user_potential:
		_user_potential[user_id] = minf(1.0, _user_potential[user_id] + 0.05)

	dot_registered.emit(user_id, dots.size())
	return dots.size()

## Record a hesitation event. The core metric VISION tracks.
## hesitation_ms: how long the user paused before acting
## context: what they were hesitating about (door, purchase, combat, etc.)
func record_hesitation(user_id: String, hesitation_ms: float, context: String = "") -> void:
	if not _user_hesitation.has(user_id):
		_user_hesitation[user_id] = []

	_user_hesitation[user_id].append({
		"timestamp": Time.get_unix_time_from_system(),
		"ms": hesitation_ms,
		"context": context,
	})

	# Update timing averages
	if not _user_timing.has(user_id):
		_user_timing[user_id] = {
			"last_action_ts": Time.get_unix_time_from_system(),
			"avg_reaction_ms": 0.0,
			"avg_hesitation_ms": 0.0,
			"total_actions": 0,
		}

	var timing: Dictionary = _user_timing[user_id]
	timing["last_action_ts"] = Time.get_unix_time_from_system()
	var total: int = int(timing.get("total_actions", 0)) + 1
	timing["total_actions"] = total
	timing["avg_hesitation_ms"] = ((float(timing.get("avg_hesitation_ms", 0.0)) * (total - 1)) + hesitation_ms) / float(total)

	# Adjust potential based on hesitation
	if user_id in _user_potential:
		var old_potential: float = _user_potential[user_id]
		if hesitation_ms > ENGAGEMENT_THRESHOLD_MS:
			# Long hesitation = disengagement signal → lower potential
			_user_potential[user_id] = maxf(0.0, old_potential - 0.03)
		elif hesitation_ms < 500.0:
			# Quick reaction = high engagement → raise potential
			_user_potential[user_id] = minf(1.0, old_potential + 0.02)

		if absf(_user_potential[user_id] - old_potential) > 0.01:
			potential_shift.emit(user_id, old_potential, _user_potential[user_id])

	hesitation_recorded.emit(user_id, hesitation_ms, context)

## Record a reaction time (for actions without hesitation — how fast they acted).
func record_reaction(user_id: String, reaction_ms: float, action: String = "") -> void:
	if not _user_timing.has(user_id):
		_user_timing[user_id] = {
			"last_action_ts": Time.get_unix_time_from_system(),
			"avg_reaction_ms": 0.0,
			"avg_hesitation_ms": 0.0,
			"total_actions": 0,
		}

	var timing: Dictionary = _user_timing[user_id]
	timing["last_action_ts"] = Time.get_unix_time_from_system()
	var total: int = int(timing.get("total_actions", 0)) + 1
	timing["total_actions"] = total
	timing["avg_reaction_ms"] = ((float(timing.get("avg_reaction_ms", 0.0)) * (total - 1)) + reaction_ms) / float(total)

	# Quick reactions boost potential
	if user_id in _user_potential:
		var old_potential: float = _user_potential[user_id]
		if reaction_ms < 1000.0:
			_user_potential[user_id] = minf(1.0, old_potential + 0.01)
			if absf(_user_potential[user_id] - old_potential) > 0.01:
				potential_shift.emit(user_id, old_potential, _user_potential[user_id])

## Get a user's current potential score (0..1).
## 0 = disengaged / collapsed, 1 = maximum engagement and exploration potential.
func get_potential(user_id: String) -> float:
	return _user_potential.get(user_id, 0.0)

## Get the active dot count for a user.
func get_dot_count(user_id: String) -> int:
	return _user_dots.get(user_id, []).size()

## Get hesitation statistics for a user.
func get_hesitation_stats(user_id: String) -> Dictionary:
	var h_list: Array = _user_hesitation.get(user_id, [])
	if h_list.is_empty():
		return {"average_ms": 0.0, "count": 0, "max_ms": 0.0, "min_ms": 0.0, "by_context": {}}

	var total_ms: float = 0.0
	var max_ms: float = 0.0
	var min_ms: float = INF
	var by_context: Dictionary = {}

	for entry in h_list:
		var ms: float = float(entry.get("ms", 0))
		var ctx: String = str(entry.get("context", ""))
		total_ms += ms
		max_ms = maxf(max_ms, ms)
		min_ms = minf(min_ms, ms)
		if not ctx.is_empty():
			if not by_context.has(ctx):
				by_context[ctx] = {"count": 0, "total_ms": 0.0}
			by_context[ctx]["count"] += 1
			by_context[ctx]["total_ms"] += ms

	# Normalize context averages
	for ctx in by_context:
		var c: Dictionary = by_context[ctx]
		c["avg_ms"] = c["total_ms"] / float(c["count"])

	return {
		"average_ms": total_ms / float(h_list.size()),
		"count": h_list.size(),
		"max_ms": max_ms,
		"min_ms": min_ms if min_ms != INF else 0.0,
		"by_context": by_context,
	}

## Get a user's timing profile.
func get_timing_profile(user_id: String) -> Dictionary:
	return _user_timing.get(user_id, {
		"last_action_ts": 0.0,
		"avg_reaction_ms": 0.0,
		"avg_hesitation_ms": 0.0,
		"total_actions": 0,
	})

## Get a full observation summary for a user.
func get_observation_summary(user_id: String) -> Dictionary:
	return {
		"user_id": user_id,
		"dots": get_dot_count(user_id),
		"potential": get_potential(user_id),
		"hesitation": get_hesitation_stats(user_id),
		"timing": get_timing_profile(user_id),
	}

## Get the global observation matrix summary.
func get_matrix_summary() -> Dictionary:
	var summary: Dictionary = {
		"total_users_tracked": _user_dots.size(),
		"total_dots": 0,
		"average_potential": 0.0,
		"total_hesitations": 0,
		"average_hesitation_ms": 0.0,
		"users": {},
	}
	var potential_sum: float = 0.0
	var hesitation_total: float = 0.0
	var hesitation_count: int = 0

	for uid in _user_dots:
		summary.total_dots += _user_dots[uid].size()
		var pot: float = get_potential(uid)
		potential_sum += pot
		var h_stats: Dictionary = get_hesitation_stats(uid)
		hesitation_total += h_stats.get("average_ms", 0.0) * float(h_stats.get("count", 0))
		hesitation_count += h_stats.get("count", 0)
		summary.users[uid] = {
			"dots": _user_dots[uid].size(),
			"potential": pot,
			"hesitation_avg_ms": h_stats.get("average_ms", 0.0),
			"hesitation_count": h_stats.get("count", 0),
		}

	if summary.total_users_tracked > 0:
		summary.average_potential = potential_sum / summary.total_users_tracked
	if hesitation_count > 0:
		summary.average_hesitation_ms = hesitation_total / hesitation_count

	return summary

## Collapse all dots for a user (e.g., they left the layer or made a decisive choice).
func collapse_dots(user_id: String) -> int:
	var count: int = _user_dots.get(user_id, []).size()
	_user_dots[user_id] = []
	if user_id in _user_potential:
		var prev: float = _user_potential[user_id]
		_user_potential[user_id] = 0.0
		potential_shift.emit(user_id, prev, 0.0)
	return count
