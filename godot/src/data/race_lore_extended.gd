class_name RaceLoreExtended
# Extended lore, abilities, and race-specific game bonuses for all 20
# canonical Periliminal.Space races (Lumenari through Starfall).
# Keys match RaceLore.get_all_race_names().
# Values derived from hdv_lore src/data/race_data.gd stat_bonus, passive,
# and drawback fields — mapped to the gameplay bonus system (slot_mult,
# race_spd_bonus, combat_crit, signature move).

const RACE_GAME_BONUSES: Dictionary = {
	"Lumenari": {
		slot_mult=1.20, race_spd_bonus=2, combat_crit=0.09,
		signature_move="Radiant Pulse", signature_desc="Deals AoE light damage when Focus is at maximum",
		hometown_district="neon_alley", unlock_cost_coins=1000,
	},
	"Gutterkin": {
		slot_mult=1.10, race_spd_bonus=8, combat_crit=0.11,
		signature_move="Hazard Conversion", signature_desc="Restores HP when standing in hazard zones",
		hometown_district="paw_vegas", unlock_cost_coins=500,
	},
	"Deepborne": {
		slot_mult=1.05, race_spd_bonus=2, combat_crit=0.08,
		signature_move="Pressure Pulse", signature_desc="Knocks back attackers when struck; 3s cooldown",
		hometown_district="neon_alley", unlock_cost_coins=750,
	},
	"Ashen Choir": {
		slot_mult=1.25, race_spd_bonus=0, combat_crit=0.07,
		signature_move="Sorrow Amplification", signature_desc="Boosts ally damage by 15% while they remain above 50% HP",
		hometown_district="neon_alley", unlock_cost_coins=1250,
	},
	"Veilstriders": {
		slot_mult=1.15, race_spd_bonus=12, combat_crit=0.12,
		signature_move="Phase Skip", signature_desc="5% chance to ignore any incoming hit entirely",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Chronarchs": {
		slot_mult=1.15, race_spd_bonus=4, combat_crit=0.10,
		signature_move="Micro-Rewind", signature_desc="Automatically corrects missed skill shots once per fight",
		hometown_district="cat_forest", unlock_cost_coins=1250,
	},
	"Nullborn": {
		slot_mult=1.30, race_spd_bonus=5, combat_crit=0.13,
		signature_move="Outcome Shift", signature_desc="Subtly skews all RNG in your favor; small but cumulative",
		hometown_district="neon_alley", unlock_cost_coins=1500,
	},
	"Thorned": {
		slot_mult=1.0, race_spd_bonus=6, combat_crit=0.09,
		signature_move="Regrowth Armor", signature_desc="Regenerates 3 HP per second in combat; heals 2x on kill",
		hometown_district="cat_forest", unlock_cost_coins=750,
	},
	"Echoes": {
		slot_mult=1.10, race_spd_bonus=3, combat_crit=0.14,
		signature_move="System Hack", signature_desc="Passively jams enemy abilities within 8m; 20% chance to misfire",
		hometown_district="cat_forest", unlock_cost_coins=1000,
	},
	"Hollowed": {
		slot_mult=1.20, race_spd_bonus=0, combat_crit=0.06,
		signature_move="Extra Item Slot", signature_desc="Carries one additional consumable without counting toward cap",
		hometown_district="neon_alley", unlock_cost_coins=500,
	},
	"Riftspawn": {
		slot_mult=1.05, race_spd_bonus=10, combat_crit=0.11,
		signature_move="Minor Gravity Pull", signature_desc="Pulls nearby targets 1m toward you every 4s; interrupts channeling",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Mirekin": {
		slot_mult=1.05, race_spd_bonus=3, combat_crit=0.08,
		signature_move="Hive Awareness", signature_desc="Reveals all allies within 50m through terrain, even stealthed",
		hometown_district="cat_forest", unlock_cost_coins=750,
	},
	"Sunspun": {
		slot_mult=1.10, race_spd_bonus=9, combat_crit=0.10,
		signature_move="Radiant Burst", signature_desc="Unleashes stored light: deals bonus damage scaling with Focus level",
		hometown_district="paw_vegas", unlock_cost_coins=1000,
	},
	"Coldmarrow": {
		slot_mult=1.0, race_spd_bonus=0, combat_crit=0.07,
		signature_move="Freeze Aura", signature_desc="Slows all enemies within 5m by 20%; stacks on prolonged contact",
		hometown_district="cat_forest", unlock_cost_coins=750,
	},
	"Pulseborn": {
		slot_mult=1.10, race_spd_bonus=14, combat_crit=0.12,
		signature_move="Shock Dash", signature_desc="Dashing leaves an electrical AoE that damages pursuers",
		hometown_district="cat_forest", unlock_cost_coins=1000,
	},
	"Dreamflesh": {
		slot_mult=1.25, race_spd_bonus=6, combat_crit=0.09,
		signature_move="Minor Morph Shift", signature_desc="Briefly change hitbox shape; 15% chance to cause attacks to miss",
		hometown_district="neon_alley", unlock_cost_coins=1250,
	},
	"Crownless": {
		slot_mult=1.15, race_spd_bonus=3, combat_crit=0.10,
		signature_move="Authority Override", signature_desc="Take temporary control of hostile turrets/doors for 4 seconds",
		hometown_district="paw_vegas", unlock_cost_coins=1500,
	},
	"Rotweavers": {
		slot_mult=1.20, race_spd_bonus=2, combat_crit=0.08,
		signature_move="Decay Conversion", signature_desc="Killed enemies drop 1 extra loot stack; value scales with kill streak",
		hometown_district="cat_forest", unlock_cost_coins=500,
	},
	"Glassborn": {
		slot_mult=1.15, race_spd_bonus=0, combat_crit=0.07,
		signature_move="Mirror Shield", signature_desc="Reflects 15% of incoming damage back at the attacker",
		hometown_district="neon_alley", unlock_cost_coins=1250,
	},
	"Starfall": {
		slot_mult=1.0, race_spd_bonus=15, combat_crit=0.13,
		signature_move="Impact Entry", signature_desc="Falling from any height creates a damaging AoE at landing point; no fall damage",
		hometown_district="paw_vegas", unlock_cost_coins=1500,
	},
}

static func get_game_bonus(race_name: String) -> Dictionary:
	return RACE_GAME_BONUSES.get(race_name, {})

static func get_signature_move(race_name: String) -> Dictionary:
	var bonus = get_game_bonus(race_name)
	if bonus.is_empty(): return {}
	return {
		"name": bonus.get("signature_move", ""),
		"desc": bonus.get("signature_desc", ""),
	}

static func get_best_races_for(game_type: String) -> Array[String]:
	var ranked: Array[Dictionary] = []
	for race_name in RACE_GAME_BONUSES.keys():
		var b = RACE_GAME_BONUSES[race_name]
		var score := 0.0
		match game_type:
			"slots": score = b.get("slot_mult", 1.0)
			"racing": score = float(b.get("race_spd_bonus", 0))
			"combat": score = b.get("combat_crit", 0.0)
		ranked.append({"race": race_name, "score": score})
	ranked.sort_custom(func(a, b): return a.score > b.score)
	return ranked.map(func(r): return r["race"]) as Array[String]
