class_name BuildList
extends Control
## The wooden Build list: a title and two rows, drawn from a BuildMenu.

signal row_hovered(thing: int)
signal row_clicked(thing: int)

const SIZE := Vector2(196, 41)
const ROW_SIZE := Vector2(190, 11)
const ROW_TOP: Array[int] = [14, 27]
const TEXT := Color("#fff6e0")
const GREYED := Color("#c9b79c")
const BORDER := Color("#5c3a22")
const FILL := Color("#8a5a34")
const HIGHLIGHT := Color("#b98452")

var title_label: Label
var rows: Array[Control] = []
var name_labels: Array[Label] = []
var cost_labels: Array[Label] = []
var _menu: BuildMenu

## Above his head and to his right, kept on the 320x180 screen.
static func top_left_for(man_on_screen: Vector2) -> Vector2:
	return Vector2(clampf(roundf(man_on_screen.x) + 12, 4, 320 - 4 - SIZE.x), maxf(2, roundf(man_on_screen.y) - 69))

func _ready() -> void:
	hide()
	size = SIZE
	mouse_filter = MOUSE_FILTER_IGNORE
	title_label = _label("Build", Vector2(0, 3), Vector2(SIZE.x, 8), HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override(&"font_color", TEXT)
	add_child(title_label)
	for i in BuildMenu.LINE_COUNT:
		var row := Control.new()
		row.position = Vector2(3, ROW_TOP[i])
		row.size = ROW_SIZE
		row.mouse_filter = MOUSE_FILTER_STOP
		row.mouse_entered.connect(func() -> void: row_hovered.emit(i))
		row.gui_input.connect(_on_row_input.bind(i))
		add_child(row)
		rows.append(row)
		var name_label := _label("", Vector2(3, 2), Vector2(ROW_SIZE.x - 6, 8), HORIZONTAL_ALIGNMENT_LEFT)
		var cost_label := _label("", Vector2(0, 2), Vector2(184, 8), HORIZONTAL_ALIGNMENT_RIGHT)
		row.add_child(name_label)
		row.add_child(cost_label)
		name_labels.append(name_label)
		cost_labels.append(cost_label)

func show_menu(menu: BuildMenu) -> void:
	_menu = menu
	for i in BuildMenu.LINE_COUNT:
		var thing := i as BuildMenu.Thing
		name_labels[i].text = BuildMenu.NAMES[i]
		cost_labels[i].text = menu.cost_text(thing)
		var colour := TEXT if menu.can_build(thing) else GREYED
		name_labels[i].add_theme_color_override(&"font_color", colour)
		cost_labels[i].add_theme_color_override(&"font_color", colour)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), BORDER)
	draw_rect(Rect2(1, 1, SIZE.x - 2, SIZE.y - 2), FILL)
	if _menu and _menu.highlighted >= 0:
		draw_rect(Rect2(Vector2(3, ROW_TOP[_menu.highlighted]), ROW_SIZE), HIGHLIGHT)

func _on_row_input(event: InputEvent, i: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		row_clicked.emit(i)

func _label(text: String, at: Vector2, box: Vector2, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = box
	label.horizontal_alignment = align
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", 8)
	return label
