class_name WindowShortcut
extends RefCounted
## The fixed fullscreen shortcut: Cmd+Enter on macOS, Alt+Enter elsewhere. Not an action, never rebound.
## InputDevice reads every event through one of these, and blanks each event it swallows.

enum Result { NONE, TOGGLE, SWALLOW }

const ENTER_KEYS := [KEY_ENTER, KEY_KP_ENTER]   # by physical_keycode

var mac: bool                     # true: Cmd (meta) is the modifier; false: Alt

var _swallowing := false          # a swallowed Enter press whose release has not come yet

func _init(p_mac: bool = OS.get_name() == "macOS") -> void:
	mac = p_mac

## The modifier key for this platform: KEY_META on macOS, KEY_ALT elsewhere.
static func modifier_key(p_mac: bool) -> Key:
	return KEY_META if p_mac else KEY_ALT

## TOGGLE: a fresh (non-echo) press of either Enter key with this platform's modifier held.
## SWALLOW: any other Enter key event with the modifier held (an echo, or a release), or the
##          Enter echo or release that follows a press this object returned TOGGLE for, even once the modifier is up.
## NONE: everything else, including plain Enter and the other platform's modifier + Enter.
## Stateful for the release; call it once per event.
func read(event: InputEvent) -> Result:
	var k := event as InputEventKey
	if k == null or not k.physical_keycode in ENTER_KEYS:
		return Result.NONE
	var held := k.meta_pressed if mac else k.alt_pressed
	if k.pressed and not k.echo and held:
		_swallowing = true
		return Result.TOGGLE
	if _swallowing:
		_swallowing = k.pressed    # its echoes, then its release, even once the modifier is up
		return Result.SWALLOW
	return Result.SWALLOW if held else Result.NONE

## Makes a key event match no action or key: physical_keycode, keycode and key_label to KEY_NONE, unicode to 0.
static func blank(key: InputEventKey) -> void:
	key.physical_keycode = KEY_NONE
	key.keycode = KEY_NONE
	key.key_label = KEY_NONE
	key.unicode = 0
