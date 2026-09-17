class_name KeyLabels
extends RefCounted
## The one place a key becomes a label: a short name for a long key, else the character printed on it.

const _FIXED := {KEY_BACKSPACE: "Bksp", KEY_PAGEUP: "PgUp", KEY_PAGEDOWN: "PgDn", KEY_INSERT: "Ins",
	KEY_DELETE: "Del", KEY_HOME: "Home", KEY_END: "End", KEY_SPACE: "Space", KEY_TAB: "Tab", KEY_CAPSLOCK: "Caps",
	KEY_ENTER: "Enter", KEY_KP_ENTER: "Enter", KEY_ESCAPE: "Esc", KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←",
	KEY_RIGHT: "→", KEY_KP_MULTIPLY: "Num *", KEY_KP_DIVIDE: "Num /", KEY_KP_SUBTRACT: "Num -", KEY_KP_ADD: "Num +",
	KEY_KP_PERIOD: "Num ."}
const _SIDED := {KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_ALT: "Alt"}

static func label(key: InputEventKey) -> String:
	var code := key.physical_keycode
	if _FIXED.has(code):
		return _FIXED[code]
	if _SIDED.has(code):
		var side := {KEY_LOCATION_LEFT: "L", KEY_LOCATION_RIGHT: "R"}.get(key.location, "") as String
		return side + _SIDED[code]
	if code >= KEY_KP_0 and code <= KEY_KP_9:
		return "Num %d" % (code - KEY_KP_0)
	if code >= KEY_F1 and code <= KEY_F12:
		return "F%d" % (code - KEY_F1 + 1)
	var c: int = code
	if DisplayServer.get_name() != "headless":
		var printed := DisplayServer.keyboard_get_label_from_physical(code)
		if printed != 0:
			c = printed
	if c >= 33 and c <= 126:
		return char(c).to_upper()
	return OS.get_keycode_string(code)
