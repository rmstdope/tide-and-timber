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
const EDGE := 1e-6                      # see getting_up_frame: float slack at a step boundary
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

## The frame of the fall for a getting-up that began `elapsed` seconds ago: the fall, backwards,
## over PUSH_UP_SECONDS + SIT_SECONDS. Collapse shares it, so the two mornings agree.
static func getting_up_frame(elapsed: float) -> int:
	var span := PUSH_UP_SECONDS + SIT_SECONDS
	# EDGE nudges a step boundary onto the step it belongs to: 0.6 / 1.2 * 8 is 3.99999 in floats,
	# which would hold a frame twice and drop another out of the eight.
	return clampi(FALL_FRAMES - 1 - int(elapsed / span * FALL_FRAMES + EDGE), 0, FALL_FRAMES - 1)

## The frame of the fall to hold now, or -1 when he is not in it and walking shows its own.
func fall_frame() -> int:
	match phase:
		Phase.FADING_IN, Phase.LYING:
			return FALL_FRAMES - 1
		Phase.PUSHING_UP:
			return getting_up_frame(phase_elapsed)
		Phase.SITTING:
			return getting_up_frame(PUSH_UP_SECONDS + phase_elapsed)
	return -1

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
