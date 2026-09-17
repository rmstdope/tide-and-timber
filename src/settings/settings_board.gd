class_name SettingsBoard
extends Control
## The Settings board over a dim: draws a SettingsMenu and turns input into its moves.
## Instanced by the title screen and by pause.tscn.
## At a scale where its rows no longer fit across the screen, every row goes onto two lines and the panel narrows to fit.
## When its content is taller than the screen above its strip, the panel is framed to fit and the content scrolls
## to the highlight, with ▲ / ▼ where rows are hidden.

signal closed              # Back: the opener highlights its Settings plank again
signal resume_requested    # the Pause input, opened from the pause board: the opener resumes play

const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const BOARD_X := 8.0
const BOARD_W := 304.0
const BOARD_H := 138.0          # heading, four rows, the two-line explaining line, bottom margin
const PLANK_X := 52.0           # rows centred: (304 - 200) / 2
const PLANK_TOP := 28.0
const PLANK_STEP := 20.0
const PLANK_SIZE := Vector2(200, 16)
const BASE_HEIGHT := 180.0
const TEXT := Color(1, 0.964706, 0.878431, 1)
const ARROW_DIM := Color(0.627451, 0.501961, 0.376471, 1)   # #a08060, an end's arrow
const FONT_SIZE := 8
const LINE_SPACING := 2.0          # %Line's theme line_spacing
const SCREEN_MARGIN := 2.0         # kept clear at each side of the screen, in board units
const PANEL_SIDE := 4.0            # panel edge to a stacked plank
const LINE_SIDE := 12.0            # panel edge to the line under the list
const LINE_GAP := 8.0              # last plank's bottom to the line's top
const BOTTOM_MARGIN := 8.0         # the line's bottom to the panel's bottom
const STACKED_PLANK_H := 28.0      # two 12-unit lines inside the plank's 2-unit border
const STACKED_STEP := 32.0
const HEADING_TOP := 8.0           # panel top to the heading's top; the scrolled content starts here
const VALUE_WORDS := {
	DisplayPrefs.Setting.UI_SIZE: ["Normal", "Large", "Largest"],
	DisplayPrefs.Setting.TEXT_SIZE: ["Normal", "Large", "Largest"],
	DisplayPrefs.Setting.CUES: ["Standard", "Shapes"],
}
const LINES := {
	SettingsMenu.Plank.UI_SIZE: "Makes the clock, item bar, hints and menus bigger.",
	SettingsMenu.Plank.TEXT_SIZE: "Makes every word bigger.",
	SettingsMenu.Plank.COLOUR_CUES: "Adds shapes to warnings shown in colour.",
	SettingsMenu.Plank.CONTROLS: "Change any key or controller button.",
}

var rules := SettingsMenu.new()
var strip: MenuStrip
var open_controls: Callable = _open_controls   # tests replace it
var stacked := false               # the rows are on two lines; derived by lay_out, never set elsewhere
var offset := 0                    # whole units the content is scrolled up; 0 while it fits. Owned by frame()
var scrolls := false               # the content does not fit the band; derived by frame(), never set elsewhere
var rest_panel := Rect2(BOARD_X, 21, BOARD_W, BOARD_H)   # lay_out's centred panel, before framing

## The panel's width at on-screen scale s: BOARD_W, or less so it fits the screen with SCREEN_MARGIN each side.
static func panel_width(s: float) -> float:
	return minf(BOARD_W, floorf(320.0 / s - 2.0 * SCREEN_MARGIN))

## True when a plank widest_row wide, with the panel's sides and the screen margins, is wider than the screen at s.
static func stacks(widest_row: float, s: float) -> bool:
	return (widest_row + 2.0 * PANEL_SIDE + 2.0 * SCREEN_MARGIN) * s > 320.0

## How many lines text takes wrapped at width, as an autowrap-smart Label draws it.
static func line_count(text: String, width: float, font: Font, font_size: int) -> int:
	var p := TextParagraph.new()
	p.add_string(text, font, font_size)
	p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	p.width = width
	return p.get_line_count()

## The widest plank's width with its row on one line: PLANK_SIZE.x, or more if its words need it.
## Reads each Row child's combined minimum width, so call it only with every Row/Label's custom_minimum_size.x at 0.
func side_by_side_width() -> float:
	var widest := PLANK_SIZE.x
	for item: SettingsMenu.Plank in rules.items:
		var w := PLANK_STYLE.get_minimum_size().x
		for child: Node in _plank(item).get_node("Row").get_children():
			var c := child as Control
			if c != null and c.visible:
				w += c.get_combined_minimum_size().x
		widest = maxf(widest, w)
	return widest

## Places the panel, the planks, the heading and the line for on-screen scale s, and sets `stacked`.
func lay_out(s: float) -> void:
	for item: SettingsMenu.Plank in rules.items:
		(_plank(item).get_node("Row/Label") as Control).custom_minimum_size.x = 0
	var widest := side_by_side_width()
	stacked = stacks(widest, s)
	var panel_w := panel_width(s)
	var plank_w := panel_w - 2.0 * PANEL_SIDE if stacked else widest
	var plank_h := STACKED_PLANK_H if stacked else PLANK_SIZE.y
	var step := STACKED_STEP if stacked else PLANK_STEP
	var plank_x := floorf((panel_w - plank_w) / 2.0)
	for i in rules.items.size():
		var plank := _plank(rules.items[i])
		plank.custom_minimum_size = Vector2(plank_w, plank_h)
		plank.position = Vector2(plank_x, PLANK_TOP + i * step)
		plank.size = Vector2(plank_w, plank_h)
		if stacked:
			var label_w := plank_w - PLANK_STYLE.get_minimum_size().x \
					- (plank.get_node("Row/Pad") as Control).custom_minimum_size.x
			if plank.has_node("Row/Arrow"):
				label_w -= (plank.get_node("Row/Arrow") as Control).custom_minimum_size.x
			(plank.get_node("Row/Label") as Control).custom_minimum_size.x = label_w
	var line_top := PLANK_TOP + (rules.items.size() - 1) * step + plank_h + LINE_GAP
	var line_w := panel_w - 2.0 * LINE_SIDE
	var line := %Line as Label
	var lines := 1
	for text: String in LINES.values():
		lines = maxi(lines, line_count(text, line_w, line.get_theme_font("font"), FONT_SIZE))
	var line_h := lines * FONT_SIZE + (lines - 1) * LINE_SPACING
	line.position = Vector2(LINE_SIDE, line_top)
	line.size.x = line_w
	line.size.y = line_h
	(%Heading as Control).size.x = panel_w
	var panel_h := line_top + line_h + BOTTOM_MARGIN
	rest_panel = Rect2(floorf((320.0 - panel_w) / 2.0), floorf((BASE_HEIGHT - panel_h) / 2.0), panel_w, panel_h)
	(%Content as Control).size = rest_panel.size
	_frame()

## Frames the panel to the band [band_top, band_bottom] (board units) and scrolls the content so the
## highlighted plank is wholly visible. Reads rest_panel and the planks' positions; sets offset and scrolls.
func frame(band_top: float, band_bottom: float) -> void:
	var band_h := band_bottom - band_top
	var w := rest_panel.size.x
	if rest_panel.size.y <= band_h:
		scrolls = false
		offset = 0
		%Panel.position = Vector2(rest_panel.position.x,
				clampf(rest_panel.position.y, band_top, band_bottom - rest_panel.size.y))
		%Panel.size = rest_panel.size
		(%Clip as Control).position = Vector2.ZERO
		(%Clip as Control).size = rest_panel.size
		(%Content as Control).position = Vector2.ZERO
	else:
		scrolls = true
		var view_h := band_h - 2.0 * ScrollWindow.MARK_ROW
		var e := _item_extent(rules.highlighted)
		offset = ScrollWindow.follow(_content_height(), view_h, e.x, e.y, offset)
		# The plank itself is made wholly visible, in case its extent was taller than the view.
		var p := _plank(rules.highlighted)
		offset = ScrollWindow.follow(_content_height(), view_h,
				p.position.y - HEADING_TOP, p.position.y + p.size.y - HEADING_TOP, offset)
		%Panel.position = Vector2(rest_panel.position.x, band_top)
		%Panel.size = Vector2(w, band_h)
		(%Clip as Control).position = Vector2(0, ScrollWindow.MARK_ROW)
		(%Clip as Control).size = Vector2(w, view_h)
		(%Content as Control).position = Vector2(0, -(HEADING_TOP + offset))
	(%Marks as Control).position = Vector2.ZERO
	(%Marks as Control).size = (%Panel as Control).size
	%Marks.queue_redraw()

## True while ▲ is drawn: scrolling, with content hidden above.
func shows_mark_above() -> bool:
	return scrolls and ScrollWindow.hidden_above(offset)

## True while ▼ is drawn: scrolling, with content hidden below.
func shows_mark_below() -> bool:
	return scrolls and ScrollWindow.hidden_below(offset, _content_height(), (%Clip as Control).size.y)

# The scrolled content: the heading's top to the line's bottom. The mark rows replace the panel's margins.
func _content_height() -> float:
	return rest_panel.size.y - HEADING_TOP - BOTTOM_MARGIN

# The plank's extent within the scrolled content. The first reaches up to the heading, and the last down to
# the line's bottom, so moving to an end brings what explains the list into view.
func _item_extent(item: SettingsMenu.Plank) -> Vector2:
	var p := _plank(item)
	var top := p.position.y - HEADING_TOP
	var bottom := top + p.size.y
	if item == rules.items[0]:
		top = 0.0
	if item == rules.items[rules.items.size() - 1]:
		bottom = _content_height()
	return Vector2(top, bottom)

func _frame() -> void:
	if not is_inside_tree() or strip == null:
		frame(0.0, BASE_HEIGHT)
		return
	var b := ScrollWindow.band(get_global_transform_with_canvas(), strip.screen_top())
	frame(b.x, b.y)

func _draw_marks() -> void:
	var marks := %Marks as Control
	if shows_mark_above():
		ScrollWindow.draw_mark(marks, Vector2(marks.size.x / 2.0, ScrollWindow.MARK_ROW / 2.0), true)
	if shows_mark_below():
		ScrollWindow.draw_mark(marks, Vector2(marks.size.x / 2.0, marks.size.y - ScrollWindow.MARK_ROW / 2.0), false)

func _ready() -> void:
	%ControlsPage.closed.connect(_on_controls_closed)
	%ControlsPage.resume_requested.connect(_on_controls_resume)
	%Marks.draw.connect(_draw_marks)
	for i in rules.items.size():
		var item := rules.items[i]
		var plank := _plank(item)
		plank.gui_input.connect(func(event: InputEvent) -> void:
			if PointerRule.is_move(event):
				rules.hover(item)
				_refresh()
			elif _is_left_press(event):
				_apply(rules.pick(item))
				_refresh())
	# The arrows stop the mouse, so they carry their row's hover as well as their own step.
	for item: SettingsMenu.Plank in SettingsMenu.SETTING_OF:
		for pair: Array in [[_plank(item).get_node("Row/Prev"), -1], [_plank(item).get_node("Row/Next"), 1]]:
			var arrow: Control = pair[0]
			var delta: int = pair[1]
			arrow.gui_input.connect(func(event: InputEvent) -> void:
				if PointerRule.is_move(event):
					rules.hover(item)
					_refresh()
				elif _is_left_press(event):
					rules.change(item, delta, Display.prefs)
					_refresh()
					arrow.accept_event())
	strip = MenuStrip.new()
	add_child(strip)   # last child: above the panel
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	Display.changed.connect(_refresh)
	Display.changed.connect(_lay_out_later)
	get_tree().root.size_changed.connect(_lay_out_later)
	_lay_out()
	_refresh()

func _lay_out() -> void:
	lay_out(get_global_transform_with_canvas().get_scale().x if is_inside_tree() else 1.0)

# Deferred: the pause layer's and the title's scale handlers listen to the same signals; by frame end the scale is final.
func _lay_out_later() -> void:
	_lay_out.call_deferred()

## Opens the board. from_pause: opened from the Paused board.
func open(from_pause: bool) -> void:
	if rules.open(from_pause):
		offset = 0
		_lay_out()
		_refresh()

func _open_controls() -> void:
	rules.show_controls()
	%ControlsPage.open(rules.from_pause)
	_refresh()

func _on_controls_closed() -> void:
	rules.close_controls()
	_refresh()

func _on_controls_resume() -> void:
	_apply(rules.resume_from_controls())

# The menu step is checked before the pause action: Esc is both, and means Back here.
func _input(event: InputEvent) -> void:
	if not rules.is_open or rules.controls_open:
		return
	var step := InputDevice.menu_step(event)
	if step == MenuPush.Step.UP:
		rules.move(-1)
	elif step == MenuPush.Step.DOWN:
		rules.move(1)
	elif step == MenuPush.Step.LEFT:
		rules.change(rules.highlighted, -1, Display.prefs)   # handled even at an end: the board is modal
	elif step == MenuPush.Step.RIGHT:
		rules.change(rules.highlighted, 1, Display.prefs)
	elif step == MenuPush.Step.SELECT:
		_apply(rules.pick(rules.highlighted))
	elif step == MenuPush.Step.BACK:
		_apply(rules.back())
	elif InputDevice.action_pressed(event, "pause"):
		var o := rules.start()
		if o == SettingsMenu.Outcome.NONE:
			return
		_apply(o)
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _apply(o: SettingsMenu.Outcome) -> void:
	match o:
		SettingsMenu.Outcome.OPEN_CONTROLS:
			open_controls.call()
		SettingsMenu.Outcome.CLOSED:
			_refresh()
			closed.emit()
		SettingsMenu.Outcome.RESUME_PLAY:
			_refresh()
			resume_requested.emit()

func _refresh() -> void:
	InputDevice.set_menu_open(self, rules.is_open)
	visible = rules.is_open
	%Panel.visible = not rules.controls_open
	strip.visible = not rules.controls_open
	for item: SettingsMenu.Plank in rules.items:
		_plank(item).add_theme_stylebox_override("panel",
				PLANK_HIGHLIGHT_STYLE if rules.highlighted == item else PLANK_STYLE)
	for item: SettingsMenu.Plank in SettingsMenu.SETTING_OF:
		var s: DisplayPrefs.Setting = SettingsMenu.SETTING_OF[item]
		var v := Display.prefs.value(s)
		var row := _plank(item)
		(row.get_node("Row/Value") as Label).text = VALUE_WORDS[s][v]
		row.get_node("Row/Prev").add_theme_color_override("font_color", ARROW_DIM if v == 0 else TEXT)
		row.get_node("Row/Next").add_theme_color_override("font_color",
				ARROW_DIM if v == DisplayPrefs.count(s) - 1 else TEXT)
	%Line.text = LINES[rules.highlighted]
	if rules.is_open:
		_frame()

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _plank(item: SettingsMenu.Plank) -> Control:
	match item:
		SettingsMenu.Plank.UI_SIZE:
			return %UiSize
		SettingsMenu.Plank.TEXT_SIZE:
			return %TextSize
		SettingsMenu.Plank.COLOUR_CUES:
			return %ColourCues
		SettingsMenu.Plank.CONTROLS:
			return %Controls
	assert(false, "no node for plank %d" % item)
	return null

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed
