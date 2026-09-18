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
	verb_label.add_theme_color_override(&"font_color", HudColours.CREAM)
	add_child(verb_label)
	InputDevice.changed.connect(_on_device_changed)
	Display.changed.connect(_rescale)
	get_tree().root.size_changed.connect(_rescale)
	_rescale()

# Grows with UI size about its own origin, the prompt's bottom centre.
func _rescale() -> void:
	scale = Vector2.ONE * UiScale.current(Display.prefs, get_tree().root)
	_layout()

## How much bigger the verb is than at Text size Normal; 1.0 out of the tree.
func text_scale() -> float:
	return TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

## The plank's height at the current Text size; 13 at Normal.
func height() -> int:
	return HEIGHT + int(TextScale.extra(HintLine.FONT_SIZE, text_scale()))

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
	return 3 + _picture_room() + _words_width() + 3

# The verb's width once grown; get_minimum_size() ignores the label's scale, so multiply it here.
func _words_width() -> int:
	return ceili(verb_label.get_minimum_size().x * text_scale())

# The picture's width and the gap after it; nothing without a picture.
func _picture_room() -> int:
	var p := picture()
	return 0 if p == null else HintLine.picture_width(p) + 2

func _layout() -> void:
	verb_label.scale = Vector2.ONE * text_scale()
	verb_label.position = Vector2(-width() / 2 + 3 + _picture_room(), -height() + 3)
	queue_redraw()

func _on_device_changed() -> void:
	_layout()

func _draw() -> void:
	var w := width()
	var h := height()
	var x0 := -w / 2
	var y0 := -h
	draw_rect(Rect2(x0, y0, w, h), HudColours.WOOD_DARK)
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, h - 2), HudColours.WOOD)
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 1), HudColours.WOOD_LIGHT)
	var p := picture()
	if p != null:
		HintLine.draw_picture(self, p, Vector2(x0 + 3, y0 + 2 + floori((h - HEIGHT) / 2.0)))
