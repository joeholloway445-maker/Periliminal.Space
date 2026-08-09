class_name DungeonData
## Locked Periliminal dungeons — sealed descents hidden inside ordinary
## Metroplex buildings. A group finds a door that should not be there, opens
## it if they hold the key, and drops into a fixed-seed Periliminal run.
##
## Ranking rule: a dungeon's rank is an ESTIMATE until somebody beats it.
## Until first clear it advertises a provisional band derived from its depth
## and lock tier, shown as "Rank ?"; the first successful party's actual
## performance — how deep, how many went in, how many came out — confirms
## the real rank and freezes it for everyone thereafter. Nobody rates a
## descent nobody has survived.
##
## Placement is by city cell, matching CityVenues' convention, so a dungeon
## sits inside a specific building in a specific hub rather than floating.

## Rank bands, cheapest to hardest. Index is the stored rank.
const RANKS := ["F", "E", "D", "C", "B", "A", "S", "SS"]

## `cell` is local city-cell coordinates (see CityData.CELL), matching the
## venue convention. `depth` is the Periliminal floor count a full clear
## demands. `key` is the item/currency gate; "" means open to anyone at level.
const DUNGEONS := [
	{
		"id": "reunion_undercroft", "name": "Reunion Undercroft", "hub": "dallas",
		"cell": Vector2(1.5, 1.5), "depth": 6, "min_level": 12, "party": 2,
		"key": "", "provisional": 2,
		"blurb": "The service stair in the Reunion tower goes down one flight further than the building has floors.",
	},
	{
		"id": "pegasus_cold_storage", "name": "Pegasus Cold Storage", "hub": "dallas",
		"cell": Vector2(4.5, 1.5), "depth": 9, "min_level": 24, "party": 3,
		"key": "frost_sigil", "provisional": 4,
		"blurb": "A meat locker whose far wall is colder than the refrigeration can explain.",
	},
	{
		"id": "stockyard_killfloor", "name": "The Killfloor", "hub": "fort_worth",
		"cell": Vector2(0.5, 2.5), "depth": 8, "min_level": 20, "party": 3,
		"key": "", "provisional": 3,
		"blurb": "Below the Stockyards, a processing line that never stopped running.",
	},
	{
		"id": "acre_bell_shaft", "name": "Bell Shaft", "hub": "fort_worth",
		"cell": Vector2(3.5, 4.5), "depth": 12, "min_level": 34, "party": 4,
		"key": "clocktower_key", "provisional": 5,
		"blurb": "The clocktower's counterweight shaft has no bottom and a draft coming up it.",
	},
	{
		"id": "denton_practice_rooms", "name": "The Practice Rooms", "hub": "denton",
		"cell": Vector2(2.5, 3.5), "depth": 7, "min_level": 16, "party": 2,
		"key": "", "provisional": 3,
		"blurb": "Soundproofed rooms in the music annex, one of which is still occupied.",
	},
	{
		"id": "denton_squarewell", "name": "Squarewell", "hub": "denton",
		"cell": Vector2(5.5, 1.5), "depth": 11, "min_level": 30, "party": 4,
		"key": "courthouse_writ", "provisional": 5,
		"blurb": "The courthouse basement floods with something that is not water.",
	},
	{
		"id": "sanctuary_understage", "name": "Understage", "hub": "arlington",
		"cell": Vector2(2.5, 0.5), "depth": 10, "min_level": 28, "party": 3,
		"key": "", "provisional": 4,
		"blurb": "Beneath the Star Bowl, a second stadium facing the wrong way.",
	},
	{
		"id": "sanctuary_dry_dock", "name": "The Dry Dock", "hub": "arlington",
		"cell": Vector2(6.5, 4.5), "depth": 15, "min_level": 45, "party": 5,
		"key": "station_override", "provisional": 7,
		"blurb": "The Space Station's maintenance bay, which predates the station.",
	},
]

static func all() -> Array:
	return DUNGEONS

static func get_dungeon(id: String) -> Dictionary:
	for d in DUNGEONS:
		if str(d.id) == id:
			return d
	return {}

## Every dungeon sitting in one hub.
static func in_hub(hub_id: String) -> Array:
	var out: Array = []
	for d in DUNGEONS:
		if str(d.hub) == hub_id:
			out.append(d)
	return out

static func rank_label(index: int) -> String:
	return RANKS[clampi(index, 0, RANKS.size() - 1)]

## The rank a first clear proves, from how that run actually went.
##
## The provisional band is the starting estimate. A party that went deeper
## than the dungeon demands, or cleared it under-strength, proves it was
## rated too soft; a full party that barely scraped the required depth with
## losses proves it was rated about right. Deaths push the rank UP — a
## descent that kills people is not an easy one, whatever the estimate said.
static func rank_from_clear(dungeon: Dictionary, depth_reached: int,
		party_size: int, deaths: int) -> int:
	var rank := int(dungeon.get("provisional", 3))
	var required := int(dungeon.get("depth", 6))
	var expected := maxi(int(dungeon.get("party", 2)), 1)

	# Cleared with fewer bodies than it was built for: harder than rated.
	if party_size < expected:
		rank += expected - party_size
	# Brought more than it was built for and still lost people: harder still.
	elif deaths > 0:
		rank += 1
	# Overshot the required depth with nobody lost: it was rated too high.
	if depth_reached > required + 2 and deaths == 0:
		rank -= 1
	# Everyone walked out of a full-strength run at exactly depth: as rated.
	rank += mini(deaths, 2)

	return clampi(rank, 0, RANKS.size() - 1)

## Human-readable gate text for the entrance plate.
static func requirement_text(d: Dictionary) -> String:
	var parts := ["Lv %d" % int(d.get("min_level", 1))]
	var party := int(d.get("party", 1))
	if party > 1:
		parts.append("%d+ party" % party)
	var key := str(d.get("key", ""))
	if not key.is_empty():
		parts.append(key.capitalize().replace("_", " "))
	return " · ".join(parts)
