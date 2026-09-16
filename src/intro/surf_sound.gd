class_name SurfSound
extends AudioStreamPlayer
## The sound of waves, generated as low-passed noise under a slow swell: no audio file to license.

const MIX_RATE := 22050.0
const SWELL_SECONDS := 6.0
const LOWPASS := 0.08
const GAIN := 3.0

var audible := false                    # what set_audible last set
var _lp := 0.0
var _t := 0.0

static func swell(t: float) -> float:
	return 0.15 + 0.35 * (0.5 - 0.5 * cos(TAU * t / SWELL_SECONDS))

func set_audible(on: bool) -> void:
	audible = on
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
		_lp += LOWPASS * (randf_range(-1.0, 1.0) - _lp)
		var s := clampf(_lp * GAIN * swell(_t), -1.0, 1.0)
		playback.push_frame(Vector2(s, s))
		_t += 1.0 / MIX_RATE
