class_name TitleScreen
extends Control
## The title screen: draws the menu from a TitleMenu and turns input into its moves.

const INTRO_SCENE := "res://src/intro/intro.tscn"
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")

var menu := TitleMenu.new()
var quit_game: Callable = _quit_game          # tests replace these two
var start_new_game: Callable = _start_new_game

func _ready() -> void:
	%Version.text = "v" + str(ProjectSettings.get_setting("application/config/version"))
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if menu.locked:
		return
	if event.is_action_pressed("menu_up"):
		menu.move(-1)
	elif event.is_action_pressed("menu_down"):
		menu.move(1)
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _refresh() -> void:
	%NewGame.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.NEW_GAME))
	%Quit.add_theme_stylebox_override("panel", _style_for(TitleMenu.Choice.QUIT))

func _style_for(choice: TitleMenu.Choice) -> StyleBoxFlat:
	return PLANK_HIGHLIGHT_STYLE if menu.highlighted == choice else PLANK_STYLE

func _quit_game() -> void:
	get_tree().quit()

func _start_new_game() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)
