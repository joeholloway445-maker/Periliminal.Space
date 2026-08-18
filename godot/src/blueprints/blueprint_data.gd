class_name BlueprintData
## The blueprint schema: EVERYTHING equipable, castable, or summonable in
## Periliminal.Space is a blueprint — a bag of named parameters a player can
## reshape in the Blueprint Forge. Weapons, armor, skills, and entities all
## share one format so forking/sharing/trading works uniformly.
##
## A blueprint = { id, kind, name, base_id, params:{}, audio:{}, author,
##                 version, locked:[] }. `params` drive geometry + material,
## `audio` drives the synthesized sound signature (where applicable).
## `locked` lists params the base refuses to expose (balance-critical stats
## are NEVER in blueprints — blueprints are FORM, ItemData/SkillData are
## FUNCTION).

const KINDS := ["weapon", "armor", "skill", "entity"]

## Parameter definitions per kind. Each def:
##   {key, label, type:"float"/"color"/"choice", min, max, def, choices}
## The editor renders these generically; the builders consume them.
const PARAM_DEFS := {
	"weapon": [
		{key="silhouette", label="Silhouette", type="choice", def="blade",
			choices=["blade", "hammer", "staff", "claw", "lash", "orbitals"]},
		{key="length", label="Length", type="float", min=0.4, max=2.2, def=1.0},
		{key="width", label="Width", type="float", min=0.05, max=0.6, def=0.15},
		{key="curve", label="Curve", type="float", min=-0.6, max=0.6, def=0.0},
		{key="taper", label="Taper", type="float", min=0.0, max=1.0, def=0.6},
		{key="segments", label="Segments", type="float", min=1.0, max=8.0, def=1.0},
		{key="base_color", label="Base Color", type="color", def=Color(0.75, 0.78, 0.85)},
		{key="edge_color", label="Edge Glow", type="color", def=Color(0.4, 0.8, 1.0)},
		{key="metallic", label="Metallic", type="float", min=0.0, max=1.0, def=0.9},
		{key="roughness", label="Roughness", type="float", min=0.0, max=1.0, def=0.25},
		{key="emission", label="Emission", type="float", min=0.0, max=4.0, def=0.8},
		{key="trail", label="Swing Trail", type="float", min=0.0, max=1.0, def=0.5},
	],
	"armor": [
		{key="silhouette", label="Silhouette", type="choice", def="plate",
			choices=["plate", "scale", "weave", "shell", "aura", "bone"]},
		{key="coverage", label="Coverage", type="float", min=0.2, max=1.0, def=0.7},
		{key="bulk", label="Bulk", type="float", min=0.0, max=1.0, def=0.4},
		{key="spikes", label="Spikes", type="float", min=0.0, max=1.0, def=0.0},
		{key="base_color", label="Base Color", type="color", def=Color(0.35, 0.37, 0.45)},
		{key="accent_color", label="Accent", type="color", def=Color(0.9, 0.7, 0.3)},
		{key="metallic", label="Metallic", type="float", min=0.0, max=1.0, def=0.7},
		{key="roughness", label="Roughness", type="float", min=0.0, max=1.0, def=0.5},
		{key="emission", label="Rune Glow", type="float", min=0.0, max=3.0, def=0.2},
		{key="wear", label="Battle Wear", type="float", min=0.0, max=1.0, def=0.3},
	],
	"skill": [
		{key="shape_style", label="Cast Shape", type="choice", def="ring",
			choices=["ring", "burst", "spiral", "shards", "wave", "sigil"]},
		{key="primary_color", label="Primary Color", type="color", def=Color(0.5, 0.8, 1.0)},
		{key="secondary_color", label="Secondary", type="color", def=Color(1.0, 1.0, 1.0)},
		{key="particle_density", label="Particle Density", type="float", min=0.2, max=3.0, def=1.0},
		{key="scale", label="Visual Scale", type="float", min=0.5, max=2.0, def=1.0},
		{key="turbulence", label="Turbulence", type="float", min=0.0, max=1.0, def=0.3},
		{key="afterglow", label="Afterglow", type="float", min=0.0, max=2.0, def=0.6},
	],
	"entity": [
		{key="body", label="Body Plan", type="choice", def="quadruped",
			choices=["quadruped", "serpent", "avian", "floating", "biped", "swarm"]},
		{key="size", label="Size", type="float", min=0.4, max=2.5, def=1.0},
		{key="limb_length", label="Limb Length", type="float", min=0.5, max=1.8, def=1.0},
		{key="head_scale", label="Head Scale", type="float", min=0.6, max=1.6, def=1.0},
		{key="base_color", label="Hide Color", type="color", def=Color(0.5, 0.4, 0.35)},
		{key="marking_color", label="Markings", type="color", def=Color(0.2, 0.15, 0.1)},
		{key="glow_color", label="Eye/Core Glow", type="color", def=Color(1.0, 0.8, 0.2)},
		{key="fur", label="Fur/Texture", type="float", min=0.0, max=1.0, def=0.5},
		{key="ethereal", label="Ethereality", type="float", min=0.0, max=1.0, def=0.0},
	],
}

## Audio signature defs — skills, weapons and entities can be HEARD. Armor
## gets footstep timbre only. Synthesized live via BlueprintAudio.
const AUDIO_DEFS := {
	"weapon": [
		{key="waveform", label="Timbre", type="choice", def="metal",
			choices=["metal", "glass", "wood", "void", "chime"]},
		{key="pitch", label="Pitch", type="float", min=0.4, max=2.5, def=1.0},
		{key="ring", label="Ring-out", type="float", min=0.05, max=1.2, def=0.4},
	],
	"armor": [
		{key="waveform", label="Step Timbre", type="choice", def="metal",
			choices=["metal", "leather", "cloth", "chitin", "silence"]},
		{key="pitch", label="Pitch", type="float", min=0.4, max=2.0, def=0.8},
	],
	"skill": [
		{key="waveform", label="Waveform", type="choice", def="sine",
			choices=["sine", "square", "saw", "noise", "choir"]},
		{key="pitch", label="Pitch", type="float", min=0.3, max=3.0, def=1.0},
		{key="attack", label="Attack", type="float", min=0.01, max=0.5, def=0.05},
		{key="decay", label="Decay", type="float", min=0.1, max=2.0, def=0.6},
		{key="wobble", label="Wobble", type="float", min=0.0, max=1.0, def=0.1},
	],
	"entity": [
		{key="waveform", label="Voice", type="choice", def="choir",
			choices=["sine", "square", "saw", "noise", "choir"]},
		{key="pitch", label="Voice Pitch", type="float", min=0.3, max=2.5, def=0.9},
		{key="decay", label="Call Length", type="float", min=0.2, max=2.0, def=0.8},
	],
}

static func defs_for(kind: String) -> Array:
	return PARAM_DEFS.get(kind, [])

static func audio_defs_for(kind: String) -> Array:
	return AUDIO_DEFS.get(kind, [])

## A fresh blueprint of `kind` with every param at its default. `base_id`
## ties it back to the functional item/skill it re-skins.
## Curated starter designs for the Blueprint Forge. Players begin from any
## of these instead of a blank template. Each preset is the SIX elements and
## the layers' uneasy atmosphere made solid — every value stays inside the
## param defs, so FORGE presets are FORM only and never touch balance.
const PRESETS: Array[Dictionary] = [
	# ---- weapons: silhouettes, element-tinted ---------------------------
	{kind="weapon", base_id="custom", name="Ember Fang", params={
		silhouette="claw", length=0.85, width=0.22, curve=0.35, taper=0.6, segments=1.0,
		base_color=Color(0.75, 0.1, 0.05), edge_color=Color(1.0, 0.55, 0.1),
		metallic=0.55, roughness=0.3, emission=2.3, trail=0.8},
		audio={waveform="void", pitch=1.4, ring=0.7}},
	{kind="weapon", base_id="custom", name="Frostwind Lancet", params={
		silhouette="blade", length=1.5, width=0.12, curve=-0.15, taper=0.85, segments=1.0,
		base_color=Color(0.7, 0.9, 1.0), edge_color=Color(1.0, 1.0, 1.0),
		metallic=0.5, roughness=0.12, emission=1.7, trail=0.6},
		audio={waveform="chime", pitch=1.7, ring=1.05}},
	{kind="weapon", base_id="custom", name="Stormcaller Staff", params={
		silhouette="staff", length=1.9, width=0.16, curve=0.0, taper=0.5, segments=5.0,
		base_color=Color(0.3, 0.42, 0.9), edge_color=Color(0.82, 0.92, 1.0),
		metallic=0.6, roughness=0.28, emission=2.0, trail=0.9},
		audio={waveform="glass", pitch=0.9, ring=0.8}},
	{kind="weapon", base_id="custom", name="Voidshard Lash", params={
		silhouette="lash", length=2.1, width=0.06, curve=0.5, taper=0.9, segments=1.0,
		base_color=Color(0.2, 0.1, 0.35), edge_color=Color(0.85, 0.3, 1.0),
		metallic=0.4, roughness=0.4, emission=1.9, trail=1.0},
		audio={waveform="void", pitch=0.6, ring=0.55}},

	# ---- armor: silhouette + faction accent -----------------------------
	{kind="armor", base_id="custom", name="Aegis of First Dawn", params={
		silhouette="plate", coverage=0.85, bulk=0.5, spikes=0.0,
		base_color=Color(0.92, 0.72, 0.2), accent_color=Color(1.0, 1.0, 1.0),
		metallic=0.85, roughness=0.3, emission=0.6, wear=0.1},
		audio={waveform="metal", pitch=0.9}},
	{kind="armor", base_id="custom", name="Marrowbone Bulwark", params={
		silhouette="bone", coverage=0.8, bulk=0.7, spikes=0.55,
		base_color=Color(0.86, 0.82, 0.74), accent_color=Color(0.5, 0.72, 0.42),
		metallic=0.3, roughness=0.7, emission=0.45, wear=0.85},
		audio={waveform="chitin", pitch=0.7}},
	{kind="armor", base_id="custom", name="Stillsilence Weave", params={
		silhouette="weave", coverage=0.7, bulk=0.1, spikes=0.0,
		base_color=Color(0.14, 0.11, 0.2), accent_color=Color(0.6, 0.4, 1.0),
		metallic=0.2, roughness=0.6, emission=0.85, wear=0.4},
		audio={waveform="cloth", pitch=0.6}},
	{kind="armor", base_id="custom", name="Tidecarapace", params={
		silhouette="shell", coverage=0.75, bulk=0.45, spikes=0.25,
		base_color=Color(0.2, 0.5, 0.6), accent_color=Color(0.9, 0.9, 0.8),
		metallic=0.5, roughness=0.45, emission=0.3, wear=0.6},
		audio={waveform="chitin", pitch=0.8}},

	# ---- skills: cast shapes + element VFX ------------------------------
	{kind="skill", base_id="custom", name="Nova Accusation", params={
		shape_style="burst", primary_color=Color(1.0, 0.8, 0.2), secondary_color=Color(1.0, 1.0, 1.0),
		particle_density=1.8, scale=1.4, turbulence=0.2, afterglow=1.2},
		audio={waveform="square", pitch=1.1, attack=0.02, decay=1.2, wobble=0.1}},
	{kind="skill", base_id="custom", name="Choir of Static", params={
		shape_style="ring", primary_color=Color(0.4, 0.85, 1.0), secondary_color=Color(0.92, 0.92, 1.0),
		particle_density=1.4, scale=1.0, turbulence=0.8, afterglow=1.0},
		audio={waveform="saw", pitch=0.9, attack=0.06, decay=0.5, wobble=0.8}},
	{kind="skill", base_id="custom", name="Dirge of Ash", params={
		shape_style="shards", primary_color=Color(0.5, 0.5, 0.55), secondary_color=Color(0.2, 0.15, 0.1),
		particle_density=0.6, scale=0.9, turbulence=0.95, afterglow=0.7},
		audio={waveform="noise", pitch=0.5, attack=0.12, decay=1.4, wobble=0.4}},
	{kind="skill", base_id="custom", name="Weaver's Sigil", params={
		shape_style="sigil", primary_color=Color(0.9, 0.4, 1.0), secondary_color=Color(0.4, 0.9, 1.0),
		particle_density=1.1, scale=1.2, turbulence=0.25, afterglow=1.4},
		audio={waveform="choir", pitch=0.8, attack=0.05, decay=1.6, wobble=0.2}},

	# ---- entities: body plans across the layers -------------------------
	{kind="entity", base_id="custom", name="Nightcradle Stalker", params={
		body="biped", size=1.1, limb_length=1.2, head_scale=0.9,
		base_color=Color(0.12, 0.1, 0.16), marking_color=Color(0.5, 0.4, 1.0),
		glow_color=Color(1.0, 0.9, 0.5), fur=0.2, ethereal=0.5},
		audio={waveform="choir", pitch=0.8, decay=0.9}},
	{kind="entity", base_id="custom", name="Sunforge Courser", params={
		body="quadruped", size=1.3, limb_length=1.05, head_scale=1.0,
		base_color=Color(0.8, 0.5, 0.2), marking_color=Color(1.0, 0.92, 0.6),
		glow_color=Color(1.0, 0.5, 0.1), fur=0.9, ethereal=0.0},
		audio={waveform="noise", pitch=1.0, decay=0.5}},
	{kind="entity", base_id="custom", name="Veilserpent", params={
		body="serpent", size=1.4, limb_length=0.4, head_scale=0.8,
		base_color=Color(0.3, 0.5, 0.6), marking_color=Color(0.8, 1.0, 1.0),
		glow_color=Color(0.6, 1.0, 0.9), fur=0.1, ethereal=0.8},
		audio={waveform="sine", pitch=0.6, decay=1.5}},
	{kind="entity", base_id="custom", name="Ironhollow Dirgewing", params={
		body="avian", size=1.0, limb_length=1.6, head_scale=0.6,
		base_color=Color(0.4, 0.45, 0.55), marking_color=Color(0.85, 0.2, 0.2),
		glow_color=Color(0.95, 0.1, 0.1), fur=0.0, ethereal=0.15},
		audio={waveform="saw", pitch=1.2, decay=0.7}},
]

static func preset_names(kind: String) -> Array[String]:
	var out: Array[String] = []
	for p in PRESETS:
		if p.get("kind", "") == kind:
			out.append(str(p.get("name", "")))
	return out

## Build a fresh blueprint stamped from a named preset. Unknown presets fall
## back to a blank template so callers can always create. Author remains the
## player — a preset is a STARTING POINT they own, not a canon locked design.
static func preset_bp(kind: String, name: String, display_name: String) -> Dictionary:
	var bp := fresh(kind, "custom", display_name)
	var preset := _find_preset(kind, name)
	if preset.is_empty():
		return bp
	bp.base_id = str(preset.get("base_id", "custom"))
	for k in preset.get("params", {}):
		if bp.params.has(k):
			bp.params[k] = preset.params[k]
	for k in preset.get("audio", {}):
		if bp.audio.has(k):
			bp.audio[k] = preset.audio[k]
	return bp

static func _find_preset(kind: String, name: String) -> Dictionary:
	for p in PRESETS:
		if p.get("kind", "") == kind and str(p.get("name", "")) == name:
			return p
	return {}

static func fresh(kind: String, base_id: String, display_name: String) -> Dictionary:
	var params := {}
	for d in defs_for(kind):
		params[d.key] = d.def
	var audio := {}
	for d in audio_defs_for(kind):
		audio[d.key] = d.def
	return {
		"id": "%s_%s_%d" % [kind, base_id, Time.get_ticks_msec()],
		"kind": kind,
		"name": display_name,
		"base_id": base_id,
		"params": params,
		"audio": audio,
		"author": _author_name(),
		"version": 1,
		"locked": [],
		# UGC governance (see docs/UGC_POLICY.md):
		#   private     — usable ONLY inside your own Subliminal
		#   mod_review  — submitted; Discord mod team balance check
		#   dev_review  — mods passed it; dev team canon check
		#   canon       — in-game lore; property of Holloway's Own
		#                 Providential Enterprise Apex Holdings Inc.,
		#                 creator keeps the blueprint + name + sole crafting
		#   rejected    — back to Subliminal-only, resubmit after edits
		"status": "private",
		"allow_forks": false, # NEVER forkable without the creator's opt-in
		"for_sale": false,
		"price": 0,
		"copies_sold": 0,
	}

static func _author_name() -> String:
	var profile := AutoloadGate.get_node("PlayerProfile")
	if profile == null:
		return "unknown"
	return str(profile.get("username")) if str(profile.get("username")) != "" else "unknown"

## Deterministic seed so procedural detail (scratches, rune layout, particle
## phase) is stable per blueprint but unique across them.
static func seed_of(bp: Dictionary) -> int:
	return hash(str(bp.get("id", "")) + str(bp.get("version", 1)))

static func clamp_params(bp: Dictionary) -> Dictionary:
	# Sanitize an imported blueprint: unknown keys dropped, floats clamped,
	# choices validated. Share codes come from other players — trust nothing.
	var kind: String = str(bp.get("kind", ""))
	if kind not in KINDS:
		return {}
	var clean := fresh(kind, str(bp.get("base_id", "custom")), str(bp.get("name", "Imported")))
	clean["author"] = str(bp.get("author", "unknown"))
	# Imports NEVER arrive canon or forkable — status is server-granted, not
	# something a share code can claim. An import is a fresh private design.
	clean["status"] = "private"
	clean["allow_forks"] = false
	var src: Dictionary = bp.get("params", {})
	for d in defs_for(kind):
		if not src.has(d.key):
			continue
		match d.type:
			"float":
				clean.params[d.key] = clampf(float(src[d.key]), d.min, d.max)
			"color":
				var c = src[d.key]
				if c is String:
					clean.params[d.key] = Color.from_string(c, d.def)
				elif c is Color:
					clean.params[d.key] = c
			"choice":
				if str(src[d.key]) in d.choices:
					clean.params[d.key] = str(src[d.key])
	var asrc: Dictionary = bp.get("audio", {})
	for d in audio_defs_for(kind):
		if not asrc.has(d.key):
			continue
		match d.type:
			"float":
				clean.audio[d.key] = clampf(float(asrc[d.key]), d.min, d.max)
			"choice":
				if str(asrc[d.key]) in d.choices:
					clean.audio[d.key] = str(asrc[d.key])
	return clean
