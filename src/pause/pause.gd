class_name Pause
extends CanvasLayer
## Esc, Start, a lost window or a lost pad pauses the tree and opens the board; draws a PauseMenu.
## Instance pause.tscn in a scene where play happens and set can_pause.

signal opened               # after the tree pauses and the board shows
signal resumed              # after RESUME (or Esc / Start / B) unpauses the tree
signal skip_story_chosen    # after SKIP_STORY unpauses the tree

const TITLE_SCENE := "res://src/title/title_screen.tscn"
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const BOARD_X := 88.0
const BOARD_W := 144.0
const BOARD_H_THREE := 96.0          # plus PLANK_STEP per extra plank
const PLANK_X := 12.0                # inside the board
const PLANK_TOP := 28.0              # first plank's top inside the board
const PLANK_STEP := 20.0
const PLANK_SIZE := Vector2(120, 16)
const BASE_HEIGHT := 180.0

@export var with_skip_story := false

static var debug_tools := OS.is_debug_build()   # tests set false to see the release board

var rules: PauseMenu
var can_pause: Callable = func() -> bool: return true      # the scene says when play is happening
var has_saved: Callable = func() -> bool: return false     # the scene says whether this run has saved
var open_settings: Callable = _open_settings                # tests replace it
var quit_to_title: Callable = _quit_to_title               # tests replace it
var open_debug: Callable = _open_debug                      # tests replace it
var strip: MenuStrip
var _quit_normal: BoxLayout   # the quit box as the scene has it, captured before anything places it
var _quit_box: BoxLayout      # the quit box as drawn now

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
	%SkipStory.visible = with_skip_story
	var h := BOARD_H_THREE + PLANK_STEP * (rules.items.size() - 3)
	%Panel.position = Vector2(BOARD_X, (BASE_HEIGHT - h) / 2.0)
	%Panel.size = Vector2(BOARD_W, h)
	for i in rules.items.size():
		var plank := _plank(rules.items[i])
		plank.position = Vector2(PLANK_X, PLANK_TOP + i * PLANK_STEP)
		plank.size = PLANK_SIZE
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
		match step:
			MenuPush.Step.BACK:
				rules.box_cancel()
			MenuPush.Step.LEFT:
				rules.box_select(PauseMenu.Choice.STAY)
			MenuPush.Step.RIGHT:
				rules.box_select(PauseMenu.Choice.QUIT)
			MenuPush.Step.SELECT:
				_apply(rules.box_press(rules.box_selected))
			MenuPush.Step.UP:
				if not _quit_box.stacked:
					return
				rules.box_select(PauseMenu.Choice.STAY)
			MenuPush.Step.DOWN:
				if not _quit_box.stacked:
					return
				rules.box_select(PauseMenu.Choice.QUIT)
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
		_plank(item).add_theme_stylebox_override("panel", _style(rules.highlighted == item))
	%Stay.add_theme_stylebox_override("panel", _style(rules.box_selected == PauseMenu.Choice.STAY))
	%Quit.add_theme_stylebox_override("panel", _style(rules.box_selected == PauseMenu.Choice.QUIT))
	if rules.box_open:
		%SecondLine.text = PauseMenu.quit_warning(has_saved.call())
		_fit_quit_box()

## Lays the quit box out for the current UI scale and words: side by side, or stacked when too wide.
func _fit_quit_box() -> void:
	var labels: Array[Label] = [%FirstLine, %SecondLine]
	var nodes: Array[Control] = [%FirstLine, %SecondLine]
	_quit_box = _quit_normal.at(UiScale.current(Display.prefs, get_tree().root), %Stay.size, %Quit.size, BoxLayout.label_heights(labels))
	_quit_box.place(%QuitBox.get_node("Panel"), nodes, %Stay, %Quit)

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
	return PLANK_HIGHLIGHT_STYLE if highlighted else PLANK_STYLE

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed

func _quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
