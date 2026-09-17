class_name WakeUp
extends RefCounted
## The waking's rules, no nodes: the fade up from black, getting himself up, control, the move hint.

signal control_given                    # emitted exactly once, when phase becomes CONTROL

enum Phase { FADING_IN, LYING, PUSHING_UP, SITTING, CONTROL }

const FADE_IN_SECONDS := 1.0
const LIE_SECONDS := 2.0                # still, after the picture is fully up
const PUSH_UP_SECONDS := 0.4
const SIT_SECONDS := 0.8
const FALL_FRAMES := 8                  # the columns of assets/man/death.png
const HINT_WALK_PIXELS := 32.0          # "a few steps": two tiles
const HINT_FADE_SECONDS := 0.5

var phase: Phase = Phase.FADING_IN
var phase_elapsed := 0.0
var walked := 0.0                       # px walked since control; only counted in CONTROL
var hint_fade_elapsed := 0.0
var resumed := false
var resume_fade_elapsed := 0.0

## Straight to control with no story: the cover fades up over FADE_IN_SECONDS, no pose, no move hint.
## Does not emit control_given.
func resume() -> void:
	resumed = true
	phase = Phase.CONTROL
	phase_elapsed = 0.0
	resume_fade_elapsed = 0.0
	walked = HINT_WALK_PIXELS
	hint_fade_elapsed = HINT_FADE_SECONDS

func advance(delta: float) -> void:
	if resumed:
		resume_fade_elapsed = minf(FADE_IN_SECONDS, resume_fade_elapsed + delta)
	if phase == Phase.CONTROL:
		if walked >= HINT_WALK_PIXELS:
			hint_fade_elapsed = minf(HINT_FADE_SECONDS, hint_fade_elapsed + delta)
		return
	phase_elapsed += delta
	while phase != Phase.CONTROL and phase_elapsed >= _duration(phase):
		phase_elapsed -= _duration(phase)
		phase = (phase + 1) as Phase
		if phase == Phase.CONTROL:
			phase_elapsed = 0.0
			control_given.emit()

func add_walked(pixels: float) -> void:
	if phase == Phase.CONTROL:
		walked += pixels

func cover_alpha() -> float:
	if resumed:
		return 1.0 - resume_fade_elapsed / FADE_IN_SECONDS
	if phase == Phase.FADING_IN:
		return 1.0 - clampf(phase_elapsed / FADE_IN_SECONDS, 0.0, 1.0)
	return 0.0

func pose() -> StringName:
	match phase:
		Phase.FADING_IN, Phase.LYING:
			return &"lie"
		Phase.PUSHING_UP:
			return &"push_up"
		Phase.SITTING:
			return &"sit"
	return &""

func hint_alpha() -> float:
	if phase != Phase.CONTROL:
		return 0.0
	if walked < HINT_WALK_PIXELS:
		return 1.0
	return 1.0 - hint_fade_elapsed / HINT_FADE_SECONDS

static func _duration(p: Phase) -> float:
	match p:
		Phase.FADING_IN:
			return FADE_IN_SECONDS
		Phase.LYING:
			return LIE_SECONDS
		Phase.PUSHING_UP:
			return PUSH_UP_SECONDS
	return SIT_SECONDS
