class_name Controls
extends RefCounted
## The player's own keys and buttons for the eight play actions: two key slots and one pad slot each.
## No nodes; InputDevice owns the live one. Every change applies to the InputMap and saves at once.

signal changed   # after any mutation that changed something

enum Action { WALK_UP, WALK_DOWN, WALK_LEFT, WALK_RIGHT, RUN, USE, BUILD_LIST, PAUSE }   # list order
enum Device { KEYBOARD, CONTROLLER }

const PATH := "user://controls.json"
const VERSION := 1
const NO_ACTION := -1
const INPUT_ACTIONS := {Action.WALK_UP: &"move_up", Action.WALK_DOWN: &"move_down", Action.WALK_LEFT: &"move_left",
	Action.WALK_RIGHT: &"move_right", Action.RUN: &"run", Action.USE: &"use", Action.BUILD_LIST: &"build",
	Action.PAUSE: &"pause"}
const NAMES := {Action.WALK_UP: "Walk up", Action.WALK_DOWN: "Walk down", Action.WALK_LEFT: "Walk left",
	Action.WALK_RIGHT: "Walk right", Action.RUN: "Run (hold)", Action.USE: "Use / take",
	Action.BUILD_LIST: "Build list", Action.PAUSE: "Pause"}

const _DEFAULT_KEYS := {Action.WALK_UP: [KEY_W, KEY_UP], Action.WALK_DOWN: [KEY_S, KEY_DOWN],
	Action.WALK_LEFT: [KEY_A, KEY_LEFT], Action.WALK_RIGHT: [KEY_D, KEY_RIGHT], Action.RUN: [KEY_SHIFT, KEY_NONE],
	Action.USE: [KEY_E, KEY_NONE], Action.BUILD_LIST: [KEY_B, KEY_NONE], Action.PAUSE: [KEY_ESCAPE, KEY_NONE]}
# [axis, sign] for a stick direction, or a button index.
const _DEFAULT_PAD := {Action.WALK_UP: [JOY_AXIS_LEFT_Y, -1], Action.WALK_DOWN: [JOY_AXIS_LEFT_Y, 1],
	Action.WALK_LEFT: [JOY_AXIS_LEFT_X, -1], Action.WALK_RIGHT: [JOY_AXIS_LEFT_X, 1],
	Action.RUN: JOY_BUTTON_LEFT_SHOULDER, Action.USE: JOY_BUTTON_A, Action.BUILD_LIST: JOY_BUTTON_Y,
	Action.PAUSE: JOY_BUTTON_START}
const _DEVICE_KEYS := {Device.KEYBOARD: "keyboard", Device.CONTROLLER: "controller"}

var path: String   # "" = never written (tests, and the gdUnit command-line run)
var _slots := {}   # Device -> Action -> Array of InputEvent or null

## Starts at the defaults; writes nothing.
func _init(p_path: String = "") -> void:
	path = p_path
	for device: Device in Device.values():
		_slots[device] = {}
		for a: Action in Action.values():
			var row: Array = []
			for i in slot_count(device):
				row.append(default_slot(a, device, i))
			_slots[device][a] = row

static func slot_count(device: Device) -> int:
	return 2 if device == Device.KEYBOARD else 1

## A new event for that default slot, or null.
static func default_slot(action: Action, device: Device, index: int) -> InputEvent:
	if device == Device.KEYBOARD:
		var code: Key = _DEFAULT_KEYS[action][index]
		return null if code == KEY_NONE else _new_key(code, KEY_LOCATION_UNSPECIFIED)
	var pad: Variant = _DEFAULT_PAD[action]
	if pad is Array:
		return _new_motion(pad[0], pad[1])
	return _new_button(pad)

## Keys by code (an unspecified side matches either side), buttons by index, stick directions by axis and sign.
static func same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka := a as InputEventKey
		var kb := b as InputEventKey
		return ka.physical_keycode == kb.physical_keycode and (ka.location == KEY_LOCATION_UNSPECIFIED
			or kb.location == KEY_LOCATION_UNSPECIFIED or ka.location == kb.location)
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		var ma := a as InputEventJoypadMotion
		var mb := b as InputEventJoypadMotion
		return ma.axis == mb.axis and signf(ma.axis_value) == signf(mb.axis_value)
	return false

## The stored event or null; callers must not mutate it.
func slot(action: Action, device: Device, index: int) -> InputEvent:
	return _slots[device][action][index]

## Slot 0 if set, else slot 1, else null.
func first_input(action: Action, device: Device) -> InputEvent:
	for e: InputEvent in _slots[device][action]:
		if e != null:
			return e
	return null

func has_no_key(action: Action, device: Device) -> bool:
	return first_input(action, device) == null

func actions_without_key(device: Device) -> Array[Action]:
	var result: Array[Action] = []
	for a: Action in Action.values():
		if has_no_key(a, device):
			result.append(a)
	return result

## Puts a copy of event in the slot. Returns the other action a clash emptied, else NO_ACTION.
func set_slot(action: Action, device: Device, index: int, event: InputEvent) -> int:
	if same_input(slot(action, device, index), event):
		return NO_ACTION
	var emptied := NO_ACTION
	for a: Action in Action.values():
		var row: Array = _slots[device][a]
		for i in row.size():
			if (a != action or i != index) and same_input(row[i], event):
				row[i] = null
				if a != action:
					emptied = a
	_slots[device][action][index] = _normalised(event)
	_changed()
	return emptied

func clear_slot(action: Action, device: Device, index: int) -> void:
	if slot(action, device, index) == null:
		return
	_slots[device][action][index] = null
	_changed()

## That device's slots back to the defaults; the other device is untouched.
func reset(device: Device) -> void:
	for a: Action in Action.values():
		for i in slot_count(device):
			_slots[device][a][i] = default_slot(a, device, i)
	_changed()

func apply_to_input_map() -> void:
	for a: Action in Action.values():
		var name: StringName = INPUT_ACTIONS[a]
		InputMap.action_erase_events(name)
		for device: Device in [Device.KEYBOARD, Device.CONTROLLER]:
			for e: InputEvent in _slots[device][a]:
				if e != null:
					InputMap.action_add_event(name, e.duplicate())

func to_dict() -> Dictionary:
	var keyboard := {}
	var controller := {}
	for a: Action in Action.values():
		var name := String(INPUT_ACTIONS[a])
		var keys: Array = []
		for e: InputEvent in _slots[Device.KEYBOARD][a]:
			keys.append(null if e == null else {"key": (e as InputEventKey).physical_keycode,
				"location": (e as InputEventKey).location})
		keyboard[name] = keys
		var pad: InputEvent = _slots[Device.CONTROLLER][a][0]
		if pad is InputEventJoypadButton:
			controller[name] = {"button": (pad as InputEventJoypadButton).button_index}
		elif pad is InputEventJoypadMotion:
			var m := pad as InputEventJoypadMotion
			controller[name] = {"axis": m.axis, "sign": int(signf(m.axis_value))}
		else:
			controller[name] = null
	return {"version": VERSION, "keyboard": keyboard, "controller": controller}

## OK at once when path is "".
func save() -> Error:
	if path == "":
		return OK
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		push_warning("could not save controls to %s: %s" % [path, error_string(err)])
		return err if err != OK else ERR_FILE_CANT_WRITE
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return OK

## The stored controls, or the defaults when the file is missing or any part of it is unreadable. Never writes.
static func load_from(p_path: String) -> Controls:
	var result := Controls.new(p_path)
	if p_path == "" or not FileAccess.file_exists(p_path):
		return result
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(p_path)) != OK:
		return result
	var data: Variant = json.data
	if not data is Dictionary or not _whole(data.get("version")) or int(data["version"]) != VERSION:
		return result
	var loaded := Controls.new(p_path)
	for device: Device in Device.values():
		var section: Variant = data.get(_DEVICE_KEYS[device])
		if not section is Dictionary:
			return result
		for a: Action in Action.values():
			var name := String(INPUT_ACTIONS[a])
			if not (section as Dictionary).has(name):
				return result
			var row: Variant = _read_row(device, section[name])
			if row == null:
				return result
			loaded._slots[device][a] = row
	for device: Device in Device.values():
		var seen: Array[InputEvent] = []
		for a: Action in Action.values():
			for e: InputEvent in loaded._slots[device][a]:
				if e == null:
					continue
				for other in seen:
					if same_input(e, other):
						return result
				seen.append(e)
	return loaded

# An Array of events (or nulls) for one action, or null when the entry is unreadable.
static func _read_row(device: Device, entry: Variant) -> Variant:
	if device == Device.KEYBOARD:
		if not entry is Array or (entry as Array).size() != 2:
			return null
		var row: Array = []
		for item: Variant in entry:
			if item == null:
				row.append(null)
				continue
			if not item is Dictionary or (item as Dictionary).size() != 2:
				return null
			var key: Variant = item.get("key")
			var location: Variant = item.get("location")
			if not _whole(key) or key <= 0 or key >= KEY_SPECIAL << 1 or not _whole(location) or location < 0 or location > 2:
				return null
			row.append(_new_key(int(key), int(location)))
		return row
	if entry == null:
		return [null]
	if not entry is Dictionary:
		return null
	var d := entry as Dictionary
	if d.size() == 1 and _whole(d.get("button")) and d["button"] >= 0 and d["button"] < JOY_BUTTON_MAX:
		return [_new_button(int(d["button"]))]
	if d.size() == 2 and _whole(d.get("axis")) and d["axis"] >= 0 and d["axis"] < JOY_AXIS_MAX \
			and _whole(d.get("sign")) and absi(int(d["sign"])) == 1:
		return [_new_motion(int(d["axis"]), int(d["sign"]))]
	return null

static func _whole(x: Variant) -> bool:
	return (x is float or x is int) and x == floor(x)

static func _normalised(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		return _new_key((event as InputEventKey).physical_keycode, (event as InputEventKey).location)
	if event is InputEventJoypadButton:
		return _new_button((event as InputEventJoypadButton).button_index)
	if event is InputEventJoypadMotion:
		return _new_motion((event as InputEventJoypadMotion).axis, int(signf((event as InputEventJoypadMotion).axis_value)))
	return null

static func _new_key(code: int, location: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code as Key
	e.location = location as KeyLocation
	e.device = -1
	return e

static func _new_button(index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index as JoyButton
	e.device = -1
	return e

static func _new_motion(axis: int, sign: int) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis as JoyAxis
	e.axis_value = float(sign)
	e.device = -1
	return e

func _changed() -> void:
	apply_to_input_map()
	save()
	changed.emit()
