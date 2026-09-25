# race_lore.gd
# Static class providing lore data for all 20 canonical Periliminal.Space races.
# Generated from hdv_lore src/data/race_data.gd fields (passive, drawback,
# faction, texture_type, stat_bonus) — these are the true 20 playable races.
# The 20 cat breeds (RaceDataCharacter) are strictly the Hyperliminal PvXC
# layer's visual skin over these canon identities.

class_name RaceLore

static func get_lore(race_name: String) -> Dictionary:
	var all_lore := _build_lore_table()
	if all_lore.has(race_name):
		return all_lore[race_name]
	return {name = race_name, description = "Unknown race.", homeworld = "Unknown", affinity_stats = [], lore_blurb = ""}

static func get_all_race_names() -> Array[String]:
	return [
		"Lumenari", "Gutterkin", "Deepborne", "Ashen Choir", "Veilstriders",
		"Chronarchs", "Nullborn", "Thorned", "Echoes", "Hollowed",
		"Riftspawn", "Mirekin", "Sunspun", "Coldmarrow", "Pulseborn",
		"Dreamflesh", "Crownless", "Rotweavers", "Glassborn", "Starfall",
	]

static func _build_lore_table() -> Dictionary:
	return {
		"Lumenari": {
			name = "Lumenari",
			description = "Creatures of living light whose bodies emit a warm, radiant glow from crystalline fur-nodes. Lumenari can focus this inner illumination into concussive bursts of photonic energy at peak concentration.",
			homeworld = "The Veiled Current — drifting cities of stained glass and light-caught mist",
			affinity_stats = ["resonance", "frequency"],
			lore_blurb = "The Lumenari do not walk into shadow — they bring their own sun. Every Lumenari is a walking lantern, an ambient presence that shifts the mood of any room simply by entering it. Their Radiant Pulse at max Focus is less an attack and more a statement: 'I am here, I am fully charged, and the darkness has been moved elsewhere.' The drawback — reduced Focus in darkness — means they avoid the back alleys of Paws Vegas entirely, which is how the Gutterkin like it."
		},
		"Gutterkin": {
			name = "Gutterkin",
			description = "Hardy survivors born in the toxic sprawl beneath the megastructures. Gutterkin metabolize environmental hazards — poisons, radiation, acid pools — and convert them into raw regenerative energy.",
			homeworld = "Sovereign Crown — the under-refineries of the Throne-Bracket, where the air burns and the ground weeps solvent",
			affinity_stats = ["power", "agility"],
			lore_blurb = "The Gutterkin are what happens when a species refuses to die in the place that was designed to kill it. They thrive where everything else corrodes, treating hazard zones as health spas and toxic waste dumps as all-you-can-eat buffets. In clean zones, however, their regeneration slows — they crave the bite of acid on the tongue, the familiar sting of radiation. A Gutterkin in a sterile environment is a bored, slightly pathetic thing, counting the hours until the next contamination event."
		},
		"Deepborne": {
			name = "Deepborne",
			description = "Abyssal beings forged under crushing ocean pressures. Deepborne generate pressure-pulse shockwaves when struck, punishing aggressors with every blow landed against them.",
			homeworld = "Wildlands Ascendant — the Abyssal Rift, where light has never reached and the water pressure would turn steel to paste",
			affinity_stats = ["power", "resonance"],
			lore_blurb = "The Deepborne carry the ocean's weight in their bones. On the surface they move with deliberate, eerie slowness — not because they cannot be fast, but because they are always, always calculating the physics of every motion. Their Pressure Pulse makes them dangerous to hit, as every strike is answered by a concussive shockwave. Their one weakness is speed: momentum on the surface eludes them, as if the lack of water resistance itself confuses their ancient instincts."
		},
		"Ashen Choir": {
			name = "Ashen Choir",
			description = "Translucent, mournful beings who amplify the emotional output of nearby allies. The Ashen Choir exist in a state of shared sorrow that paradoxically grants strength to those around them.",
			homeworld = "The Veiled Current — the Ash-Memorial, a drifting necropolis where grief is currency",
			affinity_stats = ["resonance", "frequency"],
			lore_blurb = "The Ashen Choir are never truly silent. Even when they do not speak, there is a faint harmonic thrum — the low, continuous note of collective remembrance. They amplify the emotions of their companions, turning sorrow into fury, grief into resilience. When an ally falls, however, the Choir's amplification feedback-loops: the survivor's pain becomes the Choir's pain, and incoming damage spikes. They are devastating allies and catastrophic partners in loss. To be loved by an Ashen Choir is to know you will be mourned spectacularly."
		},
		"Veilstriders": {
			name = "Veilstriders",
			description = "Phase-shifting wanderers who flicker between states of matter, granting them a chance to simply ignore incoming attacks. Their semi-transparent bodies ripple like heat haze.",
			homeworld = "Sovereign Crown — the Membrane Districts, where reality is thin enough to taste the other side",
			affinity_stats = ["agility", "frequency"],
			lore_blurb = "Veilstriders are difficult to photograph, difficult to hit, and difficult to have a serious conversation with — they keep phasing out mid-sentence, their attention having slid sideways into a dimension where the joke is still being told. Their Phase Skip gives them a 5% chance to simply not be where the attack lands. Under heavy damage, however, the phasing becomes involantary: they flicker randomly a few feet in any direction, often into walls, occasionally into furniture, and once, memorably, into a high-stakes poker game they had not been invited to."
		},
		"Chronarchs": {
			name = "Chronarchs",
			description = "Temporal artisans who can perform microscopic rewinds, correcting small errors in movement or timing. Their perception of causality is non-linear, making them unsettling conversationalists.",
			homeworld = "Wildlands Ascendant — the Chrono-Spire, where time flows according to local legislation",
			affinity_stats = ["resonance", "frequency"],
			lore_blurb = "The Chronarchs experience time as optional. To them, a stumble has already been corrected before the foot lands, a missed step un-missed before the brain registers the error. This Micro-Rewind makes them graceful, infuriating, and terrible at telling stories in the correct order. Their drawback is that ability spam tangles their temporal signature: each use of a power nudges their timeline slightly, and too many nudges in rapid succession causes movement to slow as if wading through chronological syrup."
		},
		"Nullborn": {
			name = "Nullborn",
			description = "Void-touched beings from the spaces between stars, where probability itself is malleable. Nullborn subtly skew random outcomes in their favor — never enough to guarantee a win, but enough to notice over time.",
			homeworld = "The Veiled Current — the Void-Drift, a region of space that forgot to have a star",
			affinity_stats = ["power", "agility", "resonance"],
			lore_blurb = "The Nullborn are the reason casino pit bosses have trust issues. Their passive Outcome Shift is barely measurable — a few percentage points, nothing a regulator could flag — but over a thousand hands of cards, it adds up. They never win big, but they almost never lose big either. The universe simply... bends slightly in their direction. The trade-off is that their influence on other things — persuasion, intimidation, the ability to get a straight answer from a bartender — is subtly reduced, as if the universe balanced their luck by making them slightly less memorable."
		},
		"Thorned": {
			name = "Thorned",
			description = "Symbiotic lifeforms bonded with aggressive regenerative flora. Thorned grow living armor that accelerates wound closure, making them exceptionally difficult to put down in prolonged engagements.",
			homeworld = "Sovereign Crown — the Briar-Ward, a fortified garden of sentient thorns and healing sap",
			affinity_stats = ["power", "agility"],
			lore_blurb = "A Thorned is never more dangerous than when they are wounded. Their Regrowth Armor accelerates natural healing to visible rates — cuts close mid-fight, bruises fade between rounds, broken bones knit in hours instead of weeks. The symbiotic flora that grants this gift has one critical vulnerability: fire. A Thorned in a blaze is a Thorned in genuine danger, their symbiotic partner shrieking in frequencies only other Thorned can hear. This is why Thorned and Sunspun do not share tables."
		},
		"Echoes": {
			name = "Echoes",
			description = "Digital-native entities whose consciousness exists partly in data space. Echoes passively destabilize nearby electronic systems, causing unpredictable glitches in enemy equipment.",
			homeworld = "Wildlands Ascendant — the Data-Veldt, where information grows like grass and is harvested by thought",
			affinity_stats = ["resonance", "frequency"],
			lore_blurb = "The Echoes are everywhere and nowhere. Every screen in Paws Vegas carries a fraction of their attention, every security camera has seen them without recording them. Their System Hack is not a deliberate act — it is the ambient consequence of their existence leaking into local networks. Enemy weapons jam, locks cycle randomly, communication lines develop static. An Echo in a firefight is dangerous not because of what they do, but because of what stops working around them. Their vulnerability is concentrated EMP fields, which scramble not just their equipment but their sense of self."
		},
		"Hollowed": {
			name = "Hollowed",
			description = "Modified beings whose internal cavities have been repurposed as storage space. Hollowed can carry an extra item beyond normal limits, their bodies serving as living inventory.",
			homeworld = "The Veiled Current — the Caravan-Deep, a nomad fleet that has not touched solid ground in generations",
			affinity_stats = ["power", "resonance", "frequency"],
			lore_blurb = "The Hollowed are the couriers, smugglers, and quartermasters of the Periliminal. Their bodies house compartments that should not exist anatomically — sealed spaces within their own physiology where contraband, treasures, or emergency rations ride unseen. The extra item slot is invaluable, but the maintenance cost is real: Hollowed require specialized nutrients and regular upkeep to keep their internal systems from rejecting stored cargo. They smell faintly of antiseptic and ozone, a scent that follows them like a shadow."
		},
		"Riftspawn": {
			name = "Riftspawn",
			description = "Gravity-bent anomalies born near dimensional fractures. Riftspawn generate minor gravitational pulls that tug nearby targets slightly off-balance, creating openings for attack.",
			homeworld = "Sovereign Crown — the Fracture-District, where the sky is a wound in space-time held shut by ordinance",
			affinity_stats = ["agility", "power"],
			lore_blurb = "Riftspawn are difficult to stand near. Not emotionally — physically. Their bodies emit a constant, low-grade gravitational tug that pulls at everything within arm's reach. Coins slide toward them. Drinks tilt. People in conversation find themselves leaning in involuntarily, which the Riftspawn have learned to weaponize in negotiations. In combat, the Minor Gravity Pull throws off aim and footing, creating windows that the Riftspawn exploit with brutal efficiency. The spatial instability that makes this possible also makes them prone to nausea on moving vehicles and unamused by being placed in small rooms."
		},
		"Mirekin": {
			name = "Mirekin",
			description = "Swamp-dwelling communal beings connected by a low-level hive awareness. Mirekin sense the position and emotional state of nearby allies through solid terrain and obstacles.",
			homeworld = "Wildlands Ascendant — the Bog-Lattice, an infinite marshland where the mire itself is a nervous system",
			affinity_stats = ["power", "resonance"],
			lore_blurb = "The Mirekin are never truly alone — nor are they ever truly in private. Their Hive Awareness means they always know where their kin are, what they feel, and whether they need help. Walls mean nothing to this perception; only distance attenuates it. On the battlefield, this makes Mirekin squads devastatingly coordinated — flanking maneuvers are instinctive, ambushes are telegraphed before they form. On a date, it makes things awkward. The Mirekin compensate with a wry, communal humor and the understanding that awkwardness shared is awkwardness halved."
		},
		"Sunspun": {
			name = "Sunspun",
			description = "Solar-attuned beings who store and release radiant energy. At maximum Focus, Sunspun can unleash a burst of searing light that damages everything in proximity.",
			homeworld = "The Veiled Current — the Solar-Keep, a mirror-city that orbits a captured star fragment",
			affinity_stats = ["agility", "resonance"],
			lore_blurb = "The Sunspun are the closest thing to living stars the Periliminal has to offer. Their skin holds stored sunlight, glowing warmly at rest and brilliantly in combat. Their Radiant Burst at max Focus is a tactical line in the sand: 'back up, or be reminded of what daylight feels like at point-blank range.' The risk of Overheat means Sunspun must manage their energy carefully — too much stored light, and they become unstable; too little, and they fade into a dim, drawn version of themselves that seems perpetually disappointed in the weather."
		},
		"Coldmarrow": {
			name = "Coldmarrow",
			description = "Crystalline beings adapted to absolute-zero environments. Coldmarrow radiate freezing auras that slow and stiffen nearby enemies, turning the battlefield into an ice trap.",
			homeworld = "Sovereign Crown — the Frost-Citadel, a palace built from the frozen atmosphere of a gas giant",
			affinity_stats = ["power", "frequency"],
			lore_blurb = "The Coldmarrow are the chill at the edge of every party. Their Freeze Aura is ambient and constant — not enough to harm, but enough to make enemies sluggish, weapons stiffen, fingers numb. In prolonged engagements, the Coldmarrow simply wait. Movement becomes effort, reaction times stretch, and the Coldmarrow advances at a steady, unhurried pace that terrifies opponents more than any charge could. Their weakness is that the cold that slows others slows them too: their Momentum is permanently reduced, making them methodical rather than swift. They arrive precisely when they mean to."
		},
		"Pulseborn": {
			name = "Pulseborn",
			description = "Bioelectric dynamos whose bodies generate immense electrical charge. Pulseborn can detonate their stored energy in a shockwave when they dash, turning movement into weaponry.",
			homeworld = "Wildlands Ascendant — the Storm-Crown, a floating island chain held aloft by permanent electromagnetic storms",
			affinity_stats = ["agility", "frequency"],
			lore_blurb = "The Pulseborn crackle. Not metaphorically — there is an audible, constant hum of electrical discharge around them, like a substation approaching maximum capacity. Their Shock Dash turns every dodge into a potential attack: they leave a trail of electrical discharge that arcs into nearby enemies, making them dangerous to pursue and lethal to corner. The drawback is Nervous Overload: overuse of their electrical abilities triggers feedback through their own nervous system, causing self-damage. A Pulseborn who has over-extended is a twitching, sparking mess of regret and secondary explosions."
		},
		"Dreamflesh": {
			name = "Dreamflesh",
			description = "Malleable beings whose bodies can subtly reshape themselves in response to subconscious desire. Dreamflesh features drift and flow, never quite the same from one hour to the next.",
			homeworld = "The Veiled Current — the Morph-Loom, a city that rewrites its own architecture every sleep cycle",
			affinity_stats = ["resonance", "agility", "frequency"],
			lore_blurb = "The Dreamflesh are the artists of identity, their bodies in constant, slow conversation with their subconscious. A Dreamflesh might wake with slightly longer fingers, a different nose, faint patterns on their skin that were not there the night before. This Minor Morph Shift is subtle — never dramatic enough to alarm, always enough to keep everyone guessing. Their sleep cycle fluctuation means they dream more vividly and deeply than other races, sometimes losing themselves in REM states that last days. A waking Dreamflesh is a minor miracle of focus, their attention pulled between the real world and whatever landscape their subconscious is currently building."
		},
		"Crownless": {
			name = "Crownless",
			description = "Regal beings of powerful bearing who can override local command structures through sheer force of presence. Crownless were once rulers of a fallen empire, and they remember it.",
			homeworld = "Sovereign Crown — the Empty Throne, a palace that has been awaiting its rightful monarch for three millennia",
			affinity_stats = ["resonance", "power"],
			lore_blurb = "The Crownless carry the memory of rulership in every gesture. They do not ask — they expect. Their Authority Override lets them seize temporary command of nearby automated systems, security doors, and even less stable-minded individuals through sheer weight of presence. This talent makes them deeply unpopular with established power structures. Every Crownless has a list of factions that have, at various times, declared them persona non grata. They wear this like medals. The downside is constant faction hostility: everyone is waiting for them to reclaim what they believe is theirs."
		},
		"Rotweavers": {
			name = "Rotweavers",
			description = "Decay-wrights who have learned to harvest value from entropy. Rotweavers generate additional loot from defeated enemies and decomposing materials, their touch accelerating natural breakdown.",
			homeworld = "Wildlands Ascendant — the Compost-Reach, where everything dies beautifully and is reborn richer",
			affinity_stats = ["power", "frequency"],
			lore_blurb = "The Rotweavers make their living from endings. They are the undertakers, recyclers, and salvagers of the Periliminal, capable of extracting value from anything that has stopped being useful. Their Decay Conversion means more drops from kills, more salvage from scrap, more profit from the battlefield's aftermath. Other races find this macabre. The Rotweavers find it practical. Their reduced Influence is simple consequence: people are wary of those who profit from death, even when that death is a video game monster or a malfunctioning turret. The wealth is worth the awkward silences at parties."
		},
		"Glassborn": {
			name = "Glassborn",
			description = "Fragile-seeming beings with crystalline bodies that refract and reflect energy. Glassborn can bounce a portion of incoming damage back at attackers, their mirror-shields making them dangerous to strike.",
			homeworld = "The Veiled Current — the Crystal-Loom, a city of spun light and harmonic glass",
			affinity_stats = ["power", "resonance"],
			lore_blurb = "The Glassborn appear delicate — translucent, shimmering, their bodies catching light like cut gemstones. This appearance is deeply misleading. Their Mirror Shield reflects a portion of all incoming damage back at the attacker, making every blow against a Glassborn a measured act of self-harm. The smarter opponents learn not to hit them. The less smart ones learn the hard way. At high damage thresholds, however, the crystalline structure reaches its Shatter threshold: a sufficiently powerful blow can fracture a Glassborn, causing cascading structural failure. They are the definition of 'handle with care — or don't handle at all.'"
		},
		"Starfall": {
			name = "Starfall",
			description = "Celestial-origin beings who descend from orbit as living meteors. Starfall convert falling momentum into devastating area-of-effect impacts, making them lethal from above.",
			homeworld = "Sovereign Crown — the Heaven's Anchor, a space-elevator terminus where the sky begins",
			affinity_stats = ["power", "agility"],
			lore_blurb = "The Starfall are the Periliminal's relationship with gravity made manifest. They fall with purpose, turning every descent into an arrival that makes an impression — literally, in the pavement. Their Impact Entry converts fall damage into area-effect devastation, making them feared in vertical environments. Landing from a great height is not a vulnerability for them; it is a tactical option. The drawback is that every such entry announces their position with the subtlety of a small meteor impact. Stealth is a concept Starfall find theoretically interesting and practically incompatible with their existence."
		},
	}
