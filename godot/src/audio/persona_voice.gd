class_name PersonaVoice
extends AudioStreamPlayer
## An asset-free "chittering" dialogue voice — the Animal-Crossing / Undertale
## trick: a tiny synthesized blip retriggered as text types out, pitched and
## paced per race so a Petra rumbles low and slow while a Volt chatters high
## and fast. No voice files to record or ship; the waveform is generated in
## code from the race's RacePersona.voice() params.
##
## Usage:
##   var v := PersonaVoice.new(); add_child(v)
##   v.configure(RacePersona.voice(canon))
##   v.start_speaking(char_count, reveal_duration)   # while typewriter runs
##   v.blip()                                         # or one tick, instantly

var _base_pitch := 1.0
var _rasp := 0.2
var _cadence := "even"

var _speaking := false
var _time_left := 0.0
var _accum := 0.0

func _ready() -> void:
	if stream == null:
		stream = _make_blip(_rasp)
	volume_db = -9.0
	set_process(true)

## Take a RacePersona.voice() dict: pitch, rasp, cadence. Regenerates the
## waveform so rasp actually changes the timbre, not just the pitch.
func configure(voice: Dictionary) -> void:
	_base_pitch = float(voice.get("pitch", 1.0))
	_rasp = clampf(float(voice.get("rasp", 0.2)), 0.0, 1.0)
	_cadence = str(voice.get("cadence", "even"))
	stream = _make_blip(_rasp)

## Blip repeatedly across `duration` seconds while `char_count` characters
## reveal, so the voice runs exactly as long as the line is typing.
func start_speaking(char_count: int, duration: float) -> void:
	if char_count <= 1 or duration <= 0.0:
		return
	_speaking = true
	_time_left = duration
	_accum = 0.0

func stop_speaking() -> void:
	_speaking = false

## A single immediate tick (used when the typewriter is off).
func blip() -> void:
	var j := _jitter()
	pitch_scale = _base_pitch * randf_range(1.0 - j * 0.18, 1.0 + j * 0.18)
	play()

func _process(delta: float) -> void:
	if not _speaking:
		return
	_time_left -= delta
	_accum -= delta
	if _accum <= 0.0:
		_accum = _interval() * randf_range(0.85, 1.15 + _jitter())
		blip()
	if _time_left <= 0.0:
		_speaking = false

## Seconds between blips — fast, clipped voices tick quicker than languid ones.
func _interval() -> float:
	match _cadence:
		"staccato", "rapid", "hot", "erratic", "clipped":
			return 0.034
		"glacial", "slow", "grand", "airy", "murmuring", "trailing", "flowing":
			return 0.072
		_:
			return 0.05

## Extra pitch/timing randomness — erratic/hot voices wobble, precise ones don't.
func _jitter() -> float:
	match _cadence:
		"erratic", "hot", "staccato":
			return 0.5
		"precise", "clipped", "glacial", "deliberate":
			return 0.08
		_:
			return 0.22

## A short decaying tone synthesized to 16-bit PCM. Higher rasp lowers the
## fundamental and blends in noise for a rougher, growlier blip.
static func _make_blip(rasp: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var dur := 0.055
	var n := int(wav.mix_rate * dur)
	var freq := lerpf(360.0, 235.0, clampf(rasp, 0.0, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x8AC3
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(wav.mix_rate)
		var env := exp(-t * 40.0)
		var s := sin(TAU * freq * t)
		# Fold in a touch of noise for rasp so the timbre roughens, not just drops.
		s = lerpf(s, (rng.randf() * 2.0 - 1.0), rasp * 0.35)
		data.encode_s16(i * 2, int(clampf(s * env, -1.0, 1.0) * 32767.0))
	wav.data = data
	return wav
