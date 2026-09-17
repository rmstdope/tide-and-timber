class_name Autosave
extends Node
## Saves the game at every dawn: the dawn line when it worked, the box when it did not.
## Instance autosave.tscn in the game scene and call watch().

const SHAKE_PX: Array[float] = [3.0, -3.0, 2.0, -2.0, 0.0]   # first-line x offsets, 0.05 s each
const SHAKE_STEP_SECONDS := 0.05
const FIRST_LINE_X := 24.0
const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")

var rules: DawnSave
var slot_dir := SaveStore.SLOT_DIR
var save_game: Callable = _save_game      # () -> Error; tests replace it
var _beach: Beach
var _day_night: DayNight
var _paused_by_box := false
var _shakes_seen := 0
var _shake: Tween

func _ready() -> void:
	rules = DawnSave.new(func() -> Error: return save_game.call())
	_connect_button(%TryAgain, DawnSave.Choice.TRY_AGAIN)
	_connect_button(%KeepPlaying, DawnSave.Choice.KEEP_PLAYING)
	_refresh()

func watch(beach: Beach, day_night: DayNight) -> void:
	_beach = beach
	_day_night = day_night
	day_night.dawn.connect(on_dawn)

func on_dawn() -> void:
	rules.dawn()
	_after_rules()

## While he lies in the dark after a collapse: save at dawn as usual, but keep the line back.
func hold_line() -> void:
	rules.hold_line()

func release_line() -> void:
	rules.release_line()
	_refresh()

func _process(delta: float) -> void:
	tick(delta)

func tick(real_seconds: float) -> void:
	if not get_tree().paused or _paused_by_box:
		rules.advance(real_seconds)
	_refresh()

func _input(event: InputEvent) -> void:
	if not rules.box_open:
		return
	if event.is_action_pressed("menu_left"):
		rules.select(DawnSave.Choice.TRY_AGAIN)
	elif event.is_action_pressed("menu_right"):
		rules.select(DawnSave.Choice.KEEP_PLAYING)
	elif event.is_action_pressed("menu_accept"):
		rules.press(rules.selected)
	elif event.is_action_pressed("menu_cancel"):
		rules.cancel()
	else:
		return
	_after_rules()
	get_viewport().set_input_as_handled()

func _connect_button(button: Control, which: DawnSave.Choice) -> void:
	button.mouse_entered.connect(func() -> void:
		rules.select(which)
		_refresh())
	button.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			rules.press(which)
			_after_rules())

func _save_game() -> Error:
	var data := _beach.capture()
	data.clock_minutes = _day_night.clock.last_dawn_minutes()
	return SaveStore.save_slot(data, slot_dir)

func _after_rules() -> void:
	if rules.box_open and not _paused_by_box and not get_tree().paused:
		get_tree().paused = true
		_paused_by_box = true
	if not rules.box_open and _paused_by_box:
		get_tree().paused = false
		_paused_by_box = false
	if rules.failed_retries > _shakes_seen:
		_shakes_seen = rules.failed_retries
		if _shake:
			_shake.kill()
		_shake = create_tween()
		for offset in SHAKE_PX:
			_shake.tween_property(%FirstLine, "position:x", FIRST_LINE_X + offset, SHAKE_STEP_SECONDS)
	_refresh()

func _refresh() -> void:
	%Dawn.visible = rules.line.is_showing()
	%Dawn.modulate.a = rules.line.alpha()
	%Box.visible = rules.box_open
	%TryAgain.add_theme_stylebox_override("panel", _style_for(DawnSave.Choice.TRY_AGAIN))
	%KeepPlaying.add_theme_stylebox_override("panel", _style_for(DawnSave.Choice.KEEP_PLAYING))

func _style_for(button: DawnSave.Choice) -> StyleBox:
	return PLANK_HIGHLIGHT_STYLE if rules.selected == button else PLANK_STYLE
