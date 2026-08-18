class_name CanonRaces
## The 20 canonical Periliminal.Space races (project spec + Races.gs).
## The hyperliminal's 20 cat breeds are those races as the CASINO renders
## them — every breed is a canon race wearing the house skin. This mapping
## keeps both true at once: gameplay ids stay the cat ids; lore, canon
## names, and cross-layer rendering read from here.
const RACES := [
	"Lumenari", "Gutterkin", "Deepborne", "Ashen Choir", "Veilstriders",
	"Chronarchs", "Nullborn", "Thorned", "Echoes", "Hollowed",
	"Riftspawn", "Mirekin", "Sunspun", "Coldmarrow", "Pulseborn",
	"Dreamflesh", "Crownless", "Rotweavers", "Glassborn", "Starfall",
]

## cat-breed id -> canon race. Order-matched to RaceDataCharacter.RACES.
static func canon_of(race_index: int) -> String:
	return RACES[race_index % RACES.size()]

static func canon_for_id(race_id: String) -> String:
	for i in range(RaceDataCharacter.RACES.size()):
		if RaceDataCharacter.RACES[i].id == race_id:
			return canon_of(i)
	return RACES[0]
