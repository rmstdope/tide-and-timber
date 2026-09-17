class_name DebugPanel
extends Control
## The Debug panel down the right side: draws a DebugMenu and turns input into its moves. Instanced by pause.tscn in debug builds.

signal closed              # Esc / B: the pause board takes input again on Debug
signal resume_requested    # Start, or a row's RESUME: the pause board resumes play

const BOARD_STYLE := preload("res://src/pause/board.tres")
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const PANEL_RECT := Rect2(176, 0, 144, 164)
const TITLE := "Debug"
const FONT_SIZE := 8
const TITLE_BASELINE := 13.0
const TAB_X := 180.0
const TAB_Y := 20.0
const TAB_STEP := 23.0
const TAB_SIZE := Vector2(22, 11)
const ROW_X := 182.0
const ROW_TOP := 36.0
const ROW_STEP := 14.0
const ROW_SIZE := Vector2(132, 12)
const LIST_RECT := Rect2(178, 34, 140, 128)
const TEXT := Color("#fff6e0")
const VALUE := Color("#ffe2a8")
const TAB_ON := Color("#c98a4a")
const TAB_OFF := Color("#4a2e1a")
const STORY_DIM := Color(0, 0, 0, 0.45)
const SHAKE_STEPS: Array[float] = [1.0, -1.0, 1.0, 0.0]   # px, each Shake.WIGGLE_STEP seconds

var rules := DebugMenu.new()
var strip: MenuStrip
var shaking_row := -1       # row index being shaken, -1 when none
var shake_x := 0.0          # its current x offset
var _shake_tween: Tween

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	strip = MenuStrip.new()
	add_child(strip)
	strip.show_hint(DeviceHints.Hint.DEBUG_PANEL)
	gui_input.connect(_on_gui_input)
	InputDevice.changed.connect(queue_redraw)
	_refresh()

## Opens on the Time page's first row. in_story: opened from the shipwreck story.
func open(in_story: bool) -> void:
	rules.open(in_story)
	_refresh()

## Tab i's rectangle.
static func tab_rect(i: int) -> Rect2:
	return Rect2(TAB_X + i * TAB_STEP, TAB_Y, TAB_SIZE.x, TAB_SIZE.y)

## The on-screen row slot's rectangle (0 .. VISIBLE_ROWS - 1).
static func row_rect(slot: int) -> Rect2:
	return Rect2(ROW_X, ROW_TOP + slot * ROW_STEP, ROW_SIZE.x, ROW_SIZE.y)

## The tab under a point, or -1.
static func tab_at(point: Vector2) -> int:
	for i in DebugMenu.TAB_NAMES.size():
		if tab_rect(i).has_point(point):
			return i
	return -1

## The row slot under a point, or -1.
static func slot_at(point: Vector2) -> int:
	for slot in DebugMenu.VISIBLE_ROWS:
		if row_rect(slot).has_point(point):
			return slot
	return -1

## -1 for Q or the left shoulder, 1 for E or the right shoulder, 0 for anything else (read only after menu_tab matched).
static func tab_step(event: InputEvent) -> int:
	return MenuTab.step(event)   # raw key reads live in src/input

## What a row's value draws: "" when it has none; "← v →" when highlighted and Left/Right change it; else v.
static func value_shown(row: DebugRow, highlighted: bool) -> String:
	var v := row.value_text()
	if v == "":
		return ""
	return "← %s →" % v if highlighted and row.step.is_valid() else v

# The menu step is checked before the pause action: Esc is both, and means Back here.
func _input(event: InputEvent) -> void:
	if not rules.is_open:
		return
	var step := InputDevice.menu_step(event)
	if step == MenuPush.Step.UP:
		rules.move(-1)
	elif step == MenuPush.Step.DOWN:
		rules.move(1)
	elif step == MenuPush.Step.LEFT:
		rules.change(-1)   # handled even when nothing changes: the panel is modal
	elif step == MenuPush.Step.RIGHT:
		rules.change(1)
	elif step == MenuPush.Step.SELECT:
		_apply(rules.pick())
	elif step == MenuPush.Step.BACK:
		_apply(rules.back())
	elif event.is_action_pressed("menu_tab", false) and tab_step(event) != 0:
		rules.flip(tab_step(event))
	elif InputDevice.action_pressed(event, "pause"):
		_apply(rules.start())
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

# The pointer: hovering a row highlights it, clicking a row selects it, clicking a tab opens that page.
func _on_gui_input(event: InputEvent) -> void:
	if not rules.is_open:
		return
	var m := event as InputEventMouse
	if m == null:
		return
	var slot := slot_at(m.position)
	var index := rules.scroll + slot if slot >= 0 else -1
	var on_row := index >= 0 and index < rules.rows_of(rules.page).size()
	var click := event as InputEventMouseButton
	if PointerRule.is_move(event):
		if not on_row:
			return
		rules.hover(index)
	elif click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		var tab := tab_at(m.position)
		if tab >= 0:
			rules.set_page(tab as DebugMenu.Page)
		elif on_row:
			rules.hover(index)
			_apply(rules.pick())
		else:
			return
	else:
		return
	_refresh()
	accept_event()

func _apply(o: DebugMenu.Outcome) -> void:
	match o:
		DebugMenu.Outcome.SHAKE:
			_shake(rules.highlighted)
		DebugMenu.Outcome.CLOSED:
			_refresh()
			closed.emit()
		DebugMenu.Outcome.RESUME_PLAY:
			_refresh()
			resume_requested.emit()

func _shake(index: int) -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()   # a second refusal restarts the shake rather than racing the first
	shaking_row = index
	var t := create_tween()
	_shake_tween = t
	var from := 0.0
	for x in SHAKE_STEPS:
		t.tween_method(_set_shake_x, from, x, Shake.WIGGLE_STEP)
		from = x
	t.tween_callback(func() -> void:
		shaking_row = -1
		shake_x = 0.0
		queue_redraw())

func _set_shake_x(x: float) -> void:
	shake_x = x
	queue_redraw()

func _refresh() -> void:
	InputDevice.set_menu_open(self, rules.is_open)
	visible = rules.is_open
	queue_redraw()

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _draw() -> void:
	if not rules.is_open:
		return
	draw_style_box(BOARD_STYLE, PANEL_RECT)
	var font := get_theme_default_font()
	var title_w := font.get_string_size(TITLE, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	draw_string(font, Vector2(roundf(PANEL_RECT.get_center().x - title_w / 2.0), TITLE_BASELINE), TITLE,
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
	for i in DebugMenu.TAB_NAMES.size():
		var rect := tab_rect(i)
		var name: String = DebugMenu.TAB_NAMES[i]
		draw_rect(rect, TAB_ON if i == rules.page else TAB_OFF)
		Glyphs.draw(self, name, Vector2(rect.position.x + roundi((TAB_SIZE.x - Glyphs.width(name)) / 2.0), TAB_Y + 3), TEXT)
	var rows := rules.rows_of(rules.page)
	for slot in mini(DebugMenu.VISIBLE_ROWS, rows.size() - rules.scroll):
		var index := rules.scroll + slot
		var row := rows[index]
		var rect := row_rect(slot)
		if index == shaking_row:
			rect.position.x += shake_x
		var lit := index == rules.highlighted
		draw_style_box(PLANK_HIGHLIGHT_STYLE if lit else PLANK_STYLE, rect)
		Glyphs.draw(self, row.label, rect.position + Vector2(5, 3), TEXT)
		var v := value_shown(row, lit)
		if v != "":
			Glyphs.draw(self, v, Vector2(rect.end.x - 5 - Glyphs.width(v), rect.position.y + 3), VALUE)
	if not rules.page_works(rules.page):
		draw_rect(LIST_RECT, STORY_DIM)
