class_name HintView
extends Control
## One hint line, centred in this control, redrawn in place when the device changes.

@export var hint: DeviceHints.Hint = DeviceHints.Hint.MOVE
@export var word_colour := HudColours.PALE

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	InputDevice.changed.connect(_on_device_changed)
	Display.changed.connect(_on_device_changed)
	get_tree().root.size_changed.connect(_on_device_changed)

func items() -> Array:
	return DeviceHints.line(hint, InputDevice.kind(), "", InputDevice.controls)

func text() -> String:
	return DeviceHints.as_text(items())

## How much bigger the words are than at Text size Normal; 1.0 out of the tree.
func rel() -> float:
	return TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

func line_width() -> int:
	return HintLine.width(items(), get_theme_default_font(), rel())

## The row's height at the current Text size.
func line_height() -> int:
	return HintLine.height(rel())

## What a host adds to its band's Normal height to fit the grown row.
func grown_by() -> int:
	return line_height() - HintLine.HEIGHT

func _on_device_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var at := Vector2(roundi((size.x - line_width()) / 2.0), roundi((size.y - line_height()) / 2.0))
	HintLine.draw(self, items(), at, get_theme_default_font(), word_colour, rel())
