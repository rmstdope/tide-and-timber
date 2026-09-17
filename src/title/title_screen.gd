class_name TitleScreen
extends Control
## The title screen: draws the menu from a TitleMenu and turns input into its moves.

const INTRO_SCENE := "res://src/intro/intro.tscn"
const GAME_SCENE := "res://src/waking/waking.tscn"
const MENU_TOP := 97.0                  # the menu's place: three planks with no save
const MENU_TOP_WITH_SAVE := 83.0        # four planks still clear the bottom edge
const MENU_TOP_DIMMED := 75.0           # Continue, reason line, New Game, Settings, Quit clear the bottom edge
const REASON_NEWER := "Save is from a newer version"
const REASON_BROKEN := "This save couldn't be opened"
const FADE_SECONDS := 1.0
const WAVE_AMPLITUDE_PX := 4.0
const WAVE_PERIOD_SECONDS := 3.0
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const PLANK_DIMMED_STYLE := preload("res://src/title/plank_dimmed.tres")
const LABEL_COLOR := Color(1.0, 0.956863, 0.839216, 1)             # the plank label colour in the scene
const MENU_STRIP_GAP := 2.0   # art px kept between the grown title menu and the top of the Select / Back strip
const LABEL_DIMMED_COLOR := Color(0.737255, 0.658824, 0.560784, 1)  # #bca88f

var menu := TitleMenu.new()
var _time := 0.0
var _wave_home_x: Array[float] = []
var saved_game: SaveData = null         # the loaded save, handed to the game on Continue
var saved_day := 0                      # 0: no DAY line
var quit_game: Callable = _quit_game          # tests replace these three
var start_new_game: Callable = _start_new_game
var start_continue: Callable = _start_continue
var migration_steps: Dictionary[int, Callable] = SaveMigrations.chain()   # tests replace it
var strip: MenuStrip
var _menu_top := MENU_TOP                # the menu's top at Normal, owned by read_save

## The title menu's top on screen when drawn at scale s. normal_top is its top at Normal, height its unscaled height.
## s <= 1: normal_top. Otherwise the menu grows about its own centre, then moves up until its bottom is at least
## MENU_STRIP_GAP above the strip's top (MenuStrip.BOTTOM - KeyHint.HEIGHT * s), but never above y 0.
static func menu_top_at(normal_top: float, height: float, s: float) -> float:
	if s <= 1.0:
		return normal_top
	var h := height * s
	var centred := roundf(normal_top + height / 2.0 - h / 2.0)
	var clear := floorf(MenuStrip.BOTTOM - KeyHint.HEIGHT * s - MENU_STRIP_GAP - h)
	return maxf(0.0, minf(centred, clear))

func _ready() -> void:
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	for wave: Control in %Waves.get_children():
		_wave_home_x.append(wave.position.x)
	_connect_plank(%Continue, TitleMenu.Choice.CONTINUE)
	_connect_plank(%NewGame, TitleMenu.Choice.NEW_GAME)
	_connect_plank(%Settings, TitleMenu.Choice.SETTINGS)
	%SettingsBoard.closed.connect(_on_settings_closed)
	_connect_plank(%Quit, TitleMenu.Choice.QUIT)
	_connect_box_button(%KeepMyIsland, TitleMenu.BoxButton.KEEP_MY_ISLAND)
	_connect_box_button(%StartOver, TitleMenu.BoxButton.START_OVER)
	_connect_box_button(%Cancel, TitleMenu.BoxButton.CANCEL)
	_connect_box_button(%ReplaceStartOver, TitleMenu.BoxButton.START_OVER)
	strip = MenuStrip.new()
	add_child(strip)
	move_child(strip, %Fade.get_index())   # above the dim and both boxes, under the fade
	read_save(SaveStore.SLOT_DIR)
	Display.changed.connect(_apply_ui_size)
	get_tree().root.size_changed.connect(_apply_ui_size)
	_apply_ui_size()
	InputDevice.set_menu_open(self, true)

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

## Reads the slot once and sets the menu up for it. Writes nothing, ever.
func read_save(dir: String) -> void:
	var reading := SlotReading.open(dir, migration_steps)
	var exists := reading.state != SlotReading.State.NONE
	var opens := reading.state == SlotReading.State.READY
	saved_game = reading.data
	saved_day = saved_game.day() if saved_game else 0
	menu = TitleMenu.new(exists, opens)
	_menu_top = MENU_TOP_DIMMED if menu.continue_dimmed else (MENU_TOP_WITH_SAVE if exists else MENU_TOP)
	%Reason.text = REASON_NEWER if reading.state == SlotReading.State.NEWER else REASON_BROKEN
	%Reason.visible = menu.continue_dimmed
	%DayLine.text = "DAY %d" % saved_day
	%DayLine.visible = saved_day > 0
	_refresh()

func make_continued_game() -> Waking:
	var game := (load(GAME_SCENE) as PackedScene).instantiate() as Waking
	game.resume_data = saved_game
	return game

func _process(delta: float) -> void:
	_time += delta
	var waves := %Waves.get_children()
	for i in waves.size():
		var drift := roundf(sin(_time * TAU / WAVE_PERIOD_SECONDS + i) * WAVE_AMPLITUDE_PX)
		(waves[i] as Control).position.x = _wave_home_x[i] + drift

func _connect_plank(plank: Control, choice: TitleMenu.Choice) -> void:
	plank.gui_input.connect(_on_plank_input.bind(choice))

func _on_plank_hovered(choice: TitleMenu.Choice) -> void:
	menu.hover(choice)
	_refresh()

func _on_plank_input(event: InputEvent, choice: TitleMenu.Choice) -> void:
	if PointerRule.is_move(event):
		_on_plank_hovered(choice)
	elif _is_left_press(event):
		_act(menu.pick(choice))

func _connect_box_button(button: Control, which: TitleMenu.BoxButton) -> void:
	button.gui_input.connect(func(event: InputEvent) -> void:
		if PointerRule.is_move(event):
			menu.select_box(which)
			_refresh()
		elif _is_left_press(event):
			_act(menu.press_box(which)))

static func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed

## _input, not _unhandled_key_input, so the controller's A and B reach it (and not _unhandled_input,
## which the gdUnit scene runner also calls directly on the root, handling each test key twice).
func _input(event: InputEvent) -> void:
	if menu.locked:
		return
	if menu.settings_open:
		return   # the Settings board, a child, reads it
	var step := InputDevice.menu_step(event)
	if menu.box != TitleMenu.Box.NONE:
		match step:
			MenuPush.Step.LEFT:
				menu.select_box(TitleMenu.BoxButton.KEEP_MY_ISLAND if menu.box == TitleMenu.Box.START_OVER
						else TitleMenu.BoxButton.CANCEL)
			MenuPush.Step.RIGHT:
				menu.select_box(TitleMenu.BoxButton.START_OVER)
			MenuPush.Step.SELECT:
				_act(menu.press_box(menu.box_selected))
			MenuPush.Step.BACK:
				_act(menu.cancel_box())
			_:
				return
	else:
		match step:
			MenuPush.Step.UP:
				menu.move(-1)
			MenuPush.Step.DOWN:
				menu.move(1)
			MenuPush.Step.SELECT:
				_act(menu.pick(menu.highlighted))
			_:
				return   # BACK does nothing on the title menu
	_refresh()
	get_viewport().set_input_as_handled()

func _act(action: TitleMenu.Action) -> void:
	_refresh()
	match action:
		TitleMenu.Action.QUIT:
			quit_game.call()
		TitleMenu.Action.NEW_GAME:
			_fade_then(func() -> void: start_new_game.call())
		TitleMenu.Action.CONTINUE:
			_fade_then(func() -> void: start_continue.call())
		TitleMenu.Action.OPEN_SETTINGS:
			%SettingsBoard.open(false)

func _on_settings_closed() -> void:
	menu.close_settings()
	_refresh()

func _fade_then(done: Callable) -> void:
	var fade := create_tween()
	fade.tween_property(%Fade, "modulate:a", 1.0, FADE_SECONDS).from(0.0)
	fade.tween_callback(done)

func _refresh() -> void:
	%Continue.visible = TitleMenu.Choice.CONTINUE in menu.choices
	%Continue.add_theme_stylebox_override("panel",
			PLANK_DIMMED_STYLE if menu.continue_dimmed else _style_for(TitleMenu.Choice.CONTINUE))
	$Menu/Continue/Lines/Label.add_theme_color_override("font_color",
			LABEL_DIMMED_COLOR if menu.continue_dimmed else LABEL_COLOR)
	%NewGame.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.NEW_GAME))
	%Settings.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.SETTINGS))
	%Quit.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.QUIT))
	%Dim.visible = menu.box != TitleMenu.Box.NONE
	%StartOverBox.visible = menu.box == TitleMenu.Box.START_OVER
	%ReplaceBox.visible = menu.box == TitleMenu.Box.REPLACE
	%KeepMyIsland.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.KEEP_MY_ISLAND))
	%StartOver.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.START_OVER))
	%Cancel.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.CANCEL))
	%ReplaceStartOver.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.START_OVER))
	strip.show_hint(DeviceHints.Hint.SELECT_BACK if menu.box != TitleMenu.Box.NONE else DeviceHints.Hint.SELECT)
	strip.visible = not menu.settings_open   # the board shows its own Select / Back strip
	_place_menu()

## The boxes and the Settings board grow about the screen centre; then the menu is placed.
func _apply_ui_size() -> void:
	var s := UiScale.current(Display.prefs, get_tree().root)
	for c: Control in [%StartOverBox, %ReplaceBox, %SettingsBoard]:
		c.pivot_offset = OverlayScale.ANCHOR_CENTRE - c.position
		c.scale = Vector2(s, s)
	_place_menu()

## The menu grows about its own centre and keeps clear of the strip. Runs after visibility is set.
func _place_menu() -> void:
	var s := UiScale.current(Display.prefs, get_tree().root)
	var m := %Menu as Control
	m.pivot_offset = Vector2.ZERO
	m.scale = Vector2(s, s)
	var height := m.get_combined_minimum_size().y
	m.size.y = height   # a Container never shrinks by itself; keep its rect to the planks shown
	m.position = Vector2(roundf(160.0 - 160.0 * s), menu_top_at(_menu_top, height, s))

func _box_style_for(button: TitleMenu.BoxButton) -> StyleBoxFlat:
	return PLANK_HIGHLIGHT_STYLE if menu.box_selected == button else PLANK_STYLE

func _style_for(choice: TitleMenu.Choice) -> StyleBoxFlat:
	return PLANK_HIGHLIGHT_STYLE if menu.highlighted == choice else PLANK_STYLE

func _quit_game() -> void:
	get_tree().quit()

func _start_new_game() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)

func _start_continue() -> void:
	get_tree().change_scene_to_node(make_continued_game())
