class_name BuildFade
extends RefCounted
## The build's black: fade out, hold, fade in, in real seconds.

signal went_black        # once, entering BLACK
signal black_ended       # once, leaving BLACK
signal finished          # once, entering DONE

enum Phase { FADING_OUT, BLACK, FADING_IN, DONE }
const FADE_OUT_SECONDS := 0.5
const BLACK_SECONDS := 5.0
const FADE_IN_SECONDS := 0.5

var phase: Phase = Phase.FADING_OUT
var phase_elapsed := 0.0

func advance(delta: float) -> void:
	if phase == Phase.DONE:
		return
	phase_elapsed += delta
	while phase != Phase.DONE and phase_elapsed >= _duration(phase):
		phase_elapsed -= _duration(phase)
		phase = (phase + 1) as Phase
		match phase:
			Phase.BLACK:
				went_black.emit()
			Phase.FADING_IN:
				black_ended.emit()
			Phase.DONE:
				phase_elapsed = 0.0
				finished.emit()

func cover_alpha() -> float:
	match phase:
		Phase.FADING_OUT:
			return clampf(phase_elapsed / FADE_OUT_SECONDS, 0.0, 1.0)
		Phase.BLACK:
			return 1.0
		Phase.FADING_IN:
			return 1.0 - clampf(phase_elapsed / FADE_IN_SECONDS, 0.0, 1.0)
	return 0.0

func _duration(p: Phase) -> float:
	match p:
		Phase.FADING_OUT:
			return FADE_OUT_SECONDS
		Phase.BLACK:
			return BLACK_SECONDS
	return FADE_IN_SECONDS
