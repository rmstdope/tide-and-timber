class_name TitleScreen
extends Control
## The title screen: draws the menu from a TitleMenu and turns input into its moves.

const INTRO_SCENE := "res://src/intro/intro.tscn"
const GAME_SCENE := "res://src/waking/waking.tscn"
const MENU_TOP := 118.0                 # the menu's place with no save
const MENU_TOP_WITH_SAVE := 104.0       # three planks still clear the bottom edge
const FADE_SECONDS := 1.0
const WAVE_AMPLITUDE_PX := 4.0
const WAVE_PERIOD_SECONDS := 3.0
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")

var menu := TitleMenu.new()
var _time := 0.0
var _wave_home_x: Array[float] = []
var saved_game: SaveData = null         # the loaded save, handed to the game on Continue
var saved_day := 0                      # 0: no DAY line
var quit_game: Callable = _quit_game          # tests replace these three
var start_new_game: Callable = _start_new_game
var start_continue: Callable = _start_continue

func _ready() -> void:
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	for wave: Control in %Waves.get_children():
		_wave_home_x.append(wave.position.x)
	_connect_plank(%Continue, TitleMenu.Choice.CONTINUE)
	_connect_plank(%NewGame, TitleMenu.Choice.NEW_GAME)
	_connect_plank(%Quit, TitleMenu.Choice.QUIT)
	_connect_box_button(%KeepMyIsland, TitleMenu.BoxButton.KEEP_MY_ISLAND)
	_connect_box_button(%StartOver, TitleMenu.BoxButton.START_OVER)
	_connect_box_button(%Ok, TitleMenu.BoxButton.OK)
	read_save(SaveStore.SLOT_DIR)

## Reads the slot once and sets the menu up for it. Writes nothing, ever.
func read_save(dir: String) -> void:
	var exists := SaveStore.exists(dir)
	saved_game = SaveStore.load_slot(dir) if exists else null
	var opens := saved_game != null and Beach.can_restore(saved_game)
	if not opens:
		saved_game = null
	if saved_game:
		saved_day = saved_game.day()
	else:
		saved_day = SaveData.day_in(SaveStore.read(dir)) if exists else 0
	menu = TitleMenu.new(exists, opens)
	%Menu.position.y = MENU_TOP_WITH_SAVE if exists else MENU_TOP
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
	plank.mouse_entered.connect(_on_plank_hovered.bind(choice))
	plank.gui_input.connect(_on_plank_input.bind(choice))

func _on_plank_hovered(choice: TitleMenu.Choice) -> void:
	menu.hover(choice)
	_refresh()

func _on_plank_input(event: InputEvent, choice: TitleMenu.Choice) -> void:
	if _is_left_press(event):
		_act(menu.pick(choice))

func _connect_box_button(button: Control, which: TitleMenu.BoxButton) -> void:
	button.mouse_entered.connect(func() -> void:
		menu.select_box(which)
		_refresh())
	button.gui_input.connect(func(event: InputEvent) -> void:
		if _is_left_press(event):
			_act(menu.press_box(which)))

static func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed

## _input, not _unhandled_key_input, so the controller's A and B reach it (and not _unhandled_input,
## which the gdUnit scene runner also calls directly on the root, handling each test key twice).
func _input(event: InputEvent) -> void:
	if menu.locked:
		return
	if menu.box != TitleMenu.Box.NONE:
		if event.is_action_pressed("menu_left"):
			menu.select_box(TitleMenu.BoxButton.KEEP_MY_ISLAND)
		elif event.is_action_pressed("menu_right"):
			menu.select_box(TitleMenu.BoxButton.START_OVER)
		elif event.is_action_pressed("menu_accept"):
			_act(menu.press_box(menu.box_selected))
		elif event.is_action_pressed("menu_cancel"):
			_act(menu.cancel_box())
		else:
			return
	elif event.is_action_pressed("menu_up"):
		menu.move(-1)
	elif event.is_action_pressed("menu_down"):
		menu.move(1)
	elif event.is_action_pressed("menu_accept"):
		_act(menu.pick(menu.highlighted))
	else:
		return
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

func _fade_then(done: Callable) -> void:
	var fade := create_tween()
	fade.tween_property(%Fade, "modulate:a", 1.0, FADE_SECONDS).from(0.0)
	fade.tween_callback(done)

func _refresh() -> void:
	%Continue.visible = TitleMenu.Choice.CONTINUE in menu.choices
	%Continue.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.CONTINUE))
	%NewGame.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.NEW_GAME))
	%Quit.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.QUIT))
	%Dim.visible = menu.box != TitleMenu.Box.NONE
	%StartOverBox.visible = menu.box == TitleMenu.Box.START_OVER
	%CannotOpenBox.visible = menu.box == TitleMenu.Box.CANNOT_OPEN
	%KeepMyIsland.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.KEEP_MY_ISLAND))
	%StartOver.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.START_OVER))
	%Ok.add_theme_stylebox_override("panel", _box_style_for(TitleMenu.BoxButton.OK))

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
