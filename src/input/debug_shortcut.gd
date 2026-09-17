class_name DebugShortcut
extends RefCounted
## Which debug shortcut a key event is: F1-F4 by physical key, pressed, not a repeat. Keyboard only.
## Raw key reads live under src/input (tests/input/gamepad_bindings_test.gd); DebugKeys acts on the result.

enum Name { NONE, READOUT, COLLISION_AREAS, SPEED, WALK_THROUGH }

const KEYS := {KEY_F1: Name.READOUT, KEY_F2: Name.COLLISION_AREAS, KEY_F3: Name.SPEED, KEY_F4: Name.WALK_THROUGH}

## The shortcut `event` presses; NONE for anything else, a release, or a held key's repeat.
static func of(event: InputEvent) -> Name:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return Name.NONE
	return KEYS.get(key.physical_keycode, Name.NONE)
