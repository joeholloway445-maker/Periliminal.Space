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

## Where each race stands in the Theory-of-Everything conflict — the story
## axis (see docs/STORY_SINGULARITY.md). PROVISIONAL and fully overridable:
## these are sensible defaults derived from each race's element, not fixed
## canon. Change any assignment freely; nothing downstream hard-codes it.
const STANCE_OF := {
	# The Convergence — reality resolves to one point; embrace the collapse.
	"Geara": "singularity", "Volt": "singularity", "Ferros": "singularity", "Myco": "singularity",
	# The Divergence (the twist) — the many must stay many; resist the one.
	"Sylva": "anti_singularity", "Aquis": "anti_singularity", "Ferox": "anti_singularity", "Chimera": "anti_singularity",
	# The Seekers — chase the Theory of Everything for its own sake.
	"Azhul": "seeker", "Glyphe": "seeker", "Astra": "seeker", "Lumari": "seeker", "Sanguis": "seeker",
	# The Between — no stake in the war of theories; just survive the layers.
	"Keth": "unaligned", "Nyx": "unaligned", "Vex": "unaligned", "Etherea": "unaligned",
	"Kryos": "unaligned", "Igni": "unaligned", "Petra": "unaligned",
}

const MOOD_DEFAULT := "calm"
const STANCE_DEFAULT := "unaligned"

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

## Story-axis lines. Deliberately THEMATIC, not plot — safe to speak anywhere,
## and the place to pour the real narrative once it's set (per stance, or per
## race via RACE_OVERRIDES["Keth"]["story"]). This is the twist's plug-in point.
const STORY := {
	"singularity": ["All roads run to the one point.", "Separation is a rounding error.",
		"We are converging. Can't you feel it pulling?", "One equation, and then peace."],
	"anti_singularity": ["Not everything should become one.", "The many must stay many.",
		"Collapse isn't unity — it's just an ending.", "I will not be summed."],
	"seeker": ["The Theory holds — one law under all of it.", "Every layer is a term in the same equation.",
		"Solve it, and you'd see the whole shape at once.", "So close to the form of everything."],
	"unaligned": ["Theories rise and set. The layers remain.", "Let them argue over the one point.",
		"Singularity, anti — same weather to me.", "I just want out of the Liminal in one piece."],
}

const STANCE_LABEL := {
	"singularity": "The Convergence",
	"anti_singularity": "The Divergence",
	"seeker": "The Seekers",
	"unaligned": "The Between",
}

const STANCE_BLURB := {
	"singularity": "Holds that all of reality is resolving toward a single point — the Singularity — and that this collapse into one is to be sought, not feared.",
	"anti_singularity": "The counter-movement (the twist): that the many must remain many. To be summed into one point is not unity but an ending, and the Divergence exists to prevent it.",
	"seeker": "Chases the Theory of Everything for its own sake — one law beneath every layer — without yet committing to what should be DONE once it's found.",
	"unaligned": "Takes no side in the war of theories. The layers were here before the argument and will outlast it; survival comes first.",
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
## uses its own lines for that channel and ignores the shared bucket. Marquee
## examples — extend freely; unlisted races just use the shared pools.
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
