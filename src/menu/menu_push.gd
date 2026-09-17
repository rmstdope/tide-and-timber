class_name MenuPush
extends RefCounted
## One menu step per push: keys and pad buttons without echo, the stick once past PUSH until it
## comes back inside RELEASE. No nodes; the InputDevice autoload owns the live one.

enum Step { NONE, UP, DOWN, LEFT, RIGHT, SELECT, BACK }

const PUSH := 0.5      # a stick counts as a push at or past this tilt
const RELEASE := 0.3   # and is ready to push again once back at or inside this
const SLACK := 0.00001 # axis_value is stored as a 32-bit float: 0.3 comes back as 0.30000001
const ACTIONS := {     # checked in this order
	Step.UP: &"menu_up",
	Step.DOWN: &"menu_down",
	Step.LEFT: &"menu_left",
	Step.RIGHT: &"menu_right",
	Step.SELECT: &"menu_accept",
	Step.BACK: &"menu_cancel",
}

var _held: Dictionary = {}   # Vector2i(device, axis) -> 1 or -1: the direction pushed and not yet released

## The step this event makes. Stateful for stick motion; call it once per event.
func read(event: InputEvent) -> Step:
	var m := event as InputEventJoypadMotion
	if m == null:
		for step: Step in ACTIONS:
			if event.is_action_pressed(ACTIONS[step], false):
				return step
		return Step.NONE
	var key := Vector2i(m.device, m.axis)
	var v := m.axis_value
	if absf(v) <= RELEASE + SLACK:
		_held.erase(key)
		return Step.NONE
	if absf(v) < PUSH:
		return Step.NONE
	var dir := 1 if v > 0.0 else -1
	if _held.get(key, 0) == dir:
		return Step.NONE
	for step: Step in ACTIONS:
		if binds_axis(ACTIONS[step], m.axis, v > 0.0):
			_held[key] = dir
			return step
	return Step.NONE

## Whether action has this axis bound in this direction. Not InputMap.event_is_action: on 4.7 it matches either sign.
static func binds_axis(action: StringName, axis: JoyAxis, positive: bool) -> bool:
	for bound: InputEvent in InputMap.action_get_events(action):
		var b := bound as InputEventJoypadMotion
		if b and b.axis == axis and (b.axis_value > 0.0) == positive:
			return true
	return false
