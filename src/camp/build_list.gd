class_name BuildList
extends Control
## The wooden Build list: a title and two rows, drawn from a BuildMenu.
## At 640x360 it always fits above the build hint and its words never wrap: its scrolling and wrapping
## were retired in tr-1o0.1 (build_list_text_size_scene_test.gd holds the fit).

signal row_hovered(thing: int)
signal row_clicked(thing: int)

const SIZE := Vector2(196, 41)
const ROW_SIZE := Vector2(190, 11)
const ROW_TOP: Array[int] = [14, 27]
const STACKED_SIZE := Vector2(150, 61)
const STACKED_ROW_SIZE := Vector2(144, 21)
const STACKED_ROW_TOP: Array[int] = [14, 37]
const LINE_HEIGHT := 9.0                # the cost line's top below the name line's top when stacked
const COST_GAP := 8.0                   # the least space between a name and its cost, side by side
const TEXT := HudColours.PALE
const GREYED := HudColours.DIM
const BORDER := HudColours.WOOD_DARK
const FILL := HudColours.WOOD
const HIGHLIGHT := HudColours.WOOD_LIGHT

# The Normal geometry, named. Only words grow; every one of these keeps its UI-size scale.
const TEXT_LINE := 8.0                  # one line of words, in list units, at Text size Normal
const INSET := 3.0                      # the list's left/right inset, and the row's
const WORDS_INSET := 12.0               # both insets on both sides: the list's width less its words'
const TITLE_TOP := 3.0                  # the title's top
const TITLE_GAP := 3.0                  # the title's bottom to the first row's top
const ROW_GAP := 2.0                    # one row's bottom to the next row's top
const BOTTOM_MARGIN := 3.0              # the last row's bottom to the list's bottom
const ROW_TOP_PAD := 2.0                # a row's top to its name
const ROW_BOTTOM_PAD := 1.0             # the name's bottom to the row's bottom, side by side
const NAME_GAP := 1.0                   # the name's bottom to the cost's top, stacked
const STACKED_BOTTOM_PAD := 2.0         # the cost's bottom to the row's bottom, stacked

var clip: Control
var content: Control
var title_label: Label
var rows: Array[Control] = []
var name_labels: Array[Label] = []
var cost_labels: Array[Label] = []
var _menu: BuildMenu
## True while every row shows its cost under its name. Set only by _place; read it, never write it.
var stacked := false
## The words' scale inside the list, on top of UI size; 1.0 at Text size Normal.
## Set only by _place; read it, never write it.
var _rel := 1.0
## The list's own UI scale. Set only by _place; read it, never write it.
var _ui := 1.0

const SCREEN_MARGIN := 4.0
const ABOVE_HIM := 28.0                 # his screen point to the list's bottom edge
const RIGHT_OF_HIM := 12.0

var _man := Vector2.ZERO
var _placed := false

## Top-left on the picture of the list drawn at scale s: its bottom-left corner RIGHT_OF_HIM right of
## and ABOVE_HIM above him, kept on screen; when wider than the screen less both margins, centred instead.
static func top_left_for(man_on_screen: Vector2, s: float = 1.0, box: Vector2 = SIZE) -> Vector2:
	var w := box.x * s
	var h := box.y * s
	var x := roundf((Screen.WIDTH - w) / 2.0) if w > Screen.WIDTH - 2.0 * SCREEN_MARGIN \
			else clampf(roundf(man_on_screen.x) + RIGHT_OF_HIM, SCREEN_MARGIN, Screen.WIDTH - SCREEN_MARGIN - w)
	var y := maxf(2.0, roundf(roundf(man_on_screen.y) - ABOVE_HIM - h))
	return Vector2(x, y)

## Remembers his screen point and places and scales the list for the current UI size, now and after every change.
func place_beside(man_on_screen: Vector2) -> void:
	_man = man_on_screen
	_placed = true
	_place()

func _place() -> void:
	if not _placed or not is_inside_tree():
		return
	_ui = UiScale.current(Display.prefs, get_tree().root)
	_rel = TextScale.relative(Display.prefs, get_tree().root)
	stacked = stacks(side_by_side_width(_rel), _ui)
	_layout()
	scale = Vector2(_ui, _ui)
	position = top_left_for(_man, _ui, list_size())
	queue_redraw()

## True when a list side_by_side_width wide, drawn at scale s, is wider than the screen.
static func stacks(side_by_side_width: float, s: float) -> bool:
	return side_by_side_width * s > Screen.WIDTH

## The list's unscaled width with every row side by side for the words it shows now, grown by `rel`:
## SIZE.x, or wider when a row's grown name, COST_GAP and cost, plus the 3-unit insets on both sides
## of the row and of the list, need more.
func side_by_side_width(rel := 1.0) -> float:
	var widest := 0.0
	for i in BuildMenu.LINE_COUNT:
		widest = maxf(widest,
				ceilf((_text_width(name_labels[i]) + _text_width(cost_labels[i])) * rel))
	return maxf(SIZE.x, widest + COST_GAP + WORDS_INSET)

## The list's unscaled width for the words it shows now: side by side, the widest grown row; stacked,
## the widest grown word block, capped by TextScale.fit_width so the list stays on the screen (at 640x360
## the cap never bites).
## At Text size Normal it is exactly today's: the list grows only because its words did.
func list_width() -> float:
	if is_equal_approx(_rel, 1.0):
		return STACKED_SIZE.x if stacked else SIZE.x
	if not stacked:
		return side_by_side_width(_rel)
	return TextScale.fit_width(STACKED_SIZE.x, ceilf(_widest_word_block() * _rel) + WORDS_INSET, _ui)

## The widest single name or cost, unscaled.
func _widest_word_block() -> float:
	var widest := 0.0
	for i in BuildMenu.LINE_COUNT:
		widest = maxf(widest, maxf(_text_width(name_labels[i]), _text_width(cost_labels[i])))
	return widest

## The width, in the labels' own units, that a name or cost is drawn in.
func _text_width_available() -> float:
	return (list_width() - WORDS_INSET) / _rel

## The drawn height, in list units, of one grown line of words.
func _text_height() -> float:
	return ceilf(TEXT_LINE * _rel)

static func _width_of(label: Label, text: String) -> float:
	return label.get_theme_font(&"font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size(&"font_size")).x

static func _text_width(label: Label) -> float:
	return _width_of(label, label.text)

## The list's unscaled size for the words it shows now.
func list_size() -> Vector2:
	return Vector2(list_width(),
			_row_tops()[BuildMenu.LINE_COUNT - 1] + _row_size().y + BOTTOM_MARGIN)

func _row_size() -> Vector2:
	var h := ROW_TOP_PAD + _text_height()
	h += (NAME_GAP + _text_height() + STACKED_BOTTOM_PAD) if stacked else ROW_BOTTOM_PAD
	return Vector2(list_width() - 2.0 * INSET, h)

func _row_tops() -> Array[float]:
	var tops: Array[float] = []
	var top := TITLE_TOP + _text_height() + TITLE_GAP
	for i in BuildMenu.LINE_COUNT:
		tops.append(top)
		top += _row_size().y + ROW_GAP
	return tops

func _layout() -> void:
	var text_w := _text_width_available()
	var box := list_size()
	var row_size := _row_size()
	var tops := _row_tops()
	title_label.position = Vector2(0, TITLE_TOP)
	title_label.scale = Vector2.ONE * _rel
	title_label.size = Vector2(box.x / _rel, TEXT_LINE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in BuildMenu.LINE_COUNT:
		rows[i].position = Vector2(INSET, tops[i])
		rows[i].size = row_size
		name_labels[i].position = Vector2(INSET, ROW_TOP_PAD)
		name_labels[i].scale = Vector2.ONE * _rel
		name_labels[i].size = Vector2(text_w, TEXT_LINE)
		name_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		cost_labels[i].scale = Vector2.ONE * _rel
		cost_labels[i].size = Vector2(text_w, TEXT_LINE)
		if stacked:
			cost_labels[i].position = Vector2(INSET, ROW_TOP_PAD + _text_height() + NAME_GAP)
			cost_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			cost_labels[i].position = Vector2(0, ROW_TOP_PAD)
			cost_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	size = box
	clip.size = box
	content.size = box
	content.queue_redraw()
	queue_redraw()

func _ready() -> void:
	hide()
	Display.changed.connect(_place)
	get_tree().root.size_changed.connect(_place)
	mouse_filter = MOUSE_FILTER_IGNORE
	clip = Control.new()
	clip.clip_contents = true
	clip.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(clip)
	content = Control.new()
	content.mouse_filter = MOUSE_FILTER_IGNORE
	content.draw.connect(_draw_highlight)
	clip.add_child(content)
	title_label = _label("Build")
	title_label.position = Vector2(0, 3)
	title_label.size = Vector2(SIZE.x, 8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override(&"font_color", TEXT)
	content.add_child(title_label)
	for i in BuildMenu.LINE_COUNT:
		var row := Control.new()
		row.mouse_filter = MOUSE_FILTER_STOP
		row.mouse_entered.connect(func() -> void: row_hovered.emit(i))
		row.gui_input.connect(_on_row_input.bind(i))
		content.add_child(row)
		rows.append(row)
		var name_label := _label("")
		var cost_label := _label("")
		row.add_child(name_label)
		row.add_child(cost_label)
		name_labels.append(name_label)
		cost_labels.append(cost_label)
	_layout()

func show_menu(menu: BuildMenu) -> void:
	_menu = menu
	for i in BuildMenu.LINE_COUNT:
		var thing := i as BuildMenu.Thing
		name_labels[i].text = BuildMenu.NAMES[i]
		cost_labels[i].text = menu.cost_text(thing)
		var colour := TEXT if menu.can_build(thing) else GREYED
		name_labels[i].add_theme_color_override(&"font_color", colour)
		cost_labels[i].add_theme_color_override(&"font_color", colour)
	_place()
	content.queue_redraw()
	queue_redraw()

func _draw() -> void:
	var box := size
	draw_rect(Rect2(Vector2.ZERO, box), BORDER)
	draw_rect(Rect2(1, 1, box.x - 2, box.y - 2), FILL)

## The highlight line, drawn on content under the rows.
func _draw_highlight() -> void:
	if _menu and _menu.highlighted >= 0:
		content.draw_rect(Rect2(Vector2(INSET, _row_tops()[_menu.highlighted]), _row_size()), HIGHLIGHT)

func _on_row_input(event: InputEvent, i: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		row_clicked.emit(i)

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", 8)
	label.pivot_offset = Vector2.ZERO
	return label
