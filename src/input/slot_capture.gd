class_name SlotCapture
extends RefCounted
## The waiting box's rules, with no nodes: which raw event goes into a slot, and hold-to-cancel.
## The page feeds it every event and every frame's delta while the box is up.

enum Result { WAITING, TAKEN, CANCELLED }

const HOLD_SECONDS := IntroStory.HOLD_SECONDS   # the ring fills in this long
const DEAD_ZONE := DeviceTracker.DEAD_ZONE      # a stick or trigger counts past this

var is_open := false
var device: Controls.Device = Controls.Device.KEYBOARD
var hold_progress := 0.0        # 0..1 while Esc (keyboard) or B (controller) is held
var taken: InputEvent = null    # the event that went in; null after a cancel
var mac := OS.get_name() == "macOS"   # off macOS a lone Alt is taken on release, so Alt+Enter never goes in

var _holding := false
var _alt_pending := false                 # off macOS: Alt is down and may yet start the fullscreen shortcut
var _unarmed: Array[Vector2i] = []        # (axis, sign) held when the box opened, until back inside DEAD_ZONE
var _draining := Vector2i(-1, -1)         # (pad device, axis) of a taken stick, until back inside DEAD_ZONE

## Starts waiting for this tab's device. held: Vector2i(axis, sign) already past DEAD_ZONE on any pad.
func open(p_device: Controls.Device, held: Array[Vector2i] = []) -> void:
	is_open = true
	device = p_device
	hold_progress = 0.0
	taken = null
	_holding = false
	_alt_pending = false
	_unarmed = held.duplicate()
	_draining = Vector2i(-1, -1)

## One raw event. TAKEN sets `taken` and closes; otherwise WAITING. Never CANCELLED.
func read(event: InputEvent) -> Result:
	if not is_open:
		return Result.WAITING
	if device == Controls.Device.KEYBOARD:
		return _read_key(event as InputEventKey) if event is InputEventKey else Result.WAITING
	if event is InputEventJoypadButton:
		return _read_button(event as InputEventJoypadButton)
	if event is InputEventJoypadMotion:
		return _read_motion(event as InputEventJoypadMotion)
	return Result.WAITING

## One frame. CANCELLED (and closed) when the hold reaches HOLD_SECONDS; otherwise WAITING.
func advance(delta: float) -> Result:
	if not is_open or not _holding:
		return Result.WAITING
	hold_progress = minf(1.0, hold_progress + delta / HOLD_SECONDS)
	if hold_progress < 1.0:
		return Result.WAITING
	close()
	return Result.CANCELLED

## Stops waiting with nothing taken (a pad unplugged).
func close() -> void:
	is_open = false
	_holding = false
	_alt_pending = false
	hold_progress = 0.0
	taken = null

## After a stick or trigger was taken: true for that pad axis's motion until it is back inside DEAD_ZONE.
func swallows(event: InputEvent) -> bool:
	var m := event as InputEventJoypadMotion
	if _draining.x < 0 or m == null or m.device != _draining.x or m.axis != _draining.y:
		return false
	if absf(m.axis_value) < DEAD_ZONE:
		_draining = Vector2i(-1, -1)
	return true

## Every Vector2i(axis, sign) past DEAD_ZONE on a connected pad right now.
static func held_axes_now() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for d in Input.get_connected_joypads():
		for axis in range(JOY_AXIS_MAX):
			var v := Input.get_joy_axis(d, axis as JoyAxis)
			if absf(v) >= DEAD_ZONE:
				var held := Vector2i(axis, 1 if v > 0.0 else -1)
				if not result.has(held):
					result.append(held)
	return result

func _read_key(k: InputEventKey) -> Result:
	if k.physical_keycode == KEY_NONE:
		_alt_pending = false   # InputDevice blanked the fullscreen shortcut: its Alt is not a key to take
		return Result.WAITING
	if k.echo or k.physical_keycode == KEY_META:
		return Result.WAITING
	var alt := not mac and k.physical_keycode == WindowShortcut.modifier_key(false)
	if alt:
		if k.pressed:
			_alt_pending = true
			return Result.WAITING
		if _alt_pending:
			return _take(k)
		return Result.WAITING
	if k.pressed:
		if k.physical_keycode == KEY_ESCAPE:
			_start_hold()
			return Result.WAITING
		return _take(k)
	if k.physical_keycode == KEY_ESCAPE and _holding:
		return _take(k)
	return Result.WAITING

func _read_button(b: InputEventJoypadButton) -> Result:
	if b.pressed:
		if b.button_index == JOY_BUTTON_B:
			_start_hold()
			return Result.WAITING
		return _take(b)
	if b.button_index == JOY_BUTTON_B and _holding:
		return _take(b)
	return Result.WAITING

func _read_motion(m: InputEventJoypadMotion) -> Result:
	if absf(m.axis_value) < DEAD_ZONE:
		_unarmed.erase(Vector2i(m.axis, 1))
		_unarmed.erase(Vector2i(m.axis, -1))
		return Result.WAITING
	if _unarmed.has(Vector2i(m.axis, 1 if m.axis_value > 0.0 else -1)):
		return Result.WAITING
	_take(m)
	_draining = Vector2i(m.device, m.axis)
	return Result.TAKEN

func _start_hold() -> void:
	_holding = true
	hold_progress = 0.0

func _take(e: InputEvent) -> Result:
	taken = e
	is_open = false
	_holding = false
	_alt_pending = false
	hold_progress = 0.0
	return Result.TAKEN
