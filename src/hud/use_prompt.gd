class_name UsePrompt
extends Node2D
## The small wooden [E] <verb> prompt in the world, its bottom-centre just above the thing.

const HEIGHT := 13

var verb_label: Label

func _ready() -> void:
	hide()
	z_index = 20
	verb_label = Label.new()
	verb_label.add_theme_font_size_override(&"font_size", 8)
	verb_label.add_theme_color_override(&"font_color", Color("#f4e3c1"))
	add_child(verb_label)

func show_for(usable: Usable) -> void:
	verb_label.text = usable.verb
	global_position = (usable.global_position + usable.prompt_offset).round()
	show()
	queue_redraw()

func width() -> int:
	return 3 + 9 + 2 + ceili(verb_label.get_minimum_size().x) + 3

func _draw() -> void:
	var w := width()
	var x0 := -w / 2
	var y0 := -HEIGHT
	verb_label.position = Vector2(x0 + 14, y0 + 3)
	draw_rect(Rect2(x0, y0, w, 13), Color("#7a5030"))
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 11), Color("#b07a45"))
	draw_rect(Rect2(x0 + 1, y0 + 1, w - 2, 1), Color("#d9a56b"))
	draw_rect(Rect2(x0 + 3, y0 + 2, 9, 9), Color("#f4e3c1"))
	draw_rect(Rect2(x0 + 3, y0 + 10, 9, 1), Color("#a8977a"))
	Glyphs.draw(self, "E", Vector2(x0 + 6, y0 + 4), Color("#3a2414"))
