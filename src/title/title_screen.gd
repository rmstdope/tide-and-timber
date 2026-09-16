class_name TitleScreen
extends Control
## The title screen: draws the menu from a TitleMenu and turns input into its moves.

const INTRO_SCENE := "res://src/intro/intro.tscn"
const FADE_SECONDS := 1.0
const WAVE_AMPLITUDE_PX := 4.0
const WAVE_PERIOD_SECONDS := 3.0
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")

var menu := TitleMenu.new()
var _time := 0.0
var _wave_home_x: Array[float] = []
var quit_game: Callable = _quit_game          # tests replace these two
var start_new_game: Callable = _start_new_game

func _ready() -> void:
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	for wave: Control in %Waves.get_children():
		_wave_home_x.append(wave.position.x)
	_connect_plank(%NewGame, TitleMenu.Choice.NEW_GAME)
	_connect_plank(%Quit, TitleMenu.Choice.QUIT)
	_refresh()

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
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		_choose(choice)

func _unhandled_key_input(event: InputEvent) -> void:
	if menu.locked:
		return
	if event.is_action_pressed("menu_up"):
		menu.move(-1)
	elif event.is_action_pressed("menu_down"):
		menu.move(1)
	elif event.is_action_pressed("menu_accept"):
		_choose(menu.highlighted)
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _choose(choice: TitleMenu.Choice) -> void:
	if not menu.pick(choice):
		return
	_refresh()
	if choice == TitleMenu.Choice.QUIT:
		quit_game.call()
	else:
		var fade := create_tween()
		fade.tween_property(%Fade, "modulate:a", 1.0, FADE_SECONDS).from(0.0)
		fade.tween_callback(func() -> void: start_new_game.call())

func _refresh() -> void:
	%NewGame.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.NEW_GAME))
	%Quit.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.QUIT))

func _style_for(choice: TitleMenu.Choice) -> StyleBoxFlat:
	return PLANK_HIGHLIGHT_STYLE if menu.highlighted == choice else PLANK_STYLE

func _quit_game() -> void:
	get_tree().quit()

func _start_new_game() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)
