extends GdUnitTestSuite
## The title's Start over and Replace boxes at large UI and Text sizes: framed to the room above the strip,
## scrolling their words and buttons a line per push or wheel notch, with ▲ / ▼.
## At 640x360 UI size alone never makes a box scroll, so the scrolling layout is reached the way a player
## does, in the default 1280x720 window (k = 2), at UI Largest + Text Largest: the only combination at
## which either box outgrows the room above the strip. Every test about a scrolling box first asserts that
## it scrolls, so none can pass on the plain layout.

const SCENE := "res://src/title/title_screen.tscn"
const ROOT := "user://test_saves"
const DIR := "user://test_saves/title_box_scroll"
const EPS := Vector2(0.01, 0.01)

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode
var runner: GdUnitSceneRunner
var screen: TitleScreen
var calls: Array[String] = []

func before_test() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())

func after_test() -> void:
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode
	_rm(ROOT)
	InputDevice.reset()

func _rm(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		return
	if not DirAccess.dir_exists_absolute(path):
		return
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	for d in DirAccess.get_directories_at(path):
		_rm(path.path_join(d))
	DirAccess.remove_absolute(path)

func _sample() -> SaveData:
	var d := SaveData.new()
	var slots: Array[Dictionary] = [{"kind": Item.Kind.DRIFTWOOD, "count": 3}, {}, {}, {}, {}, {}, {}, {}]
	d.inventory_slots = slots
	var none: Array[Vector2i] = []
	d.taken = {"driftwood": none, "shellfish": none.duplicate()}
	d.player_position = Vector2(400, 200)
	d.player_facing = Walk.Facing.LEFT
	d.clock_minutes = 4680.0
	return d

func _write_meta(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(text)
	f.close()

func _open(dir: String) -> void:
	InputDevice.reset()
	calls = []
	runner = scene_runner(SCENE)
	screen = runner.scene() as TitleScreen
	var recorded := calls
	screen.quit_game = func() -> void: recorded.append("quit")
	screen.start_new_game = func() -> void: recorded.append("new_game")
	screen.start_continue = func() -> void: recorded.append("continue")
	screen.read_save(dir)

func _saved() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_open(DIR)

func _newer() -> void:
	SaveStore.save_slot(_sample(), DIR)
	_write_meta(JSON.stringify({"version": 2, "game_version": "0.4"}))
	_open(DIR)

func _plank(unique: String) -> PanelContainer:
	return screen.get_node("%" + unique) as PanelContainer

func _box_highlighted(unique: String) -> void:
	var buttons := ["KeepMyIsland", "StartOver"] if unique in ["KeepMyIsland", "StartOver"] else ["Cancel", "ReplaceStartOver"]
	for button: String in buttons:
		var want := TitleScreen.PLANK_HIGHLIGHT_STYLE if button == unique else TitleScreen.PLANK_STYLE
		assert_object(_plank(button).get_theme_stylebox("panel")) \
			.override_failure_message("%s should%s be highlighted" % [button, "" if button == unique else " not"]) \
			.is_same(want)

func _press(key: Key) -> void:
	runner.simulate_key_pressed(key)
	await runner.await_input_processed()

func _open_start_over_box() -> void:
	_saved()
	await _press(KEY_DOWN)
	await _press(KEY_ENTER)

func _open_replace_box() -> void:
	_newer()
	await _press(KEY_ENTER)

func _ui(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func _text(steps: int) -> void:
	for i in steps:
		Display.prefs.step(DisplayPrefs.Setting.TEXT_SIZE, 1)

## One step short of the scrolling layout: UI Large + Text Largest (Start over stacks, still fits).
func _large() -> void:
	_ui(1)
	_text(2)

## UI Largest + Text Largest: both boxes scroll.
func _largest() -> void:
	_ui(2)
	_text(2)

## The precondition every scrolling test asserts first.
func _assert_scrolls(box: String) -> void:
	var frame: BoxLayout = screen._start_over_frame if box == "StartOverBox" else screen._replace_frame
	assert_bool(frame.scrolls).override_failure_message("%s should scroll" % box).is_true()

func _control(path: String) -> Control:
	return screen.get_node(path) as Control

func _rect(path: String) -> Rect2:
	var n := _control(path)
	return Rect2(n.position, n.size)

func _clip(box: String) -> Control:
	return _control("%" + box + "/Clip")

func _content(box: String) -> Control:
	return _control("%" + box + "/Clip/Content")

func _marks(box: String) -> Control:
	return _control("%" + box + "/Marks")

## A panel centred on the picture: the boxes' rest panels grow about Screen.CENTRE.
static func _centred(w: float, h: float) -> Rect2:
	return Rect2(Screen.CENTRE - Vector2(w, h) / 2.0, Vector2(w, h))

## The room a box grown to s = 2 about the picture's centre is framed to, in its own units: (top, bottom).
func _band() -> Vector2:
	return ScrollWindow.band(Transform2D(0.0, Vector2(2, 2), 0.0, -Screen.CENTRE), screen.strip.screen_top())

## The framed panel at s = 2: the rest panel's x and width, the band's top and height.
func _framed(w: float) -> Rect2:
	var b := _band()
	return Rect2(Screen.CENTRE.x - w / 2.0, b.x, w, b.y - b.x)

## The clip inside a framed panel: a mark row kept above and below.
func _framed_clip(w: float) -> Rect2:
	var b := _band()
	return Rect2(0, ScrollWindow.MARK_ROW, w, b.y - b.x - 2.0 * ScrollWindow.MARK_ROW)

func _hover(c: Control) -> void:
	runner.simulate_mouse_move(screen.get_viewport().get_final_transform() * c.get_global_rect().get_center())
	await runner.await_input_processed()

func _wheel(button: MouseButton, times: int) -> void:
	for i in times:
		runner.simulate_mouse_button_pressed(button)
		await runner.await_input_processed()

func test_largest_opens_framed_at_the_top() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	# the Select strip, its words at Text Largest, at s = 2: 46 units above the bottom edge
	assert_float(screen.strip.screen_top()).is_equal(Screen.HEIGHT - 46.0)
	assert_that(_band()).is_equal(Vector2(91, 246))   # ceil((2 - 180) / 2 + 180), floor((314 - 2 - 180) / 2 + 180)
	assert_that(_rect("%StartOverBox")).is_equal(_framed(312))
	assert_that(Rect2(_clip("StartOverBox").position, _clip("StartOverBox").size)).is_equal(_framed_clip(312))
	# content top 8 above the clip, the rest panel's size
	assert_that(Rect2(_content("StartOverBox").position, _content("StartOverBox").size)).is_equal(Rect2(0, -8, 312, 182))
	assert_vector(_marks("StartOverBox").size).is_equal(_framed(312).size)
	assert_that(screen._start_over_box.panel).is_equal(_centred(312, 182))
	_box_highlighted("KeepMyIsland")
	assert_bool(screen._start_over_frame.shows_mark_below()).is_true()
	assert_bool(screen._start_over_frame.shows_mark_above()).is_false()

func test_the_box_still_grows_about_the_centre() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	var box := _control("%StartOverBox")
	assert_vector(box.position + box.pivot_offset).is_equal(Screen.CENTRE)
	assert_vector(box.scale).is_equal(Vector2(2, 2))
	var framed_centre := _framed(312).get_center()
	assert_vector(box.get_global_rect().get_center()) \
		.is_equal_approx(Screen.CENTRE + (framed_centre - Screen.CENTRE) * 2.0, EPS)

func test_normal_fits_unchanged() -> void:
	await _open_start_over_box()
	await get_tree().process_frame
	assert_that(_rect("%StartOverBox")).is_equal(_centred(296, 96))
	assert_that(Rect2(_clip("StartOverBox").position, _clip("StartOverBox").size)).is_equal(Rect2(0, 0, 296, 96))
	assert_vector(_content("StartOverBox").position).is_equal(Vector2.ZERO)
	assert_vector(_control("%StartOverBox").pivot_offset).is_equal(Vector2(148, 48))
	assert_bool(screen._start_over_frame.shows_mark_above()).is_false()
	assert_bool(screen._start_over_frame.shows_mark_below()).is_false()

func test_words_and_buttons_are_clipped() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	for box: String in ["StartOverBox", "ReplaceBox"]:
		var content := _content(box)
		assert_bool(_clip(box).clip_contents).is_true()
		var names := ["%KeepMyIsland", "%StartOver"] if box == "StartOverBox" else ["%Cancel", "%ReplaceStartOver"]
		for child: String in names:
			assert_bool(content.is_ancestor_of(_control(child))).override_failure_message(
					"%s should be inside %s/Clip/Content" % [child, box]).is_true()
		for line: String in ["FirstLine", "SecondLine"]:
			assert_bool(content.is_ancestor_of(_control(box + "/Clip/Content/" + line))).is_true()
		var panel := _control("%" + box)
		assert_object(panel.get_child(panel.get_child_count() - 1)).is_same(_marks(box))
		assert_int(_clip(box).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
		assert_int(content.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
		assert_int(_marks(box).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

func test_large_scrolls_too() -> void:
	await _open_start_over_box()
	_large()
	await get_tree().process_frame
	# No player reaches this at 640x360: UI Large + Text Largest stacks Start over but it still fits
	# (418x138 against a 155-tall band), and only UI Largest + Text Largest scrolls it. Left red for
	# the navigator: whether to retire this layout.
	_assert_scrolls("StartOverBox")
	if not screen._start_over_frame.scrolls:
		return
	assert_that(_rect("%StartOverBox")).is_equal(Rect2(58, 32, 204, 102))
	assert_that(Rect2(_clip("StartOverBox").position, _clip("StartOverBox").size)).is_equal(Rect2(0, 10, 204, 82))
	assert_that(Rect2(_content("StartOverBox").position, _content("StartOverBox").size)).is_equal(Rect2(0, -8, 204, 133))
	for i in 2:
		await _press(KEY_DOWN)
	_box_highlighted("StartOver")
	assert_float(_content("StartOverBox").position.y).is_equal(-41.0)

func test_replace_box_scrolls_at_largest() -> void:
	await _open_replace_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("ReplaceBox")
	assert_that(_rect("%ReplaceBox")).is_equal(_framed(312))
	assert_that(Rect2(_clip("ReplaceBox").position, _clip("ReplaceBox").size)).is_equal(_framed_clip(312))
	assert_that(Rect2(_content("ReplaceBox").position, _content("ReplaceBox").size)).is_equal(Rect2(0, -6, 312, 190))
	_box_highlighted("Cancel")
	assert_bool(screen._replace_frame.shows_mark_above()).is_false()
	assert_bool(screen._replace_frame.shows_mark_below()).is_true()
	await _press(KEY_RIGHT)
	_box_highlighted("ReplaceStartOver")
	# content top 6 plus the most it scrolls: ceil(174 content - 135 clip) = 39
	assert_float(_content("ReplaceBox").position.y).is_equal(-45.0)
	assert_bool(screen._replace_frame.shows_mark_above()).is_true()
	assert_bool(screen._replace_frame.shows_mark_below()).is_false()

func test_down_reads_the_words_then_moves_to_start_over() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	# Keep my island (content 116..136) ends one unit below the 135-tall view: one push reads it in
	await _press(KEY_DOWN)
	assert_float(_content("StartOverBox").position.y).is_equal(-9.0)   # content top 8 + offset 1
	_box_highlighted("KeepMyIsland")
	await _press(KEY_DOWN)
	_box_highlighted("StartOver")
	# content top 8 + the most it scrolls: ceil(164 content - 135 clip) = 29
	assert_float(_content("StartOverBox").position.y).is_equal(-37.0)
	assert_bool(screen._start_over_frame.shows_mark_above()).is_true()
	assert_bool(screen._start_over_frame.shows_mark_below()).is_false()

func test_up_returns_to_the_words() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _press(KEY_RIGHT)
	assert_int(screen._start_over_offset).is_equal(29)   # ceil(164 content - 135 clip)
	await _press(KEY_UP)
	_box_highlighted("KeepMyIsland")
	assert_float(_content("StartOverBox").position.y).is_equal(-37.0)
	for i in 6:
		await _press(KEY_UP)
	assert_float(_content("StartOverBox").position.y).is_equal(-8.0)
	_box_highlighted("KeepMyIsland")
	assert_bool(_control("%StartOverBox").visible).is_true()
	assert_array(calls).is_empty()

func test_left_and_right_show_the_button_they_pick() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _press(KEY_RIGHT)
	_box_highlighted("StartOver")
	assert_float(_content("StartOverBox").position.y).is_equal(-37.0)
	await _press(KEY_LEFT)
	_box_highlighted("KeepMyIsland")
	assert_float(_content("StartOverBox").position.y).is_equal(-37.0)

func test_wheel_scrolls_and_keeps_the_highlight() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _wheel(MOUSE_BUTTON_WHEEL_DOWN, 1)
	assert_float(_content("StartOverBox").position.y).is_equal(-19.0)
	_box_highlighted("KeepMyIsland")

func test_select_presses_a_hidden_highlight() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _press(KEY_ENTER)
	assert_bool(_control("%StartOverBox").visible).is_false()
	assert_int(screen.menu.highlighted).is_equal(TitleMenu.Choice.NEW_GAME)
	assert_bool(screen.menu.locked).is_false()
	assert_array(calls).is_empty()
	await _press(KEY_ENTER)
	await get_tree().process_frame
	await _press(KEY_RIGHT)
	await _press(KEY_ENTER)
	assert_bool(screen.menu.locked).is_true()
	assert_array(calls).is_empty()

func test_reopening_starts_at_the_top() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _press(KEY_RIGHT)
	assert_int(screen._start_over_offset).is_equal(29)   # ceil(164 content - 135 clip)
	await _press(KEY_ESCAPE)
	await _press(KEY_ENTER)
	await get_tree().process_frame
	assert_float(_content("StartOverBox").position.y).is_equal(-8.0)
	_box_highlighted("KeepMyIsland")

func test_size_change_while_up_refits_and_keeps_the_highlight() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	await _press(KEY_DOWN)
	assert_int(screen._start_over_offset).is_equal(1)   # Keep my island ends one unit below the view
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_that(_rect("%StartOverBox")).is_equal(_centred(296, 96))
	assert_vector(_content("StartOverBox").position).is_equal(Vector2.ZERO)
	assert_bool(screen._start_over_frame.shows_mark_above()).is_false()
	assert_bool(screen._start_over_frame.shows_mark_below()).is_false()
	_box_highlighted("KeepMyIsland")

func test_hover_lands_only_on_the_drawn_part() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	# At the top Start over (content 144..164) is wholly below the 135-tall view: out of the pointer's reach.
	assert_int(screen._start_over_offset).is_equal(0)
	await _hover(_control("%StartOver"))
	_box_highlighted("KeepMyIsland")
	assert_float(_content("StartOverBox").position.y).is_equal(-8.0)
	await _wheel(MOUSE_BUTTON_WHEEL_DOWN, 6)
	assert_int(screen._start_over_offset).is_equal(29)   # ceil(164 content - 135 clip)
	await _hover(_control("%StartOver"))
	_box_highlighted("StartOver")
	assert_float(_content("StartOverBox").position.y).is_equal(-37.0)

func test_the_marks_are_wired_and_centred_in_their_rows() -> void:
	await _open_start_over_box()
	_largest()
	await get_tree().process_frame
	_assert_scrolls("StartOverBox")
	for box: String in ["StartOverBox", "ReplaceBox"]:
		var marks := _marks(box)
		assert_that(marks.get_rect()).is_equal(Rect2(Vector2.ZERO, _framed(312).size))
		assert_int(marks.get_signal_connection_list("draw").size()) \
			.override_failure_message("%s/Marks has no draw handler, so no mark is ever drawn" % box).is_greater(0)
	# The centres _draw_marks draws on: the box's horizontal centre, in the top and bottom mark rows
	# of the 155-tall, 312-wide framed panel. Pinned as literals, so moving either mark out of its row fails here.
	assert_that(screen.box_mark_centre(TitleMenu.Box.START_OVER, true)).is_equal(Vector2(156, 5))
	assert_that(screen.box_mark_centre(TitleMenu.Box.START_OVER, false)).is_equal(Vector2(156, 150))
	assert_that(screen.box_mark_centre(TitleMenu.Box.REPLACE, true)).is_equal(Vector2(156, 5))
	assert_that(screen.box_mark_centre(TitleMenu.Box.REPLACE, false)).is_equal(Vector2(156, 150))
