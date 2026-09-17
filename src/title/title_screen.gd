class_name TitleScreen
extends Control
## The title screen: draws the menu from a TitleMenu and turns input into its moves.
## When the menu is taller than the screen above its strip, it scrolls to the highlight, with ▲ / ▼
## where planks are hidden.

const INTRO_SCENE := "res://src/intro/intro.tscn"
const GAME_SCENE := "res://src/waking/waking.tscn"
const MENU_TOP := 97.0                  # the menu's place: three planks with no save
const MENU_TOP_WITH_SAVE := 83.0        # four planks still clear the bottom edge
const MENU_TOP_DIMMED := 75.0           # Continue, reason line, New Game, Settings, Quit clear the bottom edge
const PLANK_MIN := Vector2(90, 18)       # a menu plank at Normal (the scene's custom_minimum_size)
const WORD_HEIGHT := 8.0
const MENU_HEIGHT := 60.0                # the menu at Normal Text size: three planks with no save
const MENU_HEIGHT_WITH_SAVE := 84.0      # Continue with its DAY line, New Game, Settings, Quit
const MENU_HEIGHT_DIMMED := 92.0         # dimmed Continue, reason line, New Game, Settings, Quit
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
var _start_over_normal: BoxLayout   # the Start over box as the scene has it; captured once in _ready
var _replace_normal: BoxLayout      # the Replace box as the scene has it; captured once in _ready
var _start_over_box: BoxLayout      # the Start over box's layout drawn now
var _replace_box: BoxLayout         # the Replace box's layout drawn now
var _start_over_frame: BoxLayout   # the Start over box framed to the room above the strip; null until first framed
var _replace_frame: BoxLayout      # the Replace box framed the same way
var _start_over_offset := 0        # whole units the Start over box's content is scrolled up
var _replace_offset := 0           # whole units the Replace box's content is scrolled up
var _box_was: TitleMenu.Box = TitleMenu.Box.NONE   # to start each box at the top when it opens
var _menu_top := MENU_TOP                # the menu's top at Normal, owned by read_save
var _menu_normal_height := MENU_HEIGHT   # the menu's height at Normal Text size, owned by read_save
var menu_offset := 0          # whole menu units scrolled up; 0 while it fits. Owned by _place_menu.
var menu_scrolls := false     # the menu does not fit the band; derived by _place_menu

## The title menu's top on screen when drawn at scale s. normal_top: its top at Normal. height: its height now,
## in menu units. normal_height: its height at Normal Text size (default: height). strip_top: the strip's top on
## screen (default, or any negative: MenuStrip.BOTTOM - KeyHint.HEIGHT * s).
## Unchanged in size (s <= 1 and height <= normal_height): normal_top. Otherwise it grows about its Normal centre,
## then moves up until its bottom is at least MENU_STRIP_GAP above strip_top, but never above y 0.
static func menu_top_at(normal_top: float, height: float, s: float, normal_height: float = -1.0,
		strip_top: float = -1.0) -> float:
	if normal_height < 0.0:
		normal_height = height
	if strip_top < 0.0:
		strip_top = MenuStrip.BOTTOM - KeyHint.HEIGHT * s
	if s <= 1.0 and height <= normal_height:
		return normal_top
	var h := height * s
	var centred := roundf(normal_top + normal_height / 2.0 - h / 2.0)
	var clear := floorf(strip_top - MENU_STRIP_GAP - h)
	return maxf(0.0, minf(centred, clear))

func _ready() -> void:
	var start_over_lines: Array[Control] = [$StartOverBox/Clip/Content/FirstLine, $StartOverBox/Clip/Content/SecondLine]
	_start_over_normal = BoxLayout.of(%StartOverBox, start_over_lines, %KeepMyIsland, %StartOver)
	var replace_lines: Array[Control] = [$ReplaceBox/Clip/Content/FirstLine, $ReplaceBox/Clip/Content/SecondLine]
	_replace_normal = BoxLayout.of(%ReplaceBox, replace_lines, %Cancel, %ReplaceStartOver)
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
	%MenuMarks.draw.connect(_draw_menu_marks)
	read_save(SaveStore.SLOT_DIR)
	Display.changed.connect(_apply_ui_size)
	get_tree().root.size_changed.connect(_apply_ui_size)
	Display.changed.connect(_frame_boxes_later)
	get_tree().root.size_changed.connect(_frame_boxes_later)
	(%StartOverBox.get_node("Marks") as Control).draw.connect(_draw_marks.bind(TitleMenu.Box.START_OVER))
	(%ReplaceBox.get_node("Marks") as Control).draw.connect(_draw_marks.bind(TitleMenu.Box.REPLACE))
	_apply_ui_size()
	_frame_boxes_later()   # again once the strip's own deferred layout has run, so screen_top() is final
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
	_menu_normal_height = MENU_HEIGHT_DIMMED if menu.continue_dimmed \
			else (MENU_HEIGHT_WITH_SAVE if exists else MENU_HEIGHT)
	%Reason.text = REASON_NEWER if reading.state == SlotReading.State.NEWER else REASON_BROKEN
	%Reason.visible = menu.continue_dimmed
	%DayLine.text = "DAY %d" % saved_day
	%DayLine.visible = saved_day > 0
	menu_offset = 0   # a newly read menu opens at the top
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
		# Wheel events are not menu steps, so they are read before the match, never inside it.
		var click := event as InputEventMouseButton
		if click != null and click.pressed and \
				(click.button_index == MOUSE_BUTTON_WHEEL_UP or click.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_push_box(BoxLayout.Push.WHEEL_UP if click.button_index == MOUSE_BUTTON_WHEEL_UP \
					else BoxLayout.Push.WHEEL_DOWN)
			_refresh()
			get_viewport().set_input_as_handled()
			return
		match step:
			MenuPush.Step.LEFT:
				_push_box(BoxLayout.Push.LEFT)
			MenuPush.Step.RIGHT:
				_push_box(BoxLayout.Push.RIGHT)
			MenuPush.Step.UP:
				_push_box(BoxLayout.Push.UP)
			MenuPush.Step.DOWN:
				_push_box(BoxLayout.Push.DOWN)
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
	if menu.box != _box_was:
		_start_over_offset = 0    # a box always opens at the top, words showing
		_replace_offset = 0
	_box_was = menu.box
	%Continue.visible = TitleMenu.Choice.CONTINUE in menu.choices
	%Continue.add_theme_stylebox_override("panel",
			PLANK_DIMMED_STYLE if menu.continue_dimmed else _style_for(TitleMenu.Choice.CONTINUE))
	(%Continue.get_node("Lines/Label") as GrownWords).words().add_theme_color_override("font_color",
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
	_frame_boxes()
	_place_menu()

## The boxes and the Settings board grow about the screen centre; then the menu is placed.
func _apply_ui_size() -> void:
	_fit_boxes()   # first: the frames and pivots below are set from where the boxes now are
	var s := UiScale.current(Display.prefs, get_tree().root)
	_grow_about_centre(%SettingsBoard as Control, s)
	(%SettingsBoard as SettingsBoard).strip.relayout()   # it was laid out before the board was scaled
	_frame_boxes()
	_place_menu()
	_place_menu.call_deferred()   # decide again once the strip's own deferred layout has run

## Scales c by s about the fixed screen point (160, 90), from wherever c now is.
func _grow_about_centre(c: Control, s: float) -> void:
	c.pivot_offset = OverlayScale.ANCHOR_CENTRE - c.position
	c.scale = Vector2(s, s)

## Frames both boxes to the room above the strip, whether shown or not, and grows them about the centre.
## Does nothing before the first _fit_boxes().
func _frame_boxes() -> void:
	if _start_over_box == null or _replace_box == null or strip == null or not is_inside_tree():
		return
	var s := UiScale.current(Display.prefs, get_tree().root)
	# The band is measured in the units _fit_boxes() works in: each box carries its own scale about
	# (160, 90), so the panel's parent transform is that scale, not the box's own global transform.
	var b := ScrollWindow.band(OverlayScale.layer_transform(s, OverlayScale.ANCHOR_CENTRE), strip.screen_top())
	_start_over_frame = _frame_box(_start_over_box, %StartOverBox as Control, b, _start_over_offset, s)
	_start_over_offset = _start_over_frame.offset
	_replace_frame = _frame_box(_replace_box, %ReplaceBox as Control, b, _replace_offset, s)
	_replace_offset = _replace_frame.offset

func _frame_box(box: BoxLayout, panel: Control, b: Vector2, offset: int, s: float) -> BoxLayout:
	var f := box.framed(b.x, b.y, offset)
	f.place_frame(panel, panel.get_node("Clip") as Control,
			panel.get_node("Clip/Content") as Control, panel.get_node("Marks") as Control)
	_grow_about_centre(panel, s)   # after place_frame: the pivot follows the framed position
	return f

func _frame_boxes_later() -> void:
	_frame_boxes.call_deferred()

## The open box's framed layout, or null while no box is open or none has been framed yet.
func _open_box_frame() -> BoxLayout:
	return _start_over_frame if menu.box == TitleMenu.Box.START_OVER else _replace_frame

## One push or wheel notch on the open box: the highlight and the scroll, by BoxLayout's rule.
func _push_box(push: BoxLayout.Push) -> void:
	var f := _open_box_frame()
	if f == null:
		return
	var left := _box_left_button()
	var after := f.pushed(push, BoxLayout.Side.LEFT if menu.box_selected == left else BoxLayout.Side.RIGHT)
	menu.select_box(left if after.x == BoxLayout.Side.LEFT else TitleMenu.BoxButton.START_OVER)
	if menu.box == TitleMenu.Box.START_OVER:
		_start_over_offset = after.y
	else:
		_replace_offset = after.y

## The centre one mark is drawn on, in that box's Marks units: the box's horizontal centre, in the
## top mark row (up) or the bottom one.
func box_mark_centre(which: TitleMenu.Box, up: bool) -> Vector2:
	var marks := _box_marks(which)
	return Vector2(marks.size.x / 2.0, ScrollWindow.MARK_ROW / 2.0) if up \
			else Vector2(marks.size.x / 2.0, marks.size.y - ScrollWindow.MARK_ROW / 2.0)

func _box_marks(which: TitleMenu.Box) -> Control:
	return (%StartOverBox if which == TitleMenu.Box.START_OVER else %ReplaceBox).get_node("Marks") as Control

func _draw_marks(which: TitleMenu.Box) -> void:
	var f := _start_over_frame if which == TitleMenu.Box.START_OVER else _replace_frame
	if f == null or menu.box != which:
		return
	var marks := _box_marks(which)
	if f.shows_mark_above():
		ScrollWindow.draw_mark(marks, box_mark_centre(which, true), true)
	if f.shows_mark_below():
		ScrollWindow.draw_mark(marks, box_mark_centre(which, false), false)

## Lays both title boxes out for the current UI scale: side by side, or stacked when too wide.
## Both are laid out whether shown or not, so a box opens already fitted.
func _fit_boxes() -> void:
	var s := UiScale.current(Display.prefs, get_tree().root)
	_start_over_box = _fit_box(_start_over_normal, %StartOverBox, %KeepMyIsland, %StartOver, s)
	_replace_box = _fit_box(_replace_normal, %ReplaceBox, %Cancel, %ReplaceStartOver, s)

func _fit_box(normal: BoxLayout, panel: Control, left: Control, right: Control, s: float) -> BoxLayout:
	var labels: Array[Label] = [panel.get_node("Clip/Content/FirstLine"), panel.get_node("Clip/Content/SecondLine")]
	var lines: Array[Control] = [panel.get_node("Clip/Content/FirstLine"), panel.get_node("Clip/Content/SecondLine")]
	var layout := normal.at(s, left.size, right.size, BoxLayout.label_heights(labels))
	layout.place(panel, lines, left, right)
	return layout

## The open box's left (stacked: top) button.
func _box_left_button() -> TitleMenu.BoxButton:
	return TitleMenu.BoxButton.KEEP_MY_ISLAND if menu.box == TitleMenu.Box.START_OVER else TitleMenu.BoxButton.CANCEL

## The menu grows about its own centre and keeps clear of the strip. Runs after visibility is set.
func _place_menu() -> void:
	var s := UiScale.current(Display.prefs, get_tree().root)
	var m := %Menu as Control
	m.pivot_offset = Vector2.ZERO
	m.scale = Vector2(s, s)
	var rel := TextScale.relative(Display.prefs, get_tree().root)
	var room := floorf((320.0 - 2.0 * SpokenLine.SCREEN_MARGIN) / s)
	(%Reason as GrownWords).max_width = room
	var inner := room - PLANK_STYLE.get_minimum_size().x
	for words: GrownWords in [%Continue.get_node("Lines/Label"), %DayLine,
			%NewGame.get_node("Label"), %Settings.get_node("Label"), %Quit.get_node("Label")]:
		words.max_width = inner
	var planks: Array[Control] = [%Continue, %NewGame, %Settings, %Quit]
	for p: Control in planks:
		p.custom_minimum_size = PLANK_MIN
	var widest := PLANK_MIN.x
	for p: Control in planks:
		if p.visible:
			widest = maxf(widest, p.get_combined_minimum_size().x)
	for p: Control in planks:
		p.custom_minimum_size = Vector2(widest, PLANK_MIN.y + ceilf(WORD_HEIGHT * rel) - WORD_HEIGHT)
	var height := m.get_combined_minimum_size().y
	m.size.y = height   # a Container never shrinks by itself; keep its rect to the planks shown
	var x := roundf(160.0 - 160.0 * s)
	var b := ScrollWindow.band(Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO), strip.screen_top())
	var band_h := b.y - b.x
	if height <= band_h:
		menu_scrolls = false
		menu_offset = 0
		(%MenuClip as Control).position = Vector2.ZERO
		(%MenuClip as Control).size = Vector2(320, 180)
		m.position = Vector2(x, menu_top_at(_menu_top, height, s, _menu_normal_height, strip.screen_top()))
		%MenuMarks.position = Vector2(x, 0)
		%MenuMarks.scale = Vector2(s, s)
		(%MenuMarks as Control).size = Vector2(320, band_h)
		%MenuMarks.visible = false
	else:
		menu_scrolls = true
		var view_h := band_h - 2.0 * ScrollWindow.MARK_ROW
		var e := _choice_extent(menu.highlighted)
		menu_offset = ScrollWindow.follow(height, view_h, e.x, e.y, menu_offset)
		(%MenuClip as Control).position = Vector2(0, (b.x + ScrollWindow.MARK_ROW) * s)
		(%MenuClip as Control).size = Vector2(320, view_h * s)
		m.position = Vector2(x, -menu_offset * s)   # relative to the clip
		%MenuMarks.position = Vector2(x, b.x * s)
		%MenuMarks.scale = Vector2(s, s)
		(%MenuMarks as Control).size = Vector2(320, band_h)
		# the marks belong to the menu the player is in: the Settings board is over it, with its own strip
		%MenuMarks.visible = not menu.settings_open
		%MenuMarks.queue_redraw()

## True while ▲ is drawn over the title menu.
func shows_menu_mark_above() -> bool:
	return menu_scrolls and ScrollWindow.hidden_above(menu_offset)

## True while ▼ is drawn under the title menu.
func shows_menu_mark_below() -> bool:
	return menu_scrolls and ScrollWindow.hidden_below(menu_offset, (%Menu as Control).size.y,
			(%MenuClip as Control).size.y / (%Menu as Control).scale.y)

# The choice's extent in menu units, added up from the shown children's minimum sizes: a VBoxContainer
# sorts later in the frame, so their positions are not readable yet. The first selectable choice reaches
# the menu's top, so a dimmed Continue and its reason line come into view; the last reaches its bottom.
func _choice_extent(choice: TitleMenu.Choice) -> Vector2:
	var m := %Menu as Control
	var wanted := _plank_for(choice)
	var separation := float(m.get_theme_constant("separation"))
	var y := 0.0
	var top := 0.0
	var bottom := m.size.y
	var first := true
	for child: Control in m.get_children():
		if not child.visible:
			continue
		if not first:
			y += separation
		first = false
		var h := child.get_combined_minimum_size().y
		if child == wanted:
			top = y
			bottom = y + h
			break
		y += h
	var selectable := menu.selectable()
	if choice == selectable[0]:
		top = 0.0
	if choice == selectable[selectable.size() - 1]:
		bottom = m.size.y
	return Vector2(top, bottom)

func _plank_for(choice: TitleMenu.Choice) -> Control:
	match choice:
		TitleMenu.Choice.CONTINUE:
			return %Continue
		TitleMenu.Choice.NEW_GAME:
			return %NewGame
		TitleMenu.Choice.SETTINGS:
			return %Settings
	return %Quit

func _draw_menu_marks() -> void:
	var marks := %MenuMarks as Control
	if shows_menu_mark_above():
		ScrollWindow.draw_mark(marks, Vector2(160, ScrollWindow.MARK_ROW / 2.0), true)
	if shows_menu_mark_below():
		ScrollWindow.draw_mark(marks, Vector2(160, marks.size.y - ScrollWindow.MARK_ROW / 2.0), false)

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
