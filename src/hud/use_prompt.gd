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

func picture() -> DeviceHints.Picture:
	return DeviceHints.pictures(InputDevice.kind(), DeviceHints.Slot.BOTTOM)[0]

func text() -> String:
	return DeviceHints.as_text([picture(), verb_label.text])

func show_for(usable: Usable) -> void:
	verb_label.text = usable.verb
	global_position = (usable.global_position + usable.prompt_offset).round()
	_layout()
	show()

func width() -> int:
	return 3 + HintLine.picture_width(picture()) + 2 + ceili(verb_label.get_minimum_size().x) + 3

func _layout() -> void:
	verb_label.position = Vector2(-width() / 2 + 3 + HintLine.picture_width(picture()) + 2, -HEIGHT + 3)
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
	HintLine.draw_picture(self, picture(), Vector2(x0 + 3, y0 + 2))
