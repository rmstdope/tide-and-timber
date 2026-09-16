class_name DeviceTracker
extends RefCounted
## Which device the hints follow: the one pressed last. No nodes; InputDevice feeds it.

signal changed

enum Kind { KEYBOARD, XBOX, PLAYSTATION, NINTENDO }

const DEAD_ZONE := 0.2   # the move actions' deadzone in project.godot
const PLAYSTATION_WORDS := ["playstation", "ps3", "ps4", "ps5", "dualshock", "dualsense", "sony"]
const NINTENDO_WORDS := ["nintendo", "switch", "joy-con", "joycon"]

var kind: Kind = Kind.KEYBOARD
var settled := false   # true after the first counted press, or after the last pad unplugs
var _last_pad := -1    # device id of the pad kind came from; -1 for none

## pad_names: names of the pads connected at launch, in Input.get_connected_joypads() order.
func _init(pad_names: PackedStringArray = PackedStringArray()) -> void:
	if not pad_names.is_empty():
		kind = family_of(pad_names[0])

## The family a pad's name belongs to. Unknown and "" are XBOX.
static func family_of(pad_name: String) -> Kind:
	var lower := pad_name.to_lower()
	for word: String in PLAYSTATION_WORDS:
		if lower.contains(word):
			return Kind.PLAYSTATION
	for word: String in NINTENDO_WORDS:
		if lower.contains(word):
			return Kind.NINTENDO
	return Kind.XBOX

## Counts one input event. pad_name is Input.get_joy_name(event.device) for pad events, else "".
func observe(event: InputEvent, pad_name: String = "") -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			_press(Kind.KEYBOARD)
	elif event is InputEventMouseButton:
		if event.pressed:
			_press(Kind.KEYBOARD)
	elif event is InputEventJoypadButton:
		if event.pressed:
			_press_pad(event.device, pad_name)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= DEAD_ZONE:
			_press_pad(event.device, pad_name)

func pad_connected(device: int, pad_name: String) -> void:
	if not settled and kind == Kind.KEYBOARD:
		_last_pad = device
		_go(family_of(pad_name))

## remaining: names of the pads still connected, not including device.
func pad_disconnected(device: int, remaining: PackedStringArray) -> void:
	if remaining.is_empty():
		settled = true
		_last_pad = -1
		_go(Kind.KEYBOARD)
	elif kind != Kind.KEYBOARD and (device == _last_pad or not settled):
		_last_pad = -1
		_go(family_of(remaining[0]))

func _press(to: Kind) -> void:
	settled = true
	_go(to)

func _press_pad(device: int, pad_name: String) -> void:
	_last_pad = device
	_press(family_of(pad_name))

func _go(to: Kind) -> void:
	if to != kind:
		kind = to
		changed.emit()
