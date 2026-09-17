class_name ControlsPage
extends Control
## The Controls page: draws a ControlsMenu over the whole screen and turns input into its moves.
## Instanced by settings_board.tscn.

signal closed              # Back or Leave: the board takes input again on Controls
signal resume_requested    # Start or Leave-after-Start, opened from the pause board

const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const BACKGROUND := Color("#2c1d16")
const TEXT := Color("#fff6e0")
const QUIET := Color("#d9c7a3")         # the fixed line and an ordinary empty slot's dash
const ORANGE := Color("#ffb38a")        # a dash in a row with no key on this tab, and the no-key line
const SLOT_OUTLINE := Color("#ffe27a")
const FONT_SIZE := 8
const HEADING_BASELINE := 11.0
const TAB_RECTS := [Rect2(78, 14, 72, 11), Rect2(154, 14, 88, 11)]   # Keyboard, Controller
const TAB_NAMES := ["Keyboard", "Controller"]
const LIST_X := 16.0
const LIST_W := 288.0
const LIST_TOP := 28.0
const ROW_H := 11.0
const NAME_X := 20.0
const SLOT_XS := [144.0, 212.0]          # left edge of slot 0 and slot 1
const SLOT_W := 60.0
const LINE_BASELINE := 137.0
const FIXED_BASELINES := [147.0, 156.0]
const KEYBOARD_FIXED := ["Menus always use the arrow keys,", "Enter and Esc"]   # one agreed sentence, broken to fit 320
const CONTROLLER_FIXED_WORDS := ["Menus always use the d-pad,", "and"]          # then (A) after the first, (B) after "and"
const RESET_NAMES := ["Reset keyboard to defaults", "Reset controller to defaults"]

var rules: ControlsMenu
var strip: MenuStrip
var change_slot: Callable = func() -> void: pass   # the waiting box, when it exists (tr-eg9.5.4)

func _ready() -> void:
	rules = ControlsMenu.new(InputDevice.controls)
	strip = MenuStrip.new()
	add_child(strip)   # last child: above the box
	strip.show_hint(DeviceHints.Hint.CONTROLS_PAGE)
	for b: ControlsMenu.BoxButton in [ControlsMenu.BoxButton.SAFE, ControlsMenu.BoxButton.OTHER]:
		_box_button(b).gui_input.connect(func(event: InputEvent) -> void:
			if PointerRule.is_move(event):
				rules.box_select(b)
			elif _is_left_press(event):
				_apply(rules.box_press(b))
			else:
				return
			_refresh())
	gui_input.connect(_on_gui_input)
	InputDevice.changed.connect(queue_redraw)
	Display.changed.connect(queue_redraw)
	_refresh()

## Opens the page on the tab of the device used last. from_pause: opened from the Paused board.
func open(from_pause: bool) -> void:
	rules = ControlsMenu.new(InputDevice.controls)   # picks up a model swapped by use_controls
	var device := Controls.Device.KEYBOARD if InputDevice.kind() == DeviceTracker.Kind.KEYBOARD \
		else Controls.Device.CONTROLLER
	rules.open(device, from_pause)
	_refresh()

## The pad family the Controller tab draws.
static func pad_kind() -> DeviceTracker.Kind:
	if InputDevice.kind() != DeviceTracker.Kind.KEYBOARD:
		return InputDevice.kind()
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		return DeviceTracker.family_of(Input.get_joy_name(pads[0]))
	return DeviceTracker.Kind.XBOX

## What a point on the page hits: Vector2i(row, slot), slot -1 on the Reset row; Vector2i(-1, -1) for nothing.
static func hit(point: Vector2, device: Controls.Device) -> Vector2i:
	for r in ControlsMenu.ROWS:
		if not row_rect(r).has_point(point):
			continue
		if r == ControlsMenu.RESET_ROW:
			return Vector2i(r, -1)
		for s in Controls.slot_count(device):
			if slot_rect(r, s).has_point(point):
				return Vector2i(r, s)
		return Vector2i(-1, -1)   # the name part of an action row hits nothing
	return Vector2i(-1, -1)

## The tab under a point, or -1.
static func tab_at(point: Vector2) -> int:
	for i in TAB_RECTS.size():
		if (TAB_RECTS[i] as Rect2).has_point(point):
			return i
	return -1

## The row's rectangle.
static func row_rect(r: int) -> Rect2:
	return Rect2(LIST_X, LIST_TOP + r * ROW_H, LIST_W, ROW_H)

const SHAPES_EMPTY := "! —"   # an empty slot of an action with no key, while Colour cues is Shapes

## What an empty slot draws: SHAPES_EMPTY when the row has no key on this tab (orange) and cues is SHAPES, else "—".
static func empty_slot_mark(orange: bool, cues: DisplayPrefs.Cues) -> String:
	return SHAPES_EMPTY if orange and cues == DisplayPrefs.Cues.SHAPES else "—"

## Top-left of an empty slot's mark in cell: the "—" keeps today's place, so any prefix sits to its left.
static func empty_slot_at(cell: Rect2, mark: String) -> Vector2:
	return (cell.get_center() - Vector2(1, 2)).round() - Vector2((mark.length() - 1) * (Glyphs.W + Glyphs.GAP), 0)

## The slot's cell rectangle (row r, slot s).
static func slot_rect(r: int, s: int) -> Rect2:
	return Rect2(SLOT_XS[s], LIST_TOP + r * ROW_H + 1, SLOT_W, ROW_H - 2)

# The menu step comes first, so Esc (menu_cancel and pause) is Back; Tab and Clear come before Pause.
func _input(event: InputEvent) -> void:
	if not rules.is_open:
		return
	var step := InputDevice.menu_step(event)
	if rules.box != ControlsMenu.Box.NONE:
		match step:
			MenuPush.Step.LEFT:
				rules.box_select(ControlsMenu.BoxButton.SAFE)
			MenuPush.Step.RIGHT:
				rules.box_select(ControlsMenu.BoxButton.OTHER)
			MenuPush.Step.SELECT:
				_apply(rules.box_press(rules.box_selected))
			MenuPush.Step.BACK:
				_apply(rules.box_cancel())
			_:
				return   # Start, tabs and Clear do nothing in a box; the board and the openers ignore input while the page is up
	elif step == MenuPush.Step.UP:
		rules.move(-1)
	elif step == MenuPush.Step.DOWN:
		rules.move(1)
	elif step == MenuPush.Step.LEFT:
		rules.side(-1)
	elif step == MenuPush.Step.RIGHT:
		rules.side(1)
	elif step == MenuPush.Step.SELECT:
		_apply(rules.pick())
	elif step == MenuPush.Step.BACK:
		_apply(rules.back())
	elif event.is_action_pressed("menu_tab", false):
		rules.switch_tab()
	elif event.is_action_pressed("menu_clear", false):
		rules.clear()
	elif event.is_action_pressed("pause", false):
		if not rules.from_pause:
			return
		_apply(rules.start())
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

# The root's mouse when no box is up; the box's Dim stops clicks otherwise. Connected to gui_input.
func _on_gui_input(event: InputEvent) -> void:
	if not rules.is_open or rules.box != ControlsMenu.Box.NONE:
		return
	var m := event as InputEventMouse
	if m == null:
		return
	var tab := tab_at(m.position)
	var h := hit(m.position, rules.device)
	if PointerRule.is_move(event):
		if h.x >= 0:
			rules.hover(h.x, h.y)
	elif _is_left_press(event):
		if tab >= 0:
			rules.set_tab(tab as Controls.Device)
		elif h.x >= 0:
			rules.hover(h.x, h.y)
			_apply(rules.pick())
		else:
			return
	else:
		return
	_refresh()
	accept_event()

func _apply(o: ControlsMenu.Outcome) -> void:
	match o:
		ControlsMenu.Outcome.CHANGE_SLOT:
			change_slot.call()
		ControlsMenu.Outcome.CLOSED:
			_refresh()
			closed.emit()
		ControlsMenu.Outcome.RESUME_PLAY:
			_refresh()
			resume_requested.emit()

func _refresh() -> void:
	InputDevice.set_menu_open(self, rules.is_open)
	visible = rules.is_open
	var box_up := rules.box != ControlsMenu.Box.NONE
	%Box.visible = box_up
	if box_up:
		var reset := rules.box == ControlsMenu.Box.RESET
		%Lines.text = "\n".join(rules.box_lines())
		(%Safe.get_node("Label") as Label).text = "Keep mine" if reset else "Set a key"
		(%Other.get_node("Label") as Label).text = "Reset" if reset else "Leave"
		for b: ControlsMenu.BoxButton in [ControlsMenu.BoxButton.SAFE, ControlsMenu.BoxButton.OTHER]:
			_box_button(b).add_theme_stylebox_override("panel",
					PLANK_HIGHLIGHT_STYLE if rules.box_selected == b else PLANK_STYLE)
	strip.show_hint(DeviceHints.Hint.SELECT_BACK if box_up else DeviceHints.Hint.CONTROLS_PAGE)
	queue_redraw()

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _draw() -> void:
	if rules == null or not rules.is_open:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(0, 0, 320, 180), BACKGROUND)
	_centred(font, "Controls", 160.0, HEADING_BASELINE, TEXT)
	for i in TAB_RECTS.size():
		var rect: Rect2 = TAB_RECTS[i]
		draw_style_box(PLANK_HIGHLIGHT_STYLE if rules.device == i else PLANK_STYLE, rect)
		_centred(font, TAB_NAMES[i], rect.get_center().x, rect.position.y + 9, TEXT)
	var keyboard := rules.device == Controls.Device.KEYBOARD
	var kind := DeviceTracker.Kind.KEYBOARD if keyboard else pad_kind()
	for r in ControlsMenu.ROWS:
		if r == rules.row:
			draw_style_box(PLANK_HIGHLIGHT_STYLE, row_rect(r))
		var name: String = RESET_NAMES[rules.device] if r == ControlsMenu.RESET_ROW else Controls.NAMES[r]
		draw_string(font, Vector2(NAME_X, LIST_TOP + r * ROW_H + 9), name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
		if r == ControlsMenu.RESET_ROW:
			continue
		for s in Controls.slot_count(rules.device):
			var cell := slot_rect(r, s)
			var centre := cell.get_center()
			var e := rules.controls.slot(r as Controls.Action, rules.device, s)
			if e != null:
				var p := DeviceHints.picture_for(e, kind)
				HintLine.draw_picture(self, p, (centre - Vector2(HintLine.picture_width(p) / 2.0, 4.5)).round())
			else:
				var orange := rules.is_orange(r)
				var mark := empty_slot_mark(orange, Display.prefs.cues)
				Glyphs.draw(self, mark, empty_slot_at(cell, mark), ORANGE if orange else QUIET)
			if r == rules.row and s == rules.slot:
				draw_rect(cell, SLOT_OUTLINE, false, 1.0)
	if rules.no_key_line != "":
		_centred(font, rules.no_key_line, 160.0, LINE_BASELINE, ORANGE)
	if keyboard:
		_centred(font, KEYBOARD_FIXED[0], 160.0, FIXED_BASELINES[0], QUIET)
		_centred(font, KEYBOARD_FIXED[1], 160.0, FIXED_BASELINES[1], QUIET)
	else:
		var y: float = FIXED_BASELINES[0]
		var a := DeviceHints.picture_for(_pad_button(JOY_BUTTON_A), kind)
		var b := DeviceHints.picture_for(_pad_button(JOY_BUTTON_B), kind)
		var first := _width(font, CONTROLLER_FIXED_WORDS[0])
		var second := _width(font, CONTROLLER_FIXED_WORDS[1])
		var total := first + 4 + HintLine.picture_width(a) + 4 + second + 4 + HintLine.picture_width(b)
		var x := roundf(160.0 - total / 2.0)
		draw_string(font, Vector2(x, y), CONTROLLER_FIXED_WORDS[0], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, QUIET)
		x += first + 4
		HintLine.draw_picture(self, a, Vector2(x, y - 8))
		x += HintLine.picture_width(a) + 4
		draw_string(font, Vector2(x, y), CONTROLLER_FIXED_WORDS[1], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, QUIET)
		x += second + 4
		HintLine.draw_picture(self, b, Vector2(x, y - 8))

func _width(font: Font, text: String) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x

func _centred(font: Font, text: String, centre_x: float, baseline: float, colour: Color) -> void:
	draw_string(font, Vector2(roundf(centre_x - _width(font, text) / 2.0), baseline), text, HORIZONTAL_ALIGNMENT_LEFT,
		-1, FONT_SIZE, colour)

static func _pad_button(index: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	return e

func _box_button(b: ControlsMenu.BoxButton) -> Control:
	return %Safe if b == ControlsMenu.BoxButton.SAFE else %Other

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed
