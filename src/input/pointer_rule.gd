class_name PointerRule
extends RefCounted
## Whether the mouse pointer is hidden: only while a menu is open and a key or pad was used last.
## No nodes; InputDevice feeds it and applies it.

signal changed

var mouse_last := true      # the mouse was the last thing used; true at launch
var hidden := false         # derived: a menu is open and not mouse_last
var _menus: Dictionary = {} # instance id of each open menu -> true

## A real mouse movement: motion with a non-zero relative. A zero-relative motion is not a move.
static func is_move(event: InputEvent) -> bool:
	return event is InputEventMouseMotion and (event as InputEventMouseMotion).relative != Vector2.ZERO

## Counts one input event towards mouse_last.
func observe(event: InputEvent) -> void:
	if is_move(event):
		mouse_last = true
	elif event is InputEventMouseButton:
		if event.pressed:
			mouse_last = true
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			mouse_last = false
	elif event is InputEventJoypadButton:
		if event.pressed:
			mouse_last = false
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= DeviceTracker.DEAD_ZONE:
			mouse_last = false
	_update()

## A menu or box, named by its owner's instance id, opened or closed. Idempotent.
func set_menu_open(owner_id: int, open: bool) -> void:
	if open:
		_menus[owner_id] = true
	else:
		_menus.erase(owner_id)
	_update()

## As at launch: the mouse was the last thing used. Open menus are kept.
func forget_device() -> void:
	mouse_last = true
	_update()

func _update() -> void:
	var now := not _menus.is_empty() and not mouse_last
	if now != hidden:
		hidden = now
		changed.emit()
