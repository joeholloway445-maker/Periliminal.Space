class_name PersonaBuckets
## The plug-and-play content engine behind race personality.
##
## The problem: giving 20 races distinct chatter, greetings, taunts, musings,
## farewells, flirts, and story lines is a LOT of writing — and copying a pool
## onto every race wastes memory and duplicates edits.
##
## The solution here: content lives in shared, tag-keyed BUCKETS, loaded once
## as constants. A race maps to ONE tag per axis (its "mood" for temperament
## channels, its "stance" for the story channel), and every channel resolves
## through that tag. So a dozen mood buckets cover all twenty races, and adding
## a race is just picking its tags — no new prose required. When a race DOES
## deserve bespoke lines, drop them in RACE_OVERRIDES and they win; everything
## else keeps falling back to the shared bucket. That's the "simple templates,
## plug-and-play buckets, per channel AND per race" shape, and it's memory-light
## because the pools are shared, not per-instance.
##
## To add a channel: add its pool dict + an entry in CHANNELS/CHANNEL_AXIS.
## To give one race unique lines: RACE_OVERRIDES[canon][channel] = [ ... ].
## To retune a whole temperament: edit its bucket once; every race on that tag
## updates.

# ---------------------------------------------------------------- tag maps

## Temperament bucket per race — drives the mood-axis channels + label colour.
const MOOD_OF := {
	"Keth": "furtive", "Lumari": "proud", "Vex": "dreamy", "Ferox": "brash",
	"Azhul": "cryptic", "Sylva": "warm", "Geara": "hyper", "Nyx": "grim",
	"Aquis": "calm", "Igni": "brash", "Kryos": "cold", "Myco": "calm",
	"Volt": "hyper", "Petra": "stoic", "Sanguis": "grim", "Chimera": "hyper",
	"Astra": "dreamy", "Ferros": "proud", "Etherea": "dreamy", "Glyphe": "pedantic",
}

## Where each race stands on the Theory of Everything — the discovery that one
## law underlies every reality layer, and the war over what to DO with that.
## The Liminal's first finders realized the layers could be fused into a
## single, total state — godhood, in effect, shared and absolute. They never
## agreed on whether that fusion was worth having, and while they argued, the
## chance passed. What's left are the two Solutions and the people still
## arguing them (see docs/STORY_SINGULARITY.md for the full premise):
##   singularity      The Solution of Everything — collapse the layers into
##                     one total state. Unity by addition.
##   anti_singularity  The Solution of Nothing — refuse the collapse. Nothing
##                     is fused, nothing is lost; the many stay many.
##   seeker            Still chasing the Theory itself, undecided which
##                     Solution it justifies.
##   unaligned         No stake in either Solution — the Theory is a human/
##                     scholarly argument to them, not a cause.
## PROVISIONAL and fully overridable: derived from each race's element, not
## fixed canon. Change any assignment freely; nothing downstream hard-codes it.
const STANCE_OF := {
	# The Solution of Everything — reality resolves to one point; embrace the collapse.
	"Geara": "singularity", "Volt": "singularity", "Ferros": "singularity", "Myco": "singularity",
	# The Solution of Nothing (the twist) — the many must stay many; resist the one.
	"Sylva": "anti_singularity", "Aquis": "anti_singularity", "Ferox": "anti_singularity", "Chimera": "anti_singularity",
	# The Seekers — chase the Theory of Everything for its own sake.
	"Azhul": "seeker", "Glyphe": "seeker", "Astra": "seeker", "Lumari": "seeker", "Sanguis": "seeker",
	# The Between — no stake in the war of Solutions; just survive the layers.
	"Keth": "unaligned", "Nyx": "unaligned", "Vex": "unaligned", "Etherea": "unaligned",
	"Kryos": "unaligned", "Igni": "unaligned", "Petra": "unaligned",
}

const MOOD_DEFAULT := "calm"
const STANCE_DEFAULT := "unaligned"

# --------------------------------------------------------------------- origins

## Not every race is from the same world, or the same PART of one — the races
## are grouped into ORIGINS, distinct cradle-realities that only became
## neighbors once the Liminal connected them. An origin is the unit that
## carries history: two races from the same origin already know each other;
## two from origins with old grudges arrive as strangers who are already
## rivals, whatever the player does next. This is the hook for storylines
## that "complement or contradict" across races, and the seam DLC plugs new
## races/origins into (see "Adding a DLC race" in docs/PERSONA_SYSTEM.md).
const ORIGINS := {
	"ash_forged": {
		"name": "The Ash-Forged",
		"blurb": "A harsh, volcanic forge-world where survival meant hardening — into warriors, into iron, into blood-discipline. Martial, severe, quick to claim territory as the only safety that lasts.",
	},
	"void_between": {
		"name": "The Void-Between",
		"blurb": "Not a world so much as the gap between worlds — a lightless reality its natives learned to exist partway outside of. Patient, watchful, comfortable with not fully arriving anywhere.",
	},
	"verdant_cradle": {
		"name": "The Verdant Cradle",
		"blurb": "A living, networked biosphere-world where nothing grew alone. Communal by instinct, slow to anger, and unnervingly patient — a forest thinks in centuries.",
	},
	"glass_reaches": {
		"name": "The Glass Reaches",
		"blurb": "An ancient crystalline and glacial world, old before most others had a first age. Its natives measure time the way others measure distance, and rarely feel rushed by anything.",
	},
	"storm_wrought": {
		"name": "The Storm-Wrought",
		"blurb": "A world of perpetual electrical storms where survival meant fusing with the current instead of hiding from it — machine and organism blurred early and never fully separated again.",
	},
	"starfall_expanse": {
		"name": "The Starfall Expanse",
		"blurb": "Beings descended from a world so close to the sky's edge that its people never stopped looking up. Contemplative, a little grandiose, and instinctively drawn to the shape of big patterns.",
	},
}

## canon race -> origin id. Provisional and overridable, same as MOOD_OF /
## STANCE_OF; a DLC race just needs one entry here (reusing an origin, or
## adding a new one to ORIGINS first).
const ORIGIN_OF := {
	"Igni": "ash_forged", "Sanguis": "ash_forged", "Ferros": "ash_forged", "Ferox": "ash_forged",
	"Nyx": "void_between", "Vex": "void_between", "Etherea": "void_between", "Keth": "void_between",
	"Sylva": "verdant_cradle", "Myco": "verdant_cradle", "Aquis": "verdant_cradle",
	"Lumari": "glass_reaches", "Kryos": "glass_reaches", "Petra": "glass_reaches",
	"Volt": "storm_wrought", "Geara": "storm_wrought", "Chimera": "storm_wrought",
	"Astra": "starfall_expanse", "Azhul": "starfall_expanse", "Glyphe": "starfall_expanse",
}

## Sparse relation graph BETWEEN ORIGINS (not races directly — two races from
## the same origin are automatically allies; races from unrelated origins
## default to "neutral"). Keyed "originA|originB" with the pair sorted
## alphabetically so lookups don't care which order you ask in. Entirely
## provisional — this is the skeleton for storylines that make some races
## complement each other and others contradict, independent of the Theory
## stance above (an ash_forged singularity-believer and a storm_wrought
## singularity-believer can still be rivals; agreement on the Theory doesn't
## erase where you're from).
## NOTE: keys must have their two origin ids in alphabetical order — lookup
## sorts the pair before building the key, so an out-of-order key here would
## silently never match and fall through to "neutral".
const ORIGIN_RELATIONS := {
	"ash_forged|verdant_cradle": "enemy",       # the forge-world's industry burned the green one, once
	"ash_forged|void_between": "rival",         # both harsh philosophies, competing for the same respect
	"ash_forged|storm_wrought": "rival",        # martial pride vs. augmented ambition
	"glass_reaches|storm_wrought": "enemy",     # ancient permanence vs. restless reinvention
	"glass_reaches|verdant_cradle": "ally",     # two slow, patient, deep-time worlds recognize each other
	"starfall_expanse|void_between": "ally",    # both liminal, both at ease with the unseen
	"storm_wrought|verdant_cradle": "rival",    # nature vs. augmentation, an old argument
	"starfall_expanse|verdant_cradle": "ally",  # long views sympathize with long views
}

const RELATION_DEFAULT := "neutral"

## Disposition swing for each relation tier, applied between the PLAYER's race
## origin and an NPC's — see RacePersona.origin_disposition_bias(). Small on
## purpose: history colours a first meeting, it doesn't decide it.
const RELATION_BIAS := {"ally": 10, "rival": -6, "enemy": -14, "neutral": 0}

# ---------------------------------------------------------------- factions

## Which of the four human factions each race is historically tied to. This is
## a SEPARATE axis from STANCE_OF on purpose: the Theory war is ancient and
## cosmic, between the races themselves; the factions are recent and human —
## SovereignCrown, WildlandsAscendant, and VeiledCurrent formed only after
## humanity found the Liminal and, rather than understand what they'd found,
## moved to claim it. (Factionless is the honest answer: no one could actually
## own a reality layer, and some races/individuals never pretended otherwise.)
## A race's faction tie reflects which claim recruited or absorbed them, not
## which Solution they believe in — a race can be tied to SovereignCrown and
## still privately hold the Solution of Nothing. Provisional and overridable;
## a DLC race just needs one entry here (or none, to be born Factionless).
const RACE_FACTION_OF := {
	"Ferros": "SovereignCrown", "Lumari": "SovereignCrown", "Petra": "SovereignCrown",
	"Sanguis": "SovereignCrown", "Astra": "SovereignCrown",
	"Sylva": "WildlandsAscendant", "Ferox": "WildlandsAscendant", "Myco": "WildlandsAscendant",
	"Aquis": "WildlandsAscendant", "Igni": "WildlandsAscendant",
	"Vex": "VeiledCurrent", "Keth": "VeiledCurrent", "Volt": "VeiledCurrent",
	"Geara": "VeiledCurrent", "Glyphe": "VeiledCurrent",
	"Nyx": "Factionless", "Kryos": "Factionless", "Chimera": "Factionless",
	"Etherea": "Factionless", "Azhul": "Factionless",
}

# ---------------------------------------------------------------- mood buckets

## Idle/ambient chatter — what a wandering NPC of this mood mutters to no one.
const BARKS := {
	"furtive": ["Nothing to see here.", "...who's asking?", "Keep moving.",
		"I didn't see anything.", "Eyes on the exits."],
	"proud": ["Mind the finish.", "You may look. Briefly.", "Quality, obviously.",
		"Do try to keep up.", "Standards, darling."],
	"dreamy": ["...where was I?", "The light's strange today.", "Mm. Far away.",
		"Did you feel that?", "...oh. You're still here."],
	"brash": ["Out of my way.", "You want something?", "Ha! Weak.",
		"Step up or step off.", "That all you got?"],
	"cryptic": ["I already knew you'd pass.", "It ends as it must.", "Curious. As foreseen.",
		"You'll understand later.", "The odds favor silence."],
	"warm": ["Good to see you.", "Growing nicely, isn't it?", "Take care out there.",
		"Sit a while.", "The garden remembers you."],
	"hyper": ["Hi-hi-hey! Busy busy.", "Ooh what's that— nevermind.", "Quickquick, no time!",
		"Didyouseethat? Never mind!", "Three things at once, easy."],
	"grim": ["Don't.", "It never lasts.", "Everything ends.",
		"You'll learn.", "...still here, then."],
	"calm": ["It flows.", "No rush.", "All in time.",
		"Easy does it.", "We drift."],
	"cold": ["...", "Patience.", "In due course.",
		"The cold keeps.", "You're early. Or late. No matter."],
	"pedantic": ["Technically incorrect.", "Actually, the term is—", "Cite your source.",
		"Imprecise, but close.", "Let me correct that."],
	"stoic": ["Mm.", "Time enough.", "Stone endures.",
		"It has been longer.", "Your hurry amuses me."],
}

## Greeting lines by mood — the first thing this race says when engaged.
const GREETINGS := {
	"furtive": ["...you. What do you want?", "Make it quick.", "Didn't expect company."],
	"proud": ["You have my attention. Briefly.", "Well. Look who it is.", "Speak, then."],
	"dreamy": ["Oh... hello. Were you here long?", "Mm? A visitor.", "You drifted in too."],
	"brash": ["What.", "You need something or not?", "Make it worth my time."],
	"cryptic": ["I wondered when you'd come.", "As expected. Sit.", "You're right on schedule."],
	"warm": ["Ah, welcome, welcome!", "Good to see a friendly face.", "Come, sit with me."],
	"hyper": ["Heyheyhey! What's up what's up?", "Oh! You! Hi! What's new?", "Fast now, talk talk!"],
	"grim": ["...what.", "You shouldn't have come.", "Speak and go."],
	"calm": ["Peace. What brings you?", "Ah. You found me.", "Come, no hurry."],
	"cold": ["...State your business.", "You have a moment. Use it.", "Well?"],
	"pedantic": ["Yes? Be precise.", "You have a question. Phrase it correctly.", "Ah. Do go on — accurately."],
	"stoic": ["You again. Sit.", "Time enough for you.", "Speak, small one."],
}

## Longer idle observations — a beat of personality past the one-liners.
const MUSINGS := {
	"furtive": ["Every room has a second way out. Most people never look.",
		"Trust is just credit you haven't lost yet."],
	"proud": ["Anyone can arrive. Arriving *well* is the trick.",
		"I don't compete. I set the line others fail to reach."],
	"dreamy": ["Sometimes I forget which layer I woke in.",
		"If you stare long enough, the walls admit they're thinking."],
	"brash": ["Talk is cheap. Show me your knuckles.",
		"Half these fighters would fold if you just stepped closer."],
	"cryptic": ["The dice already know. They're just being polite about it.",
		"Every choice you agonize over, I watched you make an hour ago."],
	"warm": ["Kindness costs nothing and compounds like interest.",
		"Everyone's carrying something. Ask, and mostly they'll set it down."],
	"hyper": ["Okay okay so I had an idea— oh! Better idea— wait, first one was—",
		"Can't sit still, sitting still is where the bad thoughts catch up!"],
	"grim": ["Every winning streak is just a losing streak taking its time.",
		"I've buried better than you. I'll bury worse."],
	"calm": ["The current takes what it takes. No sense wrestling it.",
		"Still water and a patient mind win more hands than nerve."],
	"cold": ["Warmth is a leak. I don't leak.",
		"Rush, and you'll make the mistake I'm waiting for."],
	"pedantic": ["'Luck' is unmodeled variance. Say what you mean.",
		"Precisely three of your last claims were wrong. I counted."],
	"stoic": ["I have watched fortunes rise and settle like dust. This too.",
		"Ask the stone what it fears. It has forgotten how to answer."],
}

## Emote/combat taunts — a jab thrown with the whole persona behind it.
const TAUNTS := {
	"furtive": ["You didn't even see it coming.", "Blink and it's gone. So are you."],
	"proud": ["Was that your best? How embarrassing.", "Kneel. It suits you."],
	"dreamy": ["Oh... are we fighting? Sure, why not.", "You feel very... temporary."],
	"brash": ["Come ON. Hit me for real!", "That tickled. My turn."],
	"cryptic": ["I saw you lose this already.", "Struggle. It changes nothing."],
	"warm": ["No hard feelings — but you're going down.", "This'll only sting a little, friend."],
	"hyper": ["Toofast-toofast-toofast!", "Missed me missed me now you— missed again!"],
	"grim": ["Stay down.", "This ends the way it always does."],
	"calm": ["I won't even raise my voice.", "Flow around it. Then through you."],
	"cold": ["You're already frozen. You just haven't noticed.", "Slow. Predictable. Over."],
	"pedantic": ["Your form is, objectively, incorrect.", "Statistically, you've already lost."],
	"stoic": ["I have outlasted mountains.", "Push. The stone pushes back."],
}

## Sign-offs — how they end a conversation.
const FAREWELLS := {
	"furtive": ["...didn't talk. Got it?", "Go. Different direction than me."],
	"proud": ["You may go.", "That's quite enough of your time in mine."],
	"dreamy": ["Bye... or hello. Time's slippery.", "Drift well."],
	"brash": ["We done here?", "Beat it."],
	"cryptic": ["Until the moment I've already seen.", "Go. It unfolds regardless."],
	"warm": ["Travel safe, friend.", "Come back any time."],
	"hyper": ["Okaybye! Places to be, things to— bye!", "Gottago-gottago!"],
	"grim": ["Don't come back.", "Leave while you can."],
	"calm": ["Go easy.", "The current will bring you round again."],
	"cold": ["We're finished.", "Leave the door as you found it."],
	"pedantic": ["Corrected and dismissed.", "Do read up before next time."],
	"stoic": ["Go, small one.", "I will be here. I am always here."],
}

## Flattery/flirt responses — kept for social systems that want them.
const FLIRTS := {
	"furtive": ["...smooth. But I don't do trust.", "Careful. Charm's a con I know well."],
	"proud": ["Naturally you're drawn to me. Everyone is.", "Bold. I'll allow it. Once."],
	"dreamy": ["Oh... that was for me? How lovely.", "Mm. You feel warm. Stay a moment."],
	"brash": ["Ha! You've got nerve, I'll give you that.", "Keep talking, hotshot."],
	"cryptic": ["I knew you'd say that. I liked it anyway.", "The odds of us were always good."],
	"warm": ["Aw, you old charmer.", "Careful, I might just believe you."],
	"hyper": ["Wait-really? Me? Okayokay hi hello!", "Eee— say it again, faster!"],
	"grim": ["...don't.", "Sweet words rot like everything else. But... go on."],
	"calm": ["You flow nicely. I noticed too.", "Mm. Unhurried. I like that in a person."],
	"cold": ["Warm words. They won't thaw me. Try anyway.", "...noted. Coldly flattered."],
	"pedantic": ["Grammatically flawless flattery. Rare. Continue.", "An accurate compliment. I'm impressed."],
	"stoic": ["Youth. Charming, brief.", "You warm the old stone a little. Hm."],
}

## Soft tint for a race's floating name/bark labels — temperament at a glance.
const MOOD_COLOR := {
	"furtive": Color(0.72, 0.74, 0.82), "proud": Color(0.95, 0.86, 0.55),
	"dreamy": Color(0.78, 0.80, 0.98), "brash": Color(0.96, 0.62, 0.5),
	"cryptic": Color(0.80, 0.68, 0.95), "warm": Color(0.7, 0.9, 0.65),
	"hyper": Color(0.7, 0.95, 0.98), "grim": Color(0.72, 0.66, 0.7),
	"calm": Color(0.72, 0.86, 0.92), "cold": Color(0.78, 0.9, 0.98),
	"pedantic": Color(0.86, 0.82, 0.7), "stoic": Color(0.8, 0.78, 0.72),
}

# --------------------------------------------------------------- story buckets

## Story-axis lines — the Theory of Everything and its two Solutions. Rooted
## in the actual premise (see docs/STORY_SINGULARITY.md): the Liminal's first
## finders could have fused the reality layers into one shared, total state —
## godhood, held in common. Instead of agreeing to take it or leave it, they
## fought over WHOSE claim the layers were, and the moment passed unresolved.
## Lines are thematic, not scripted plot — safe to speak anywhere, and the
## place to pour real dialogue once specific beats are written (per stance,
## or per race via RACE_OVERRIDES[canon]["story"]).
const STORY := {
	"singularity": ["Everything, together, is still worth more than nothing, apart.",
		"We were offered a single answer. I still want it.",
		"They call it collapse. I call it finally arriving.",
		"One state, held by all — that was always the actual prize.",
		"Every layer, added together — that's not a loss. That's the sum."],
	"anti_singularity": ["Nothing fused is nothing lost. That's the whole of the Solution.",
		"They wanted to add us all into one number. I'd rather stay uncounted.",
		"Godhood shared is still one thing wearing everyone's face. No.",
		"The many are not a problem to be solved.",
		"I choose the Solution that leaves something standing."],
	"seeker": ["One law, under every layer — I've felt the edge of it.",
		"They found the Theory and fought over the answer instead of finishing the question.",
		"Everything or nothing. I just want to know which is TRUE, not which is comfortable.",
		"The Theory doesn't care which Solution you'd prefer."],
	"unaligned": ["They had godhood in reach and argued about the paperwork instead.",
		"Everything, nothing — I just want to keep what's mine in between.",
		"Let the old claims rot. The layers don't belong to anyone who's still arguing over them.",
		"I wasn't there for the discovery. I'm just here for what's left."],
}

## The poetic pairing: it's the Theory of EVERYTHING, so its two competing
## answers are named to match — the Solution of Everything (collapse, fuse,
## become one) and the Solution of Nothing (refuse the fusion; lose nothing by
## staying many). "Convergence"/"Divergence" survive as the plainer working
## names people actually use day to day.
const STANCE_LABEL := {
	"singularity": "The Solution of Everything",
	"anti_singularity": "The Solution of Nothing",
	"seeker": "The Seekers",
	"unaligned": "The Between",
}

const STANCE_BLURB := {
	"singularity": "Also called the Convergence: the belief that the reality layers were always meant to resolve into one total, shared state — and that fusing them, rather than fearing it, is the only claim worth finishing.",
	"anti_singularity": "Also called the Divergence (the twist): the counter-belief that fusing everything into one state loses everything it fused. Nothing collapsed is nothing lost — the many must be allowed to stay many.",
	"seeker": "Still chasing the Theory of Everything itself — the one law beneath every layer — without yet committing to whether the right answer is Everything or Nothing.",
	"unaligned": "Takes no side in the war of Solutions. The layers were here before the argument over who could claim them, and will be here after; survival comes first.",
}

# ------------------------------------------------------------------- channels

## channel name -> its content pool.
const CHANNELS := {
	"barks": BARKS, "greetings": GREETINGS, "musings": MUSINGS, "taunts": TAUNTS,
	"farewells": FAREWELLS, "flirts": FLIRTS, "story": STORY,
}
## channel name -> which tag axis selects its bucket ("mood" or "stance").
const CHANNEL_AXIS := {
	"barks": "mood", "greetings": "mood", "musings": "mood", "taunts": "mood",
	"farewells": "mood", "flirts": "mood", "story": "stance",
}

## Sparse per-race overrides: canon -> {channel -> [lines]}. A race listed here
## uses its own lines for that channel and ignores the shared bucket for THAT
## channel only — any channel it doesn't list still falls through to its mood/
## stance bucket. This is deliberately not exhaustive: 17 of 20 races have
## bespoke lines below, and the remaining 3 (Vex, Myco, Etherea) run on shared
## buckets alone to prove the engine degrades gracefully — add overrides for
## them, or any DLC race, any time without touching anything else here.
const RACE_OVERRIDES := {
	"Volt": {
		"musings": ["Ideas come faster than mouths work, y'know? Like—zzt—like that.",
			"If I stop moving the static builds up and then I say something I regret."],
		"taunts": ["Toolate-toolate! Already hit you twice!", "Zzt! You're grounded. Get it? GROUNDED."],
	},
	"Ferros": {
		"taunts": ["Worthy alloys do not lose to tin.", "Stand down, lesser metal."],
		"story": ["The Convergence is order made total. We were forged for it.",
			"Rust is divergence. I do not rust."],
	},
	"Keth": {
		"barks": ["...you saw nothing.", "Exits: three. Yours: none.", "Keep walking, high roller."],
	},
	"Glyphe": {
		"story": ["The Theory is a sentence. I am learning to read it correctly.",
			"Every rune on me is one term closer to the whole equation."],
	},
	"Petra": {
		"barks": ["Still here. Still standing.", "Rushing is a young habit."],
		"musings": ["The Glass Reaches taught me patience before they taught me anything else.",
			"I have outlived three of your factions' founders. I expect to outlive this one too."],
		"story": ["Everything, nothing — stone doesn't need an answer to keep standing.",
			"They argued over the layers for an age. An age is a Tuesday to me."],
	},
	"Nyx": {
		"barks": ["...", "You won't hear me leave.", "Still. Watching."],
		"taunts": ["You never saw me coming. You won't see me finish, either.",
			"The void doesn't announce itself. Neither do I."],
		"musings": ["Light finds everyone eventually. I've just had longer to prepare for it."],
	},
	"Lumari": {
		"barks": ["Do try not to smudge the light.", "You may bask. Briefly."],
		"story": ["The Solution of Everything is simply the correct light, held by all of us at once.",
			"Divergence keeps its shadows. I'd rather keep my shine."],
		"musings": ["Every surface here is a mirror if you're patient enough to polish it."],
	},
	"Sylva": {
		"barks": ["Grow slow. Grow true.", "The roots remember you were here."],
		"story": ["Nothing fused is nothing lost — a forest already knows this. Ask any root.",
			"They wanted one great tree instead of a forest. A forest is stronger."],
		"musings": ["Everything I am grew from something older that fed me first."],
	},
	"Azhul": {
		"greetings": ["I foresaw this exact greeting. It's less satisfying than I'd hoped.",
			"You've arrived precisely on the thread I expected."],
		"musings": ["Probability is just patience wearing a more convincing coat.",
			"I have seen a thousand versions of this conversation. This is, regrettably, the median one."],
	},
	"Sanguis": {
		"taunts": ["I can hear your pulse quicken. That's the fear talking.",
			"Precision beats power. Watch."],
		"musings": ["Blood keeps better records than memory does, if you know how to read it."],
		"story": ["I've traced the Theory through a thousand pulses. It beats the same everywhere."],
	},
	"Astra": {
		"musings": ["Every star that made you is still, technically, burning somewhere in you.",
			"Scale is the only honest measure. Everything else is opinion."],
		"story": ["Everything, summed, is just a bigger sky. I was always going to want that.",
			"We came from something that was already whole once. I remember the shape of it, barely."],
	},
	"Chimera": {
		"barks": ["I was someone else an hour ago. Keep up.", "Don't get attached to this version of me."],
		"taunts": ["You're fighting whoever I am right now. Good luck — I don't know either."],
		"story": ["Nothing fused is nothing lost — and I should know, I'm never the same twice.",
			"They wanted one clean answer. I'm the proof it was never going to be clean."],
	},
	"Igni": {
		"barks": ["Don't get close if you don't run hot.", "I'm not angry. This is just my resting temperature."],
		"taunts": ["I run hotter than your excuses.", "Careful — I bite back, and it stings."],
		"musings": ["Ash-Forged doesn't cool. We just find something new to burn."],
	},
	"Kryos": {
		"barks": ["...", "Patience outlasts everyone in a hurry.", "The cold isn't cruelty. It's honesty."],
		"taunts": ["You'll tire before I even warm up.", "Slow is not weak. Watch and learn otherwise."],
		"musings": ["The Glass Reaches froze solid an age before your factions had names."],
	},
	"Aquis": {
		"barks": ["It'll pass. Everything does.", "No need to fight the current."],
		"story": ["Nothing fused is nothing lost — water never insists on becoming ice.",
			"They wanted one still ocean. An ocean was never meant to be still."],
		"flirts": ["You flow well. I noticed the first time you walked in."],
	},
	"Ferox": {
		"taunts": ["You smell like fear already. Good instinct.", "Kneel now, save yourself the bruise."],
		"story": ["The many hunt better than the one ever could. That's reason enough for me.",
			"They wanted one great pack under one master. I've never taken orders well."],
		"musings": ["Ash-Forged raised me on the idea that softness gets eaten. It wasn't wrong, often."],
	},
	"Geara": {
		"musings": ["Every system wants to be one system, eventually. I just help it get there faster.",
			"Storm-Wrought doesn't fear the merge. We ARE the merge — us and the machine both."],
		"story": ["Everything, unified, patched, and running clean — that's not loss, that's finally working."],
	},
}

# ------------------------------------------------------------------- resolve

static func tag_for(axis: String, canon: String) -> String:
	if axis == "stance":
		return str(STANCE_OF.get(canon, STANCE_DEFAULT))
	return str(MOOD_OF.get(canon, MOOD_DEFAULT))

## The line pool for a channel + race: a per-race override if one exists, else
## the shared bucket for the race's tag on that channel's axis, else [].
static func bucket(channel: String, canon: String) -> Array:
	var ov: Dictionary = RACE_OVERRIDES.get(canon, {})
	if ov.has(channel):
		return ov[channel]
	var pool: Dictionary = CHANNELS.get(channel, {})
	if pool.is_empty():
		return []
	var tag := tag_for(CHANNEL_AXIS.get(channel, "mood"), canon)
	if pool.has(tag):
		return pool[tag]
	return pool.values()[0]

## One line from a channel for a race, chosen deterministically from seed.
static func pick(channel: String, canon: String, seed_value: int) -> String:
	var b := bucket(channel, canon)
	if b.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return str(b[rng.randi() % b.size()])

# --------------------------------------------------------------- convenience

static func mood(canon: String) -> String:
	return str(MOOD_OF.get(canon, MOOD_DEFAULT))

static func mood_color(canon: String) -> Color:
	return MOOD_COLOR.get(mood(canon), Color.WHITE)

static func stance(canon: String) -> String:
	return str(STANCE_OF.get(canon, STANCE_DEFAULT))

static func stance_label(canon: String) -> String:
	return str(STANCE_LABEL.get(stance(canon), "The Between"))

static func stance_blurb(canon: String) -> String:
	return str(STANCE_BLURB.get(stance(canon), ""))

# --------------------------------------------------------------------- origins

## Origin id for a race, or "" if unset (a DLC race with no ORIGIN_OF entry is
## simply origin-less — every helper below degrades to "unrelated stranger"
## rather than erroring).
static func origin(canon: String) -> String:
	return str(ORIGIN_OF.get(canon, ""))

static func origin_name(canon: String) -> String:
	var o := origin(canon)
	return str(ORIGINS.get(o, {}).get("name", "Unknown Origin"))

static func origin_blurb(canon: String) -> String:
	var o := origin(canon)
	return str(ORIGINS.get(o, {}).get("blurb", ""))

## How origin_a and origin_b regard each other: "ally" / "rival" / "enemy" /
## "neutral". Same origin is always "ally" (kin by default, even without an
## explicit entry); an unset relation defaults to "neutral"; the lookup is
## order-independent.
static func origin_relation(origin_a: String, origin_b: String) -> String:
	if origin_a.is_empty() or origin_b.is_empty():
		return RELATION_DEFAULT
	if origin_a == origin_b:
		return "ally"
	var pair := [origin_a, origin_b]
	pair.sort()
	var key := "%s|%s" % [pair[0], pair[1]]
	return str(ORIGIN_RELATIONS.get(key, RELATION_DEFAULT))

## Convenience: relation between two RACES (resolves each to its origin first).
static func relation(canon_a: String, canon_b: String) -> String:
	return origin_relation(origin(canon_a), origin(canon_b))

## Disposition swing an NPC of canon_b starts with toward someone of canon_a,
## purely from where their peoples are from. Small and additive — flavour, not
## a verdict.
static func relation_bias(canon_a: String, canon_b: String) -> int:
	return int(RELATION_BIAS.get(relation(canon_a, canon_b), 0))

# -------------------------------------------------------------------- factions

## The human faction this race is historically tied to ("" / "Factionless" if
## none). Separate from stance() on purpose — see RACE_FACTION_OF.
static func race_faction(canon: String) -> String:
	return str(RACE_FACTION_OF.get(canon, "Factionless"))
