class_name SettingsBoard
extends Control
## The Settings board over a dim: draws a SettingsMenu and turns input into its moves.
## Instanced by the title screen and by pause.tscn.
## At a scale where its rows no longer fit the board, every row goes onto two lines and the panel narrows to fit.
## When its content is taller than the screen above its strip, the panel is framed to fit and the content scrolls
## to the highlight, with ▲ / ▼ where rows are hidden.

signal closed              # Back: the opener highlights its Settings plank again
signal resume_requested    # the Pause input, opened from the pause board: the opener resumes play

const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const BOARD_W := 312.0
const BOARD_X := (Screen.WIDTH - BOARD_W) / 2.0   # the board centred
const BOARD_H := 158.0          # heading, five rows, the two-line explaining line, bottom margin
const PLANK_X := 56.0           # rows centred: (312 - 200) / 2
const PLANK_TOP := 28.0
const PLANK_STEP := 20.0
const PLANK_SIZE := Vector2(200, 16)
const ARROW_DIM := Color(0.627451, 0.501961, 0.376471, 1)   # #a08060, an end's arrow
const FONT_SIZE := 8
const LINE_SPACING := 2.0          # %Line's theme line_spacing
const SCREEN_MARGIN := 2.0         # kept clear at each side of the screen, in board units
const PANEL_SIDE := 8.0            # panel edge to a stacked plank: the rim (6) and 2
const LINE_SIDE := 16.0            # panel edge to the line under the list
const LINE_GAP := 8.0              # last plank's bottom to the line's top
const BOTTOM_MARGIN := 8.0         # the line's bottom to the panel's bottom
const PLANK_GAP := 4.0             # the gap below each plank (PLANK_STEP - PLANK_SIZE.y)
const HEADING_TOP := 8.0           # panel top to the heading's top; the scrolled content starts here
const VALUE_WORDS := {
	DisplayPrefs.Setting.UI_SIZE: ["Normal", "Large", "Largest"],
	DisplayPrefs.Setting.TEXT_SIZE: ["Normal", "Large", "Largest"],
	DisplayPrefs.Setting.CUES: ["Standard", "Shapes"],
	DisplayPrefs.Setting.FULLSCREEN: ["Off", "On"],
}
const LINES := {
	SettingsMenu.Plank.UI_SIZE: "Makes the clock, item bar, hints and menus bigger.",
	SettingsMenu.Plank.TEXT_SIZE: "Makes every word bigger.",
	SettingsMenu.Plank.COLOUR_CUES: "Adds shapes to warnings shown in colour.",
	SettingsMenu.Plank.CONTROLS: "Change any key or controller button.",
}
## The Fullscreen row's line names the shortcut for this platform, so it is not in LINES.
const FULLSCREEN_LINES := {
	true: "Fills the whole screen. Cmd+Enter also switches.",    # macOS
	false: "Fills the whole screen. Alt+Enter also switches.",   # Windows, Linux
}

var rules := SettingsMenu.new()
var mac := OS.get_name() == "macOS"   # which shortcut the Fullscreen line names; tests set it before lay_out
var strip: MenuStrip
var open_controls: Callable = _open_controls   # tests replace it
var stacked := false               # the rows are on two lines; derived by lay_out, never set elsewhere
var offset := 0                    # whole units the content is scrolled up; 0 while it fits. Owned by frame()
var scrolls := false               # the content does not fit the band; derived by frame(), never set elsewhere
var rest_panel := Rect2(BOARD_X, floorf((Screen.HEIGHT - BOARD_H) / 2.0), BOARD_W, BOARD_H)   # lay_out's centred panel, before framing

## The panel's width at on-screen scale s: BOARD_W, or less so it fits the screen with SCREEN_MARGIN each side.
static func panel_width(s: float) -> float:
	return minf(BOARD_W, floorf(Screen.WIDTH / s - 2.0 * SCREEN_MARGIN))

## True when a plank widest_row wide, with the panel's sides, does not fit the panel at s.
## panel_width(s) is already the smaller of the board and the screen, so this covers both.
static func stacks(widest_row: float, s: float) -> bool:
	return widest_row + 2.0 * PANEL_SIDE > panel_width(s)

## How many lines text takes wrapped at width, as an autowrap-smart Label draws it.
static func line_count(text: String, width: float, font: Font, font_size: int) -> int:
	return GrownWords.line_count(text, width, font, font_size)

## The widest plank's width with its row on one line: PLANK_SIZE.x, or more if its words need it.
## Reads each Row child's combined minimum width, so call it only with every Row/Label holder's
## custom_minimum_size.x at 0 and max_width at INF.
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
## The height of cells of these sizes flowed left to right into rows `width` wide, as an HFlowContainer with
## no separation lays them: a cell starts a new row when it is not first on its row and would pass width.
static func flow_height(sizes: Array[Vector2], width: float) -> float:
	var x := 0.0
	var y := 0.0
	var row_h := 0.0
	for c: Vector2 in sizes:
		if x > 0.0 and x + c.x > width:
			y += row_h
			x = 0.0
			row_h = 0.0
		x += c.x
		row_h = maxf(row_h, c.y)
	return y + row_h

func lay_out(s: float, retry: bool = true) -> void:
	var rel := TextScale.relative(Display.prefs, get_tree().root)
	for item: SettingsMenu.Plank in rules.items:
		var label := _plank(item).get_node("Row/Label") as GrownWords
		label.custom_minimum_size.x = 0
		label.max_width = INF
	var widest := side_by_side_width()
	stacked = stacks(widest, s)
	var panel_w := panel_width(s)
	var plank_w := panel_w - 2.0 * PANEL_SIDE if stacked else widest
	var inner := plank_w - PLANK_STYLE.get_minimum_size().x
	if stacked:
		for item: SettingsMenu.Plank in rules.items:
			var plank := _plank(item)
			var label := plank.get_node("Row/Label") as GrownWords
			var pad := (plank.get_node("Row/Pad") as Control).custom_minimum_size.x
			label.max_width = inner - pad
			if plank.has_node("Row/Arrow"):
				label.custom_minimum_size.x = inner - pad \
						- (plank.get_node("Row/Arrow") as Control).get_combined_minimum_size().x
			else:
				label.custom_minimum_size.x = inner - pad
	var plank_h := 0.0
	for item: SettingsMenu.Plank in rules.items:
		var sizes: Array[Vector2] = []
		for child: Node in _plank(item).get_node("Row").get_children():
			var c := child as Control
			if c != null and c.visible:
				sizes.append(c.get_combined_minimum_size())
		plank_h = maxf(plank_h, PLANK_STYLE.get_minimum_size().y + flow_height(sizes, inner))
	var step := plank_h + PLANK_GAP
	var plank_x := floorf((panel_w - plank_w) / 2.0)
	var settled := true          # false when a plank could not yet shrink to the height we just measured
	var top := PLANK_TOP + ceilf(FONT_SIZE * rel) - FONT_SIZE
	for i in rules.items.size():
		var plank := _plank(rules.items[i])
		plank.custom_minimum_size = Vector2(plank_w, plank_h)
		# A cell that shrank reaches its Row and plank only on the next frame, and until then the
		# engine clamps `size` to the height at the Text size before this one. Invalidate them, and
		# `settled` below catches the frame where the clamp still bit.
		(plank.get_node("Row") as Control).update_minimum_size()
		plank.update_minimum_size()
		plank.position = Vector2(plank_x, top + i * step)
		plank.size = Vector2(plank_w, plank_h)
		if plank.size.y > plank_h:
			settled = false
	var line_top := top + (rules.items.size() - 1) * step + plank_h + LINE_GAP
	var line_w := panel_w - 2.0 * LINE_SIDE
	var line := %Line as Label
	var lines := 1
	for text: String in LINES.values() + [FULLSCREEN_LINES[mac]]:
		lines = maxi(lines, line_count(text, line_w / rel, line.get_theme_font("font"), FONT_SIZE))
	var words_h := lines * FONT_SIZE + (lines - 1) * LINE_SPACING
	line.scale = Vector2.ONE * rel
	line.position = Vector2(LINE_SIDE, line_top)
	line.size = Vector2(line_w / rel, words_h)
	var line_h := ceilf(words_h * rel)
	var heading := %Heading as Label
	heading.scale = Vector2.ONE * rel
	heading.size = Vector2(panel_w / rel, FONT_SIZE)
	var panel_h := line_top + line_h + BOTTOM_MARGIN
	rest_panel = Rect2(floorf((Screen.WIDTH - panel_w) / 2.0), floorf((Screen.HEIGHT - panel_h) / 2.0), panel_w, panel_h)
	(%Content as Control).size = rest_panel.size
	_frame()
	if not settled and retry:
		# Once, on the next frame, when the shrink has reached the planks. Never again: a plank whose
		# words genuinely need the taller rect would otherwise re-queue itself every frame.
		_lay_out.call_deferred(false)

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
		var inset := HudFrame.RIM + ScrollWindow.MARK_ROW
		var view_h := band_h - 2.0 * inset
		var e := _item_extent(rules.highlighted)
		offset = ScrollWindow.follow(_content_height(), view_h, e.x, e.y, offset)
		# The plank itself is made wholly visible, in case its extent was taller than the view.
		var p := _plank(rules.highlighted)
		offset = ScrollWindow.follow(_content_height(), view_h,
				p.position.y - HEADING_TOP, p.position.y + p.size.y - HEADING_TOP, offset)
		%Panel.position = Vector2(rest_panel.position.x, band_top)
		%Panel.size = Vector2(w, band_h)
		(%Clip as Control).position = Vector2(0, inset)
		(%Clip as Control).size = Vector2(w, view_h)
		(%Content as Control).position = Vector2(0, -(HEADING_TOP + offset))
	(%Marks as Control).position = Vector2(0, HudFrame.RIM)
	(%Marks as Control).size = (%Panel as Control).size - Vector2(0, 2.0 * HudFrame.RIM)
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
	return ScrollWindow.stretch_ends(Vector2(top, top + p.size.y), _content_height(),
			item == rules.items[0], item == rules.items[rules.items.size() - 1])

func _frame() -> void:
	if not is_inside_tree() or strip == null:
		frame(0.0, Screen.HEIGHT)
		return
	var b := ScrollWindow.band(get_global_transform_with_canvas(), strip.screen_top())
	frame(b.x, b.y)

## The centre of the ▲ (up) or ▼ mark row, in %Marks' units: the panel's horizontal centre, in the
## mark row kept just inside the rim at the panel's top or bottom.
func mark_centre(up: bool) -> Vector2:
	return ScrollWindow.mark_centre(Rect2(Vector2.ZERO, (%Marks as Control).size), up)

func _draw_marks() -> void:
	var marks := %Marks as Control
	if shows_mark_above():
		ScrollWindow.draw_mark(marks, mark_centre(true), true)
	if shows_mark_below():
		ScrollWindow.draw_mark(marks, mark_centre(false), false)

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

func _lay_out(retry: bool = true) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return   # a deferred pass that arrived as the board was going away
	lay_out(get_global_transform_with_canvas().get_scale().x, retry)

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
		Plate.paint(_plank(item), rules.highlighted == item)   # before the arrows, which may dim
	for item: SettingsMenu.Plank in SettingsMenu.SETTING_OF:
		var s: DisplayPrefs.Setting = SettingsMenu.SETTING_OF[item]
		var v := Display.prefs.value(s)
		var row := _plank(item)
		(row.get_node("Row/Value") as GrownWords).text = VALUE_WORDS[s][v]
		(row.get_node("Row/Prev") as GrownWords).words().add_theme_color_override(
				"font_color", ARROW_DIM if v == 0 else Plate.words(rules.highlighted == item))
		(row.get_node("Row/Next") as GrownWords).words().add_theme_color_override(
				"font_color", ARROW_DIM if v == DisplayPrefs.count(s) - 1 else Plate.words(rules.highlighted == item))
	%Line.text = line_for(rules.highlighted)
	if rules.is_open:
		_frame()

## The line under the list for item on this platform.
func line_for(item: SettingsMenu.Plank) -> String:
	return FULLSCREEN_LINES[mac] if item == SettingsMenu.Plank.FULLSCREEN else LINES[item]

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
		SettingsMenu.Plank.FULLSCREEN:
			return %Fullscreen
		SettingsMenu.Plank.CONTROLS:
			return %Controls
	assert(false, "no node for plank %d" % item)
	return null

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed
