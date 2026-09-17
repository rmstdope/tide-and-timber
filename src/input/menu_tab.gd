class_name MenuTab
extends RefCounted
## Which way a menu_tab press turns: the action is one for Q, E, LB and RB, so the direction comes from the event.

## -1 for Q or the left shoulder, 1 for E or the right shoulder, 0 for anything else.
static func step(event: InputEvent) -> int:
	var key := event as InputEventKey
	if key != null:
		match key.physical_keycode:
			KEY_Q:
				return -1
			KEY_E:
				return 1
		return 0
	var button := event as InputEventJoypadButton
	if button != null:
		match button.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				return -1
			JOY_BUTTON_RIGHT_SHOULDER:
				return 1
	return 0
