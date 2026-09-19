extends Node
## The live device tracker and menu step: sees every event at the root window, before any handler can consume it.
## It also catches the fixed fullscreen shortcut first, and blanks it so no handler takes it as a key.
## It also hides the mouse pointer while a menu is open and a key or pad was used last.

signal changed

var tracker: DeviceTracker
var controls: Controls
var menu_push: MenuPush
var _menu_event: InputEvent
var _menu_step := MenuPush.Step.NONE
var action_press: ActionPress
var _press_event: InputEvent
var pointer := PointerRule.new()
var window_shortcut: WindowShortcut

func _ready() -> void:
	# The gdUnit command-line run gives the SceneTree a script: it starts at the defaults and never touches the file.
	use_controls(Controls.load_from("" if get_tree().get_script() != null else Controls.PATH))
	process_mode = Node.PROCESS_MODE_ALWAYS
	pointer.changed.connect(_apply_pointer)
	reset(_pad_names(-1))
	get_tree().root.window_input.connect(_on_window_input)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func kind() -> DeviceTracker.Kind:
	return tracker.kind

## Makes c the live controls: applies them to the InputMap and tells every hint. Tests pass Controls.new().
func use_controls(c: Controls) -> void:
	if controls != null and controls.changed.is_connected(_on_controls_changed):
		controls.changed.disconnect(_on_controls_changed)
	controls = c
	c.changed.connect(_on_controls_changed)
	c.apply_to_input_map()
	changed.emit()

func _on_controls_changed() -> void:
	changed.emit()

## Starts over as at launch with these pads connected, on macOS's shortcut rules or not, and tells every hint. Tests call reset() for keyboard.
func reset(pad_names: PackedStringArray = PackedStringArray(), mac := OS.get_name() == "macOS") -> void:
	window_shortcut = WindowShortcut.new(mac)
	tracker = DeviceTracker.new(pad_names)
	menu_push = MenuPush.new()
	_menu_event = null
	_menu_step = MenuPush.Step.NONE
	action_press = ActionPress.new()
	_press_event = null
	tracker.changed.connect(changed.emit)
	pointer.forget_device()
	changed.emit()

func _on_window_input(event: InputEvent) -> void:
	var shortcut := window_shortcut.read(event)
	if shortcut != WindowShortcut.Result.NONE:
		WindowShortcut.blank(event as InputEventKey)
		if shortcut == WindowShortcut.Result.TOGGLE:
			Display.toggle_fullscreen()
	var pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	tracker.observe(event, Input.get_joy_name(event.device) if pad else "")
	menu_step(event)
	_read_press(event)
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

## Whether this event is a fresh press of a play action, one per push on a stick; worked out once per event.
func action_pressed(event: InputEvent, action: StringName) -> bool:
	_read_press(event)
	return action_press.pressed(event, action)

## Whether this event lets go of a play action; worked out once per event.
func action_released(event: InputEvent, action: StringName) -> bool:
	_read_press(event)
	return action_press.released(event, action)

func _read_press(event: InputEvent) -> void:
	if event != _press_event:
		_press_event = event
		action_press.read(event)

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
