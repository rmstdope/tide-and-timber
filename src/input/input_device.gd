extends Node
## The live device tracker and menu step: sees every event at the root window, before any handler can consume it.
## It also hides the mouse pointer while a menu is open and a key or pad was used last.

signal changed

var tracker: DeviceTracker
var menu_push: MenuPush
var _menu_event: InputEvent
var _menu_step := MenuPush.Step.NONE
var pointer := PointerRule.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pointer.changed.connect(_apply_pointer)
	reset(_pad_names(-1))
	get_tree().root.window_input.connect(_on_window_input)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func kind() -> DeviceTracker.Kind:
	return tracker.kind

## Starts over as at launch with these pads connected, and tells every hint. Tests call reset() for keyboard.
func reset(pad_names: PackedStringArray = PackedStringArray()) -> void:
	tracker = DeviceTracker.new(pad_names)
	menu_push = MenuPush.new()
	_menu_event = null
	_menu_step = MenuPush.Step.NONE
	tracker.changed.connect(changed.emit)
	pointer.forget_device()
	changed.emit()

func _on_window_input(event: InputEvent) -> void:
	var pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	tracker.observe(event, Input.get_joy_name(event.device) if pad else "")
	menu_step(event)
	pointer.observe(event)

## A menu or box owned by this node opened or closed. Menus call it; the pointer follows.
func set_menu_open(menu: Object, open: bool) -> void:
	pointer.set_menu_open(menu.get_instance_id(), open)

func _apply_pointer() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if pointer.hidden else Input.MOUSE_MODE_VISIBLE

## The menu step this event makes, worked out once per event however many handlers ask.
func menu_step(event: InputEvent) -> MenuPush.Step:
	if event != _menu_event:
		_menu_event = event
		_menu_step = menu_push.read(event)
	return _menu_step

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		tracker.pad_connected(device, Input.get_joy_name(device))
	else:
		tracker.pad_disconnected(device, _pad_names(device))

func _pad_names(except: int) -> PackedStringArray:
	var names := PackedStringArray()
	for d in Input.get_connected_joypads():
		if d != except:
			names.append(Input.get_joy_name(d))
	return names
