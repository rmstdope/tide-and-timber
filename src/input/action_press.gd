class_name ActionPress
extends RefCounted
## One press and one release per push of a play action (use, build, pause): keys and pad buttons as
## Godot reports them, sticks and triggers by sign, pressed at MenuPush.PUSH and released at MenuPush.RELEASE.
## No nodes; the InputDevice autoload owns the live one and reads every event once.

var _held: Dictionary = {}          # Vector2i(device, axis) -> 1 or -1, pushed and not yet released
var _pressed := Vector2i.ZERO       # (axis, sign) this event pushed past PUSH; sign 0 = none
var _released := Vector2i.ZERO      # (axis, sign) this event let go of; sign 0 = none

## Works out what this event pushed and let go of. Stateful for motion; call it once per event.
func read(event: InputEvent) -> void:
	_pressed = Vector2i.ZERO
	_released = Vector2i.ZERO
	var m := event as InputEventJoypadMotion
	if m == null:
		return
	var key := Vector2i(m.device, m.axis)
	var v := m.axis_value
	var dir := 1 if v > 0.0 else -1
	var was: int = _held.get(key, 0)
	if absf(v) <= MenuPush.RELEASE + MenuPush.SLACK:
		if was != 0:
			_released = Vector2i(m.axis, was)
		_held.erase(key)
	elif absf(v) >= MenuPush.PUSH and was != dir:
		if was != 0:
			_released = Vector2i(m.axis, was)
		_pressed = Vector2i(m.axis, dir)
		_held[key] = dir

## Whether this event (the last one read) is a fresh press of action.
func pressed(event: InputEvent, action: StringName) -> bool:
	if not event is InputEventJoypadMotion:
		return event.is_action_pressed(action, false)
	return _pressed.y != 0 and MenuPush.binds_axis(action, _pressed.x as JoyAxis, _pressed.y > 0)

## Whether this event (the last one read) is the release of action.
func released(event: InputEvent, action: StringName) -> bool:
	if not event is InputEventJoypadMotion:
		return event.is_action_released(action)
	return _released.y != 0 and MenuPush.binds_axis(action, _released.x as JoyAxis, _released.y > 0)
