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
var strip: MenuStrip
var _box_normal: BoxLayout   # the box as the scene has it, captured before anything places it
var _box: BoxLayout          # the box as drawn now
var _box_frame: BoxLayout    # the box framed to the room above the strip; null until first framed while open
var _box_offset := 0         # whole units the box's content is scrolled; owned by _push_box and _frame_box
var _box_was_open := false   # to reset the offset each time the box opens

func _ready() -> void:
	var box_lines: Array[Control] = [%FirstLine, %SecondLine]
	_box_normal = BoxLayout.of(%Box.get_node("Panel"), box_lines, %TryAgain, %KeepPlaying)
	Display.changed.connect(_fit_box)
	get_tree().root.size_changed.connect(_fit_box)
	_fit_box()
	rules = DawnSave.new(func() -> Error: return save_game.call())
	_connect_button(%TryAgain, DawnSave.Choice.TRY_AGAIN)
	_connect_button(%KeepPlaying, DawnSave.Choice.KEEP_PLAYING)
	strip = MenuStrip.new()
	%Box.add_child(strip)   # shown exactly when the box is
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	# After add_child(strip): the strip's own deferred layout is queued first, so screen_top() is final.
	Display.changed.connect(_frame_box_later)
	get_tree().root.size_changed.connect(_frame_box_later)
	_box_panel().get_node("Marks").draw.connect(_draw_box_marks)
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
	# The wheel is not a menu step: read it first, or the _ arm swallows it.
	var wheel := BoxLayout.wheel_push(event)
	if wheel != -1:
		_push_box(wheel as BoxLayout.Push)
		_after_rules()
		get_viewport().set_input_as_handled()
		return
	match InputDevice.menu_step(event):
		MenuPush.Step.LEFT:
			_push_box(BoxLayout.Push.LEFT)
		MenuPush.Step.RIGHT:
			_push_box(BoxLayout.Push.RIGHT)
		MenuPush.Step.UP:
			_push_box(BoxLayout.Push.UP)
		MenuPush.Step.DOWN:
			_push_box(BoxLayout.Push.DOWN)
		MenuPush.Step.SELECT:
			rules.press(rules.selected)
		MenuPush.Step.BACK:
			rules.cancel()
		_:
			return
	_after_rules()
	get_viewport().set_input_as_handled()

## Lays the box out for the current UI scale: side by side, or stacked when too wide.
func _fit_box() -> void:
	var rel := TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	var labels: Array[Label] = [%FirstLine, %SecondLine]
	var nodes: Array[Control] = [%FirstLine, %SecondLine]
	_box = _box_normal.at(UiScale.current(Display.prefs, get_tree().root),
			BoxLayout.button_size(%TryAgain, _box_normal.left), BoxLayout.button_size(%KeepPlaying, _box_normal.right),
			BoxLayout.label_heights(labels, rel), BoxLayout.label_widths(labels, rel))
	_box.place(%Box.get_node("Panel"), nodes, %TryAgain, %KeepPlaying, rel)

## One push or wheel notch on the open box: the highlight and the scroll, by BoxLayout's rule.
func _push_box(push: BoxLayout.Push) -> void:
	if _box_frame == null:
		return
	var side := BoxLayout.Side.LEFT if rules.selected == DawnSave.Choice.TRY_AGAIN else BoxLayout.Side.RIGHT
	var after := _box_frame.pushed(push, side)
	rules.select(DawnSave.Choice.TRY_AGAIN if after.x == BoxLayout.Side.LEFT else DawnSave.Choice.KEEP_PLAYING)
	_box_offset = after.y

## Frames the laid-out box to the room between the screen top and the strip. Only while the box is open.
func _frame_box() -> void:
	if rules == null or not rules.box_open or _box == null or strip == null or not is_inside_tree():
		return
	var b := ScrollWindow.band((%Box as Control).get_global_transform_with_canvas(), strip.screen_top())
	_box_frame = _box.framed(b.x, b.y, _box_offset)
	_box_offset = _box_frame.offset
	_box_frame.place_frame(_box_panel(), _box_panel().get_node("Clip"),
			_box_panel().get_node("Clip/Content"), _box_panel().get_node("Marks"))

func _frame_box_later() -> void:
	_frame_box.call_deferred()

func _box_panel() -> Control:
	return %Box.get_node("Panel")

func _draw_box_marks() -> void:
	if _box_frame == null or not rules.box_open:
		return
	var marks: Control = _box_panel().get_node("Marks")
	if _box_frame.shows_mark_above():
		ScrollWindow.draw_mark(marks, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, marks.size), true), true)
	if _box_frame.shows_mark_below():
		ScrollWindow.draw_mark(marks, ScrollWindow.mark_centre(Rect2(Vector2.ZERO, marks.size), false), false)

func _connect_button(button: Control, which: DawnSave.Choice) -> void:
	button.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if PointerRule.is_move(event):
			rules.select(which)
			_refresh()
		elif click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
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

func _exit_tree() -> void:
	InputDevice.set_menu_open(self, false)

func _refresh() -> void:
	InputDevice.set_menu_open(self, rules.box_open)
	%Dawn.visible = rules.line.is_showing()
	%Dawn.modulate.a = rules.line.alpha()
	%Box.visible = rules.box_open
	if rules.box_open and not _box_was_open:
		_box_offset = 0
	if rules.box_open:
		_frame_box()
	_box_was_open = rules.box_open
	Plate.paint(%TryAgain, rules.selected == DawnSave.Choice.TRY_AGAIN)
	Plate.paint(%KeepPlaying, rules.selected == DawnSave.Choice.KEEP_PLAYING)

func _style_for(button: DawnSave.Choice) -> StyleBox:
	return Plate.style(rules.selected == button)
