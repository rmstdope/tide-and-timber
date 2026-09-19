class_name Pause
extends CanvasLayer
## Esc, Start, a lost window or a lost pad pauses the tree and opens the board; draws a PauseMenu.
## Instance pause.tscn in a scene where play happens and set can_pause.
## When the board is taller than the screen above its strip, it is framed to fit and its planks scroll
## to the highlight, with ▲ / ▼ where planks are hidden.

signal opened               # after the tree pauses and the board shows
signal resumed              # after RESUME (or Esc / Start / B) unpauses the tree
signal skip_story_chosen    # after SKIP_STORY unpauses the tree

const TITLE_SCENE := "res://src/title/title_screen.tscn"
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
# The board at Text size Normal. lay_out() measures the words instead of reading these, so they are
# what tests/debug/pause_debug_test.gd checks Normal still draws, not values the layout uses.
const BOARD_H_THREE := 96.0          # plus PLANK_STEP per extra plank
const PLANK_X := 12.0                # inside the board
const PLANK_TOP := 28.0              # first plank's top inside the board
const PLANK_STEP := 20.0             # the Normal step; lay_out() uses plank_h + PLANK_GAP
const PLANK_SIZE := Vector2(120, 16)
const HEADING_TOP := 8.0        # panel top to the heading's top; the scrolled content starts here
const BOTTOM_MARGIN := 12.0     # last plank's bottom to the panel's bottom (96 - 84)
const WORD_HEIGHT := 8.0        # one line of words at Normal: the heading's height
const PLANK_GAP := 4.0          # PLANK_STEP - PLANK_SIZE.y, kept at every Text size
const DEV_TAG_RIGHT := 22.0   # the DEV tag's left edge, from the board's right edge: the rim (6) plus the tag's 16
const DEV_TAG_TOP := 8.0   # the DEV tag's top inside the board: level with the heading (HEADING_TOP), inside the rim

@export var with_skip_story := false

static var debug_tools := OS.is_debug_build()   # tests set false to see the release board

var rules: PauseMenu
var can_pause: Callable = func() -> bool: return true      # the scene says when play is happening
var has_saved: Callable = func() -> bool: return false     # the scene says whether this run has saved
var open_settings: Callable = _open_settings                # tests replace it
var quit_to_title: Callable = _quit_to_title               # tests replace it
var open_debug: Callable = _open_debug                      # tests replace it
var strip: MenuStrip
var scroll_offset := 0        # whole units the content is scrolled up; 0 while it fits. Owned by frame().
var scrolls := false          # the content does not fit the band; derived by frame()
var rest_panel := Rect2()     # the centred panel set in _ready, before framing
var _quit_normal: BoxLayout   # the quit box as the scene has it, captured before anything places it
var _quit_box: BoxLayout      # the quit box as drawn now
var _quit_frame: BoxLayout    # the quit box framed to the room above the strip; null until first framed while open
var _quit_offset := 0         # whole units the quit box's content is scrolled; owned by _push_quit_box and _frame_quit_box
var _quit_was_open := false   # to reset the offset each time the box opens

func _ready() -> void:
	var box_lines: Array[Control] = [%FirstLine, %SecondLine]
	_quit_normal = BoxLayout.of(%QuitBox.get_node("Panel"), box_lines, %Stay, %Quit)
	Display.changed.connect(_fit_quit_box)
	get_tree().root.size_changed.connect(_fit_quit_box)
	_fit_quit_box()
	rules = PauseMenu.new(with_skip_story, debug_tools)
	if debug_tools:
		%DebugPanel.closed.connect(_on_debug_closed)
		%DebugPanel.resume_requested.connect(_on_debug_resume)
	else:
		%Debug.queue_free()
		%DevTag.queue_free()
		%DebugPanel.queue_free()
	%SettingsBoard.closed.connect(_on_settings_closed)
	%SettingsBoard.resume_requested.connect(_on_settings_resume)
	strip = MenuStrip.new()
	%Board.add_child(strip)   # last child: above the quit box's dim, shown exactly when the board is
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	# After add_child(strip): the strip's own deferred layout is queued first, so screen_top() is final.
	%Marks.draw.connect(_draw_marks)
	Display.changed.connect(_frame_later)
	get_tree().root.size_changed.connect(_frame_later)
	Display.changed.connect(_frame_quit_box_later)
	get_tree().root.size_changed.connect(_frame_quit_box_later)
	_quit_panel().get_node("Marks").draw.connect(_draw_quit_marks)
	%SkipStory.visible = with_skip_story
	for i in rules.items.size():
		var plank := _plank(rules.items[i])
		plank.gui_input.connect(func(event: InputEvent) -> void:
			if PointerRule.is_move(event):
				rules.hover(rules.items[i])
				_refresh()
			elif _is_left_press(event):
				_apply(rules.pick(rules.items[i]))
				_refresh())
	for choice: PauseMenu.Choice in [PauseMenu.Choice.STAY, PauseMenu.Choice.QUIT]:
		var button := _button(choice)
		button.gui_input.connect(func(event: InputEvent) -> void:
			if PointerRule.is_move(event):
				rules.box_select(choice)
				_refresh()
			elif _is_left_press(event):
				_apply(rules.box_press(choice))
				_refresh())
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()

## The Debug panel's rules, where a scene adds its rows; null in a release build.
func debug_menu() -> DebugMenu:
	return %DebugPanel.rules if debug_tools else null

## A Debug story jump: board and panel gone, the tree stays paused, the screen fades to black
## over TitleScreen.FADE_SECONDS, then `then` is called. Input is swallowed until then.
func leave(then: Callable) -> void:
	rules.leave()
	_refresh()
	%Fade.visible = true
	var t := create_tween()
	t.tween_property(%Fade, "modulate:a", 1.0, TitleScreen.FADE_SECONDS).from(0.0)
	t.tween_callback(func() -> void: then.call())

## Opens the board if play is happening: not open, not quitting, the tree not already paused, can_pause true.
func try_open() -> bool:
	if rules.is_open or rules.quitting or rules.leaving or get_tree().paused or not can_pause.call():
		return false
	rules.open()
	scroll_offset = 0
	get_tree().paused = true
	_refresh()
	opened.emit()
	return true

# After _input and _shortcut_input, so the build list, the collapse and the save-failed box get Esc first.
func _unhandled_input(event: InputEvent) -> void:
	if InputDevice.action_pressed(event, "pause") and try_open():
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if rules.quitting or rules.leaving:
		get_viewport().set_input_as_handled()
		return
	if not rules.is_open:
		return
	if rules.settings_open or rules.debug_open:
		return   # the Settings board or the Debug panel, a child, reads it
	var step := InputDevice.menu_step(event)
	if rules.box_open:
		# The wheel is not a menu step: read it before the match, or the _ arm swallows it.
		var wheel := BoxLayout.wheel_push(event)
		if wheel != -1:
			_push_quit_box(wheel as BoxLayout.Push)
			_refresh()
			get_viewport().set_input_as_handled()
			return
		match step:
			MenuPush.Step.BACK:
				rules.box_cancel()
			MenuPush.Step.LEFT:
				_push_quit_box(BoxLayout.Push.LEFT)
			MenuPush.Step.RIGHT:
				_push_quit_box(BoxLayout.Push.RIGHT)
			MenuPush.Step.SELECT:
				_apply(rules.box_press(rules.box_selected))
			MenuPush.Step.UP:
				_push_quit_box(BoxLayout.Push.UP)
			MenuPush.Step.DOWN:
				_push_quit_box(BoxLayout.Push.DOWN)
			_:
				return   # Start does nothing in the box
	elif step == MenuPush.Step.UP:
		rules.move(-1)
	elif step == MenuPush.Step.DOWN:
		rules.move(1)
	elif step == MenuPush.Step.SELECT:
		_apply(rules.pick(rules.highlighted))
	elif step == MenuPush.Step.BACK or InputDevice.action_pressed(event, "pause"):
		_apply(rules.back())
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if rules:
			try_open()

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected:
		try_open()

func _apply(outcome: PauseMenu.Outcome) -> void:
	match outcome:
		PauseMenu.Outcome.RESUMED:
			get_tree().paused = false
			_refresh()
			resumed.emit()
		PauseMenu.Outcome.SKIP_STORY:
			get_tree().paused = false
			_refresh()
			skip_story_chosen.emit()
		PauseMenu.Outcome.OPEN_SETTINGS:
			open_settings.call()
		PauseMenu.Outcome.OPEN_DEBUG:
			open_debug.call()
		PauseMenu.Outcome.QUITTING:
			%Fade.visible = true
			var t := create_tween()
			t.tween_property(%Fade, "modulate:a", 1.0, TitleScreen.FADE_SECONDS).from(0.0)
			t.tween_callback(func() -> void: quit_to_title.call())

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _refresh() -> void:
	InputDevice.set_menu_open(self, rules.is_open or rules.quitting or rules.leaving)
	%Board.visible = (rules.is_open and not rules.settings_open and not rules.debug_open) or rules.quitting
	%QuitBox.visible = rules.box_open
	for item: PauseMenu.Plank in rules.items:
		Plate.paint(_plank(item), rules.highlighted == item)
	Plate.paint(%Stay, rules.box_selected == PauseMenu.Choice.STAY)
	Plate.paint(%Quit, rules.box_selected == PauseMenu.Choice.QUIT)
	if rules.box_open:
		%SecondLine.text = PauseMenu.quit_warning(has_saved.call())
		_fit_quit_box()
		if not _quit_was_open:
			_quit_offset = 0
		_frame_quit_box()
	_quit_was_open = rules.box_open
	_frame()

## Frames the panel to the band [band_top, band_bottom] (board units) and scrolls the content so the
## highlighted plank is wholly visible. Reads rest_panel and the planks' positions; sets scroll_offset
## and scrolls.
func frame(band_top: float, band_bottom: float) -> void:
	var band_h := band_bottom - band_top
	var w := rest_panel.size.x
	if rest_panel.size.y <= band_h:
		scrolls = false
		scroll_offset = 0
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
		scroll_offset = ScrollWindow.follow(_content_height(), view_h, e.x, e.y, scroll_offset)
		# The plank itself is made wholly visible, in case its extent was taller than the view.
		var p := _plank(rules.highlighted)
		scroll_offset = ScrollWindow.follow(_content_height(), view_h,
				p.position.y - HEADING_TOP, p.position.y + p.size.y - HEADING_TOP, scroll_offset)
		%Panel.position = Vector2(rest_panel.position.x, band_top)
		%Panel.size = Vector2(w, band_h)
		(%Clip as Control).position = Vector2(0, inset)
		(%Clip as Control).size = Vector2(w, view_h)
		(%Content as Control).position = Vector2(0, -(HEADING_TOP + scroll_offset))
	(%Marks as Control).position = Vector2(0, HudFrame.RIM)
	(%Marks as Control).size = (%Panel as Control).size - Vector2(0, 2.0 * HudFrame.RIM)
	%Marks.queue_redraw()

## True while ▲ is drawn: scrolling, with planks hidden above.
func shows_mark_above() -> bool:
	return scrolls and ScrollWindow.hidden_above(scroll_offset)

## True while ▼ is drawn: scrolling, with planks hidden below.
func shows_mark_below() -> bool:
	return scrolls and ScrollWindow.hidden_below(scroll_offset, _content_height(), (%Clip as Control).size.y)

# The scrolled content: the heading's top to the last plank's bottom. The mark rows replace the margins.
func _content_height() -> float:
	return rest_panel.size.y - HEADING_TOP - BOTTOM_MARGIN

# The plank's extent within the scrolled content. The first reaches up to the heading, and the last down
# to the board's bottom, so moving to an end brings what frames the list into view.
func _item_extent(item: PauseMenu.Plank) -> Vector2:
	var p := _plank(item)
	var top := p.position.y - HEADING_TOP
	return ScrollWindow.stretch_ends(Vector2(top, top + p.size.y), _content_height(),
			item == rules.items[0], item == rules.items[rules.items.size() - 1])

## Sizes the heading and planks for Text size and sets rest_panel. Every plank takes the widest plank's
## width and the tallest plank's height. A plank's words wrap only when they are wider than the board
## may be on screen.
func lay_out(retry: bool = true) -> void:
	var ui := UiScale.current(Display.prefs, get_tree().root)
	var rel := TextScale.relative(Display.prefs, get_tree().root)
	var room := SettingsBoard.panel_width(ui) - 2.0 * PLANK_X - PLANK_STYLE.get_minimum_size().x
	var plank_w := PLANK_SIZE.x
	var plank_h := PLANK_SIZE.y
	for item: PauseMenu.Plank in rules.items:
		var plank := _plank(item)
		(plank.get_node("Label") as GrownWords).max_width = room
		var m := plank.get_combined_minimum_size()
		plank_w = maxf(plank_w, m.x)
		plank_h = maxf(plank_h, m.y)
	var top := PLANK_TOP + ceilf(WORD_HEIGHT * rel) - WORD_HEIGHT
	var step := plank_h + PLANK_GAP
	var settled := true          # false when a plank could not yet shrink to the height we just measured
	for i in rules.items.size():
		var plank := _plank(rules.items[i])
		plank.position = Vector2(PLANK_X, top + i * step)
		# A shrunken Label reaches its plank only on the next frame, and until then the engine clamps
		# `size` to the height at the Text size before this one. `settled` catches that frame.
		plank.update_minimum_size()
		plank.size = Vector2(plank_w, plank_h)
		if plank.size.y > plank_h:
			settled = false
	var board_w := plank_w + 2.0 * PLANK_X
	var heading := %Heading as Label
	heading.scale = Vector2.ONE * rel
	heading.size = Vector2(board_w / rel, WORD_HEIGHT)
	# The tag is freed in _ready in a release board, and debug_tools may have changed since; ask the node.
	var dev_tag := get_node_or_null("%DevTag") as Control
	if dev_tag != null:
		dev_tag.position = Vector2(board_w - DEV_TAG_RIGHT, DEV_TAG_TOP)
	var h := top + (rules.items.size() - 1) * step + plank_h + BOTTOM_MARGIN
	rest_panel = Rect2(floorf((Screen.WIDTH - board_w) / 2.0), floorf((Screen.HEIGHT - h) / 2.0), board_w, h)
	(%Content as Control).size = rest_panel.size
	if not settled and retry:
		# Once, on the next frame, when the shrink has reached the planks. Never again: a plank whose
		# words genuinely need the taller rect would otherwise re-queue itself every frame.
		_frame.call_deferred(false)

func _frame(retry: bool = true) -> void:
	if is_queued_for_deletion():
		return   # a deferred retry that arrived as the board was going away
	if not is_inside_tree() or strip == null:
		frame(0.0, Screen.HEIGHT)   # lay_out needs the tree; leave the rects as they are
		return
	lay_out(retry)
	var b := ScrollWindow.band((%Board as Control).get_global_transform_with_canvas(), strip.screen_top())
	frame(b.x, b.y)

func _frame_later() -> void:
	if is_inside_tree() and not is_queued_for_deletion():
		_frame.call_deferred()

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

## Lays the quit box out for the current UI scale and words: side by side, or stacked when too wide.
func _fit_quit_box() -> void:
	var rel := TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	var labels: Array[Label] = [%FirstLine, %SecondLine]
	var nodes: Array[Control] = [%FirstLine, %SecondLine]
	_quit_box = _quit_normal.at(UiScale.current(Display.prefs, get_tree().root),
			BoxLayout.button_size(%Stay, _quit_normal.left), BoxLayout.button_size(%Quit, _quit_normal.right),
			BoxLayout.label_heights(labels, rel), BoxLayout.label_widths(labels, rel))
	_quit_box.place(%QuitBox.get_node("Panel"), nodes, %Stay, %Quit, rel)

## One push or wheel notch on the open quit box: the highlight and the scroll, by BoxLayout's rule.
func _push_quit_box(push: BoxLayout.Push) -> void:
	if _quit_frame == null:
		return
	var side := BoxLayout.Side.LEFT if rules.box_selected == PauseMenu.Choice.STAY else BoxLayout.Side.RIGHT
	var after := _quit_frame.pushed(push, side)
	rules.box_select(PauseMenu.Choice.STAY if after.x == BoxLayout.Side.LEFT else PauseMenu.Choice.QUIT)
	_quit_offset = after.y

## Frames the laid-out quit box to the room between the screen top and the strip. Only while the box is open.
func _frame_quit_box() -> void:
	if rules == null or not rules.box_open or _quit_box == null or strip == null or not is_inside_tree():
		return
	var b := ScrollWindow.band((%QuitBox as Control).get_global_transform_with_canvas(), strip.screen_top())
	_quit_frame = _quit_box.framed(b.x, b.y, _quit_offset)
	_quit_offset = _quit_frame.offset
	_quit_frame.place_frame(_quit_panel(), _quit_panel().get_node("Clip"),
			_quit_panel().get_node("Clip/Content"), _quit_panel().get_node("Marks"))

func _frame_quit_box_later() -> void:
	_frame_quit_box.call_deferred()

func _quit_panel() -> Control:
	return %QuitBox.get_node("Panel")

func _draw_quit_marks() -> void:
	if _quit_frame == null or not rules.box_open:
		return
	var marks: Control = _quit_panel().get_node("Marks")
	if _quit_frame.shows_mark_above():
		ScrollWindow.draw_mark(marks, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, marks.size), true), true)
	if _quit_frame.shows_mark_below():
		ScrollWindow.draw_mark(marks, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, marks.size), false), false)

func _open_settings() -> void:
	%SettingsBoard.open(true)

func _on_settings_closed() -> void:
	rules.close_settings()
	_refresh()

func _on_settings_resume() -> void:
	_apply(rules.resume_from_settings())

func _open_debug() -> void:
	%DebugPanel.open(with_skip_story)

func _on_debug_closed() -> void:
	rules.close_debug()
	_refresh()

func _on_debug_resume() -> void:
	_apply(rules.resume_from_debug())

func _plank(item: PauseMenu.Plank) -> Control:
	match item:
		PauseMenu.Plank.RESUME:
			return %Resume
		PauseMenu.Plank.SKIP_STORY:
			return %SkipStory
		PauseMenu.Plank.SETTINGS:
			return %Settings
		PauseMenu.Plank.DEBUG:
			return %Debug
	return %QuitToTitle

func _button(choice: PauseMenu.Choice) -> Control:
	return %Stay if choice == PauseMenu.Choice.STAY else %Quit

func _style(highlighted: bool) -> StyleBox:
	return Plate.style(highlighted)

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed

func _quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
