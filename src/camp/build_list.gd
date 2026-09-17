class_name BuildList
extends Control
## The wooden Build list: a title and two rows, drawn from a BuildMenu.
## When it is taller than the room above its hint, it is framed to fit and scrolls to the highlight,
## with ▲ / ▼ where rows are hidden.

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
const SCREEN_WIDTH := 320.0
const TEXT := Color("#fff6e0")
const GREYED := Color("#c9b79c")
const BORDER := Color("#5c3a22")
const FILL := Color("#8a5a34")
const HIGHLIGHT := Color("#b98452")
const CONTENT_TOP := 3.0                # the title's top: the scrolled content starts here
const CONTENT_BOTTOM_MARGIN := 3.0      # the last row's bottom to the list's bottom
const SCREEN_HEIGHT := 180.0            # the band's bottom edge when no hint is shown

var clip: Control
var content: Control
var title_label: Label
var rows: Array[Control] = []
var name_labels: Array[Label] = []
var cost_labels: Array[Label] = []
var _menu: BuildMenu
## True while every row shows its cost under its name. Set only by _place; read it, never write it.
var stacked := false
## Whole units the content is scrolled up; 0 while the list fits. Owned by frame(); reset only by place_beside.
var offset := 0
## True while the content does not fit the room above the hint. Set only by frame(); read it, never write it.
var scrolls := false
## The hint whose on-screen top bounds the list from below; null when none.
var hint: Control

const SCREEN_MARGIN := 4.0
const ABOVE_HIM := 28.0                 # his screen point to the list's bottom edge
const RIGHT_OF_HIM := 12.0

var _man := Vector2.ZERO
var _placed := false

## Top-left on the 320x180 screen of the list drawn at scale s: its bottom-left corner RIGHT_OF_HIM right of
## and ABOVE_HIM above him, kept on screen; when wider than the screen less both margins, centred instead.
static func top_left_for(man_on_screen: Vector2, s: float = 1.0, box: Vector2 = SIZE) -> Vector2:
	var w := box.x * s
	var h := box.y * s
	var x := roundf((320.0 - w) / 2.0) if w > 320.0 - 2.0 * SCREEN_MARGIN \
			else clampf(roundf(man_on_screen.x) + RIGHT_OF_HIM, SCREEN_MARGIN, 320.0 - SCREEN_MARGIN - w)
	var y := maxf(2.0, roundf(roundf(man_on_screen.y) - ABOVE_HIM - h))
	return Vector2(x, y)

## Remembers his screen point and places and scales the list for the current UI size, now and after every change.
func place_beside(man_on_screen: Vector2) -> void:
	_man = man_on_screen
	_placed = true
	offset = 0
	_place()

## Bounds the list from below by h's on-screen top while h is visible, re-framing whenever h moves, resizes,
## shows or hides.
func use_hint(h: Control) -> void:
	hint = h
	h.item_rect_changed.connect(_place)
	h.visibility_changed.connect(_place)
	_place()

func _place() -> void:
	if not _placed or not is_inside_tree():
		return
	var s := UiScale.current(Display.prefs, get_tree().root)
	stacked = stacks(side_by_side_width(), s)
	_layout()
	scale = Vector2(s, s)
	position = top_left_for(_man, s, list_size())
	_frame(s)

## Frames the list, already scaled by s and placed, to the band read from the hint.
func _frame(s: float) -> void:
	# The list's own transform is not used because frame() changes it; its parent may be a CanvasLayer,
	# which is not a CanvasItem.
	var parent_t := get_global_transform_with_canvas() * get_transform().affine_inverse()
	var b := ScrollWindow.band(parent_t, _hint_top())
	frame(b.x, b.y, s)

## The hint's on-screen top while it is visible, else the screen's bottom edge.
func _hint_top() -> float:
	if hint != null and hint.is_visible_in_tree():
		return HintLift.screen_rect(hint).position.y
	return SCREEN_HEIGHT

## Frames the list, already scaled by s and placed, to the band [band_top, band_bottom] in its parent's units,
## and scrolls the content so the highlighted row is wholly visible.
func frame(band_top: float, band_bottom: float, s: float) -> void:
	var box := list_size()
	var room := floorf((band_bottom - band_top) / s)
	if box.y <= room:
		scrolls = false
		offset = 0
		size = box
		clip.position = Vector2.ZERO
		clip.size = box
		content.position = Vector2.ZERO
	else:
		scrolls = true
		var view_h := room - 2.0 * ScrollWindow.MARK_ROW
		if _menu != null and _menu.highlighted >= 0:
			var e := _item_extent(_menu.highlighted)
			offset = ScrollWindow.follow(_content_height(), view_h, e.x, e.y, offset)
		position.y = band_top
		size = Vector2(box.x, room)
		clip.position = Vector2(0, ScrollWindow.MARK_ROW)
		clip.size = Vector2(box.x, view_h)
		content.position = Vector2(0, -(CONTENT_TOP + offset))
	queue_redraw()

## True while ▲ is drawn: scrolling, with content hidden above.
func shows_mark_above() -> bool:
	return scrolls and ScrollWindow.hidden_above(offset)

## True while ▼ is drawn: scrolling, with content hidden below.
func shows_mark_below() -> bool:
	return scrolls and ScrollWindow.hidden_below(offset, _content_height(), clip.size.y)

## The scrolled content's height: the title's top to the last row's bottom.
func _content_height() -> float:
	return list_size().y - CONTENT_TOP - CONTENT_BOTTOM_MARGIN

## Row i's top and bottom in the content's own units. The first row reaches the title, the last the bottom.
func _item_extent(i: int) -> Vector2:
	var top := _row_tops()[i] - CONTENT_TOP
	return ScrollWindow.stretch_ends(Vector2(top, top + _row_size().y), _content_height(),
			i == 0, i == BuildMenu.LINE_COUNT - 1)

## True when a list side_by_side_width wide, drawn at scale s, is wider than the screen.
static func stacks(side_by_side_width: float, s: float) -> bool:
	return side_by_side_width * s > SCREEN_WIDTH

## The list's unscaled width with every row side by side for the words it shows now: SIZE.x, or wider when
## a row's name, COST_GAP and cost, plus the row's and list's 3-unit insets on both sides, need more.
func side_by_side_width() -> float:
	var widest := 0.0
	for i in BuildMenu.LINE_COUNT:
		widest = maxf(widest, _text_width(name_labels[i]) + COST_GAP + _text_width(cost_labels[i]))
	return maxf(SIZE.x, widest + 12.0)

static func _text_width(label: Label) -> float:
	return label.get_theme_font(&"font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size(&"font_size")).x

## STACKED_SIZE while stacked, else SIZE.
func list_size() -> Vector2:
	return STACKED_SIZE if stacked else SIZE

func _row_size() -> Vector2:
	return STACKED_ROW_SIZE if stacked else ROW_SIZE

func _row_tops() -> Array[int]:
	return STACKED_ROW_TOP if stacked else ROW_TOP

func _layout() -> void:
	size = list_size()
	title_label.size.x = size.x
	var row_size := _row_size()
	for i in BuildMenu.LINE_COUNT:
		rows[i].position = Vector2(3, _row_tops()[i])
		rows[i].size = row_size
		name_labels[i].position = Vector2(3, 2)
		name_labels[i].size = Vector2(row_size.x - 6, 8)
		name_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if stacked:
			cost_labels[i].position = Vector2(3, 2 + LINE_HEIGHT)
			cost_labels[i].size = Vector2(row_size.x - 6, 8)
			cost_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			cost_labels[i].position = Vector2(0, 2)
			cost_labels[i].size = Vector2(184, 8)
			cost_labels[i].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.size = list_size()
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
	if shows_mark_above():
		ScrollWindow.draw_mark(self, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, box), true), true)
	if shows_mark_below():
		ScrollWindow.draw_mark(self, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, box), false), false)

## The highlight line, drawn on content so it scrolls and clips with the rows.
func _draw_highlight() -> void:
	if _menu and _menu.highlighted >= 0:
		content.draw_rect(Rect2(Vector2(3, _row_tops()[_menu.highlighted]), _row_size()), HIGHLIGHT)

func _on_row_input(event: InputEvent, i: int) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		row_clicked.emit(i)

func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", 8)
	return label
