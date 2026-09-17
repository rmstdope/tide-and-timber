class_name SettingsBoard
extends Control
## The Settings board over a dim: draws a SettingsMenu and turns input into its moves.
## Instanced by the title screen and by pause.tscn.

signal closed              # Back: the opener highlights its Settings plank again
signal resume_requested    # the Pause input, opened from the pause board: the opener resumes play

const PLANK_STYLE := preload("res://src/title/plank.tres")
const PLANK_HIGHLIGHT_STYLE := preload("res://src/title/plank_highlight.tres")
const BOARD_X := 88.0
const BOARD_W := 144.0
const BOARD_H_ONE := 56.0      # heading, one plank, bottom margin; plus PLANK_STEP per extra plank
const PLANK_X := 12.0
const PLANK_TOP := 28.0
const PLANK_STEP := 20.0
const PLANK_SIZE := Vector2(120, 16)
const BASE_HEIGHT := 180.0

var rules := SettingsMenu.new()
var strip: MenuStrip
var open_controls: Callable = func() -> void: pass     # the Controls page, when it exists (tr-eg9.5.3)

func _ready() -> void:
	var h := BOARD_H_ONE + (rules.items.size() - 1) * PLANK_STEP
	%Panel.position = Vector2(BOARD_X, (BASE_HEIGHT - h) / 2.0)
	%Panel.size = Vector2(BOARD_W, h)
	for i in rules.items.size():
		var item := rules.items[i]
		var plank := _plank(item)
		plank.position = Vector2(PLANK_X, PLANK_TOP + i * PLANK_STEP)
		plank.size = PLANK_SIZE
		plank.gui_input.connect(func(event: InputEvent) -> void:
			if PointerRule.is_move(event):
				rules.hover(item)
				_refresh()
			elif _is_left_press(event):
				_apply(rules.pick(item))
				_refresh())
	strip = MenuStrip.new()
	add_child(strip)   # last child: above the panel
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	_refresh()

## Opens the board. from_pause: opened from the Paused board.
func open(from_pause: bool) -> void:
	if rules.open(from_pause):
		_refresh()

# The menu step is checked before the pause action: Esc is both, and means Back here.
func _input(event: InputEvent) -> void:
	if not rules.is_open or rules.controls_open:
		return
	var step := InputDevice.menu_step(event)
	if step == MenuPush.Step.UP:
		rules.move(-1)
	elif step == MenuPush.Step.DOWN:
		rules.move(1)
	elif step == MenuPush.Step.SELECT:
		_apply(rules.pick(rules.highlighted))
	elif step == MenuPush.Step.BACK:
		_apply(rules.back())
	elif event.is_action_pressed("pause", false):
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

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _plank(item: SettingsMenu.Plank) -> Control:
	match item:
		_:
			return %Controls

func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed
