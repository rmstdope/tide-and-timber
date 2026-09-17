class_name Collapse
extends RefCounted
## The collapse and the morning after, in real seconds: fall, fade to black, line on black, fade up, get up.

signal went_black      ## once, entering BLACK: the night is spent here, unseen
signal morning         ## once, entering FADING_IN: the card starts
signal got_up          ## once, entering DONE: control returns

enum Phase { FALLING, FADING_OUT, BLACK, FADING_IN, PUSHING_UP, SITTING, DONE }

const FALL_SECONDS := 2.0
const SWAY_SECONDS := 0.6        # standing, swaying
const SWAY_STEP_SECONDS := 0.15  # the sway flips side this often
const FADE_OUT_SECONDS := 0.5
const BLACK_SECONDS := 3.0
const LINE_FADE_SECONDS := 0.5   # his line fades in and out inside BLACK

var phase: Phase = Phase.FALLING
var phase_elapsed := 0.0

func advance(real_seconds: float) -> void:
	if phase == Phase.DONE:
		return
	phase_elapsed += real_seconds
	while phase != Phase.DONE and phase_elapsed >= _duration(phase):
		phase_elapsed -= _duration(phase)
		phase = (phase + 1) as Phase
		match phase:
			Phase.BLACK:
				went_black.emit()
			Phase.FADING_IN:
				morning.emit()
			Phase.DONE:
				phase_elapsed = 0.0
				got_up.emit()

func cover_alpha() -> float:
	match phase:
		Phase.FADING_OUT:
			return clampf(phase_elapsed / FADE_OUT_SECONDS, 0.0, 1.0)
		Phase.BLACK:
			return 1.0
		Phase.FADING_IN:
			return 1.0 - clampf(phase_elapsed / WakeUp.FADE_IN_SECONDS, 0.0, 1.0)
	return 0.0

func line_alpha() -> float:
	if phase != Phase.BLACK:
		return 0.0
	var e := phase_elapsed
	return clampf(minf(e / LINE_FADE_SECONDS, (BLACK_SECONDS - e) / LINE_FADE_SECONDS), 0.0, 1.0)

## The frame of the fall to hold now, or -1 once he is up. The whole of FALL_SECONDS carries the
## eight frames: the sheet's first three are the upright figure, so they are the sway, and the sheet
## itself says when he kneels.
func fall_frame() -> int:
	match phase:
		Phase.FALLING:
			return WakeUp.step_of(phase_elapsed, FALL_SECONDS)
		Phase.FADING_OUT, Phase.BLACK, Phase.FADING_IN:
			return WakeUp.FALL_FRAMES - 1
		Phase.PUSHING_UP:
			return WakeUp.getting_up_frame(phase_elapsed)
		Phase.SITTING:
			return WakeUp.getting_up_frame(WakeUp.PUSH_UP_SECONDS + phase_elapsed)
	return -1

func sway_x() -> float:
	if phase == Phase.FALLING and phase_elapsed < SWAY_SECONDS:
		return 1.0 if fposmod(phase_elapsed, 2 * SWAY_STEP_SECONDS) < SWAY_STEP_SECONDS else -1.0
	return 0.0

static func _duration(p: Phase) -> float:
	match p:
		Phase.FALLING:
			return FALL_SECONDS
		Phase.FADING_OUT:
			return FADE_OUT_SECONDS
		Phase.BLACK:
			return BLACK_SECONDS
		Phase.FADING_IN:
			return WakeUp.FADE_IN_SECONDS
		Phase.PUSHING_UP:
			return WakeUp.PUSH_UP_SECONDS
	return WakeUp.SIT_SECONDS
