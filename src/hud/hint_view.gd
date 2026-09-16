class_name HintView
extends Control
## One hint line, centred in this control, redrawn in place when the device changes.

@export var hint: DeviceHints.Hint = DeviceHints.Hint.MOVE
@export var word_colour := Color("#fff6e0")

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	InputDevice.changed.connect(_on_device_changed)

func items() -> Array:
	return DeviceHints.line(hint, InputDevice.kind())

func text() -> String:
	return DeviceHints.as_text(items())

func line_width() -> int:
	return HintLine.width(items(), get_theme_default_font())

func _on_device_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var at := Vector2(roundi((size.x - line_width()) / 2.0), roundi((size.y - HintLine.HEIGHT) / 2.0))
	HintLine.draw(self, items(), at, get_theme_default_font(), word_colour)
