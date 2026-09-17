class_name UsePrompt
extends Node2D
## The small wooden prompt in the world, the device's use button and the verb, its bottom-centre just
## above the thing.

const HEIGHT := 13

var verb_label: Label

func _ready() -> void:
	hide()
	z_index = 20
	verb_label = Label.new()
	verb_label.add_theme_font_size_override(&"font_size", 8)
	verb_label.add_theme_color_override(&"font_color", Color("#f4e3c1"))
	add_child(verb_label)
	InputDevice.changed.connect(_on_device_changed)

## The player's Use key or button on the device in use, or null when Use has none there.
func picture() -> DeviceHints.Picture:
	var pictures := DeviceHints.pictures(InputDevice.kind(), DeviceHints.Slot.BOTTOM, InputDevice.controls)
	return null if pictures.is_empty() else pictures[0]

func text() -> String:
	var p := picture()
	return verb_label.text if p == null else DeviceHints.as_text([p, verb_label.text])

func show_for(usable: Usable) -> void:
	verb_label.text = usable.verb
	global_position = (usable.global_position + usable.prompt_offset).round()
	_layout()
	show()

func width() -> int:
	return 3 + _picture_room() + ceili(verb_label.get_minimum_size().x) + 3

# The picture's width and the gap after it; nothing without a picture.
func _picture_room() -> int:
	var p := picture()
	return 0 if p == null else HintLine.picture_width(p) + 2

func _layout() -> void:
	verb_label.position = Vector2(-width() / 2 + 3 + _picture_room(), -HEIGHT + 3)
	queue_redraw()

func _on_device_changed() -> void:
	_layout()

func _draw() -> void:
	var w := width()
	var x0 := -w / 2
	var y0 := -HEIGHT
	draw_rect(Rect2(x0, y0, w, 13), Color("#7a5030"))
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 11), Color("#b07a45"))
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 1), Color("#d9a56b"))
	var p := picture()
	if p != null:
		HintLine.draw_picture(self, p, Vector2(x0 + 3, y0 + 2))
