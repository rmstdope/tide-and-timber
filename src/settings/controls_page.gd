class_name ControlsPage
extends Control
## The Controls page: draws a ControlsMenu over the whole screen and turns input into its moves.
## Instanced by settings_board.tscn.
## At a scale where its rows no longer fit across the screen, every row goes onto two lines: the name, then its slots.

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
const SCREEN_MARGIN := 2.0
const LIST_X_STACKED := 86.0             # (320 - 148) / 2
const LIST_W_STACKED := 148.0            # fits inside the 160 units a 2x page shows, with margins
const ROW_H_STACKED := 22.0              # the name line, then the slot line
const SLOT_XS_STACKED := [96.0, 164.0]   # two 60-wide slots, 8 apart, centred in the stacked list
const SLOT_TOP_STACKED := 11.0           # row top to slot top
const NAME_LINE_STEP := 10.0             # baseline to baseline when a stacked name wraps
const NAME_WRAP_W := 132.0               # both Reset names break before "to": "Reset keyboard to" (136) does not fit
const TAB_RECTS_STACKED := [Rect2(82, 14, 68, 11), Rect2(154, 14, 84, 11)]

var rules: ControlsMenu
var stacked := false                     # derived by _restack, never set elsewhere
var strip: MenuStrip
var change_slot: Callable = _change_slot   # tests swap in a recorder
var capture := SlotCapture.new()
var pad_connected: Callable = func() -> bool: return not Input.get_connected_joypads().is_empty()   # tests replace it
var _box_normal: BoxLayout   # the box as the scene draws it at Normal, captured once in _ready
var _box_layout: BoxLayout   # the layout drawn now; input reads its `stacked`

func _ready() -> void:
	var box_lines: Array[Control] = [%Lines]
	_box_normal = BoxLayout.of(%Box.get_node("Panel"), box_lines, %Safe, %Other)
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
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	InputDevice.changed.connect(queue_redraw)
	Display.changed.connect(queue_redraw)
	Display.changed.connect(_restack_later)
	get_tree().root.size_changed.connect(_restack_later)
	Display.changed.connect(_fit_box)
	get_tree().root.size_changed.connect(_fit_box)
	_fit_box()
	_refresh()

## Lays the box out for the current UI scale and words: side by side, or stacked when the two buttons
## are too wide; OK alone follows its two-button form.
func _fit_box() -> void:
	var labels: Array[Label] = [%Lines]
	var nodes: Array[Control] = [%Lines]
	_box_layout = _box_normal.at(UiScale.current(Display.prefs, get_tree().root), %Safe.size, %Other.size,
			BoxLayout.label_heights(labels))
	if rules.box == ControlsMenu.Box.NO_PAD:
		_box_layout = _box_layout.one_button()
	_box_layout.place(%Box.get_node("Panel"), nodes, %Safe, %Other)

func _restack() -> void:
	var now := stacks_at(get_global_transform_with_canvas().get_scale().x) if is_inside_tree() else false
	if now != stacked:   # Display.changed already queued a redraw; a second would draw twice
		stacked = now
		queue_redraw()

# Deferred, so the pause layer's or the title's own scale handler has run first.
func _restack_later() -> void:
	_restack.call_deferred()

## True when today's rows, with the screen margins, are wider than the screen at on-screen scale s.
static func stacks_at(s: float) -> bool:
	return (LIST_W + 2.0 * SCREEN_MARGIN) * s > 320.0

## The tab's rectangle.
static func tab_rect(i: int, p_stacked := false) -> Rect2:
	return TAB_RECTS_STACKED[i] if p_stacked else TAB_RECTS[i]

## Baseline of row r's name (its first line).
static func name_origin(r: int, p_stacked := false) -> Vector2:
	return Vector2(LIST_X_STACKED + 4.0, LIST_TOP + r * ROW_H_STACKED + 9.0) if p_stacked \
			else Vector2(NAME_X, LIST_TOP + r * ROW_H + 9.0)

## A name broken at spaces into lines no wider than max_w (greedy, at FONT_SIZE); one line if it fits.
static func name_lines(text: String, max_w: float, font: Font) -> PackedStringArray:
	var lines := PackedStringArray()
	var current := ""
	for word in text.split(" "):
		var candidate := word if current == "" else current + " " + word
		if current == "" or font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x <= max_w:
			current = candidate
		else:
			lines.append(current)
			current = word
	lines.append(current)
	return lines

## Baselines of the no-key line and the two fixed lines, moved down below a stacked list.
static func text_baselines(p_stacked := false) -> Array[float]:
	var drop := ControlsMenu.ROWS * (ROW_H_STACKED - ROW_H) if p_stacked else 0.0
	return [LINE_BASELINE + drop, FIXED_BASELINES[0] + drop, FIXED_BASELINES[1] + drop]

## Opens the page on the tab of the device used last. from_pause: opened from the Paused board.
func open(from_pause: bool) -> void:
	rules = ControlsMenu.new(InputDevice.controls)   # picks up a model swapped by use_controls
	var device := Controls.Device.KEYBOARD if InputDevice.kind() == DeviceTracker.Kind.KEYBOARD \
		else Controls.Device.CONTROLLER
	rules.open(device, from_pause)
	_restack()
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
static func hit(point: Vector2, device: Controls.Device, p_stacked := false) -> Vector2i:
	for r in ControlsMenu.ROWS:
		if not row_rect(r, p_stacked).has_point(point):
			continue
		if r == ControlsMenu.RESET_ROW:
			return Vector2i(r, -1)
		for s in Controls.slot_count(device):
			if slot_rect(r, s, p_stacked).has_point(point):
				return Vector2i(r, s)
		return Vector2i(-1, -1)   # the name part of an action row hits nothing
	return Vector2i(-1, -1)

## The tab under a point, or -1.
static func tab_at(point: Vector2, p_stacked := false) -> int:
	for i in TAB_RECTS.size():
		if tab_rect(i, p_stacked).has_point(point):
			return i
	return -1

## The row's rectangle.
static func row_rect(r: int, p_stacked := false) -> Rect2:
	if p_stacked:
		return Rect2(LIST_X_STACKED, LIST_TOP + r * ROW_H_STACKED, LIST_W_STACKED, ROW_H_STACKED)
	return Rect2(LIST_X, LIST_TOP + r * ROW_H, LIST_W, ROW_H)

const SHAPES_EMPTY := "! —"   # an empty slot of an action with no key, while Colour cues is Shapes

## What an empty slot draws: SHAPES_EMPTY when the row has no key on this tab (orange) and cues is SHAPES, else "—".
static func empty_slot_mark(orange: bool, cues: DisplayPrefs.Cues) -> String:
	return SHAPES_EMPTY if orange and cues == DisplayPrefs.Cues.SHAPES else "—"

## Top-left of an empty slot's mark in cell: the "—" keeps today's place, so any prefix sits to its left.
static func empty_slot_at(cell: Rect2, mark: String) -> Vector2:
	return (cell.get_center() - Vector2(1, 2)).round() - Vector2((mark.length() - 1) * (Glyphs.W + Glyphs.GAP), 0)

## The slot's cell rectangle (row r, slot s).
static func slot_rect(r: int, s: int, p_stacked := false) -> Rect2:
	if p_stacked:
		return Rect2(SLOT_XS_STACKED[s], LIST_TOP + r * ROW_H_STACKED + SLOT_TOP_STACKED, SLOT_W, ROW_H - 2)
	return Rect2(SLOT_XS[s], LIST_TOP + r * ROW_H + 1, SLOT_W, ROW_H - 2)

# The menu step comes first, so Esc (menu_cancel and pause) is Back; Tab and Clear come before Pause.
# While waiting, every event goes to the capture and is consumed, so Esc and Start go in, not Back or Pause.
func _input(event: InputEvent) -> void:
	if not rules.is_open:
		return
	if capture.swallows(event):
		get_viewport().set_input_as_handled()
		return
	if rules.box == ControlsMenu.Box.WAITING:
		_take(capture.read(event))
		get_viewport().set_input_as_handled()
		return
	var step := InputDevice.menu_step(event)
	if rules.box != ControlsMenu.Box.NONE:
		match step:
			MenuPush.Step.LEFT:
				rules.box_select(ControlsMenu.BoxButton.SAFE)
			MenuPush.Step.RIGHT:
				rules.box_select(ControlsMenu.BoxButton.OTHER)
			MenuPush.Step.UP:
				if not _box_layout.stacked:
					return   # side by side, Up and Down do nothing in a box, as before
				rules.box_select(ControlsMenu.BoxButton.SAFE)
			MenuPush.Step.DOWN:
				if not _box_layout.stacked:
					return
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
	elif InputDevice.action_pressed(event, "pause"):
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
	var tab := tab_at(m.position, stacked)
	var h := hit(m.position, rules.device, stacked)
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

func _process(delta: float) -> void:
	if rules.box == ControlsMenu.Box.WAITING:
		_take(capture.advance(delta))

func _change_slot() -> void:
	rules.begin_change(pad_connected.call())
	if rules.box == ControlsMenu.Box.WAITING:
		capture.open(rules.device, SlotCapture.held_axes_now())
	_refresh()

func _take(result: SlotCapture.Result) -> void:
	match result:
		SlotCapture.Result.TAKEN:
			rules.finish_change(capture.taken)
			_refresh()
		SlotCapture.Result.CANCELLED:
			rules.finish_change(null)
			_refresh()
		_:
			(%WaitingBox as WaitingBox).set_progress(capture.hold_progress)

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if connected or rules.box != ControlsMenu.Box.WAITING or rules.device != Controls.Device.CONTROLLER:
		return
	capture.close()
	rules.pad_disconnected()
	_refresh()

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
	var waiting := rules.box == ControlsMenu.Box.WAITING
	var box_up := rules.box != ControlsMenu.Box.NONE and not waiting
	%Box.visible = box_up
	var waiting_box := %WaitingBox as WaitingBox
	waiting_box.visible = waiting
	if waiting:
		waiting_box.show_for(rules.box_lines(), WaitingBox.hold_items(rules.device, pad_kind()), capture.hold_progress)
	if box_up:
		var reset := rules.box == ControlsMenu.Box.RESET
		var no_pad := rules.box == ControlsMenu.Box.NO_PAD
		%Lines.text = "\n".join(rules.box_lines())
		(%Safe.get_node("Label") as Label).text = "OK" if no_pad else "Keep mine" if reset else "Set a key"
		(%Other.get_node("Label") as Label).text = "Reset" if reset else "Leave"
		%Other.visible = not no_pad
		_fit_box()
		for b: ControlsMenu.BoxButton in [ControlsMenu.BoxButton.SAFE, ControlsMenu.BoxButton.OTHER]:
			_box_button(b).add_theme_stylebox_override("panel",
					PLANK_HIGHLIGHT_STYLE if rules.box_selected == b else PLANK_STYLE)
	strip.visible = not waiting
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
		var rect := tab_rect(i, stacked)
		draw_style_box(PLANK_HIGHLIGHT_STYLE if rules.device == i else PLANK_STYLE, rect)
		_centred(font, TAB_NAMES[i], rect.get_center().x, rect.position.y + 9, TEXT)
	var keyboard := rules.device == Controls.Device.KEYBOARD
	var kind := DeviceTracker.Kind.KEYBOARD if keyboard else pad_kind()
	for r in ControlsMenu.ROWS:
		if r == rules.row:
			draw_style_box(PLANK_HIGHLIGHT_STYLE, row_rect(r, stacked))
		var name: String = RESET_NAMES[rules.device] if r == ControlsMenu.RESET_ROW else Controls.NAMES[r]
		var lines := name_lines(name, NAME_WRAP_W, font) if stacked else PackedStringArray([name])
		for j in lines.size():
			draw_string(font, name_origin(r, stacked) + Vector2(0, j * NAME_LINE_STEP), lines[j],
					HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT)
		if r == ControlsMenu.RESET_ROW:
			continue
		for s in Controls.slot_count(rules.device):
			var cell := slot_rect(r, s, stacked)
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
	var baselines := text_baselines(stacked)
	if rules.no_key_line != "":
		_centred(font, rules.no_key_line, 160.0, baselines[0], ORANGE)
	if keyboard:
		_centred(font, KEYBOARD_FIXED[0], 160.0, baselines[1], QUIET)
		_centred(font, KEYBOARD_FIXED[1], 160.0, baselines[2], QUIET)
	else:
		var y: float = baselines[1]
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
