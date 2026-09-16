class_name BuildSound
extends AudioStreamPlayer
## Knocks of wood on wood during the build's black, generated: no audio file to license.

const MIX_RATE := 22050.0
const KNOCK_SECONDS := 0.55
const KNOCK_DECAY := 40.0
const GAIN := 0.8

var audible := false                    # what set_audible last set
var _t := 0.0

static func knock(t: float) -> float:
	return exp(-fposmod(t, KNOCK_SECONDS) * KNOCK_DECAY)

func set_audible(on: bool) -> void:
	audible = on
	if on:
		_t = 0.0
	if on and not playing:
		play()
	stream_paused = not on

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.25
	stream = generator

func _process(_delta: float) -> void:
	if not playing or stream_paused:
		return
	var playback := get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	for i in playback.get_frames_available():
		var s := clampf(randf_range(-1.0, 1.0) * knock(_t) * GAIN, -1.0, 1.0)
		playback.push_frame(Vector2(s, s))
		_t += 1.0 / MIX_RATE
