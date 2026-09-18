extends GdUnitTestSuite
## A menu's Select / Back strip: its words, its corner, and the device it follows.

var strip: MenuStrip

func before_test() -> void:
	InputDevice.reset()
	strip = auto_free(MenuStrip.new()) as MenuStrip
	add_child(strip)

func after_test() -> void:
	InputDevice.reset()

func _pad_press(pad_name: String) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = JOY_BUTTON_A
	e.pressed = true
	InputDevice.tracker.observe(e, pad_name)

## The strip's origin at scale s: its bottom-left corner pinned at (LEFT, BOTTOM).
func _corner(s: float) -> Vector2:
	return Vector2(MenuStrip.LEFT, MenuStrip.BOTTOM - KeyHint.HEIGHT * s)

func test_starts_on_select_with_keys() -> void:
	assert_str(strip.text()).is_equal("[Enter] Select")
	assert_vector(strip.position).is_equal(_corner(1.0))
	assert_vector(strip.size).is_equal(Vector2(84, 12))
	assert_int(strip.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

func test_select_back_lays_out() -> void:
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	assert_str(strip.text()).is_equal("[Enter] Select   [Esc] Back")
	assert_vector(strip.size).is_equal(Vector2(148, 12))
	assert_vector(strip.position).is_equal(_corner(1.0))

func test_follows_a_pad_press_and_resizes() -> void:
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	_pad_press("PS5 Controller")
	assert_str(strip.text()).is_equal("(✕) Select   (○) Back")
	assert_float(strip.size.x).is_equal(124.0)

func test_mouse_motion_does_not_switch_it() -> void:
	_pad_press("PS5 Controller")
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(3, 0)
	InputDevice.tracker.observe(move, "")
	assert_str(strip.text()).is_equal("(✕) Select")

func test_click_switches_it_to_keys() -> void:
	_pad_press("PS5 Controller")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	InputDevice.tracker.observe(click, "")
	assert_str(strip.text()).is_equal("[Enter] Select")

func test_stick_inside_the_dead_zone_does_not_switch_it() -> void:
	var tilt := InputEventJoypadMotion.new()
	tilt.axis = JOY_AXIS_LEFT_X
	tilt.axis_value = 0.1
	InputDevice.tracker.observe(tilt, "Xbox Series Controller")
	assert_str(strip.text()).is_equal("[Enter] Select")
	tilt.axis_value = 0.2
	InputDevice.tracker.observe(tilt, "Xbox Series Controller")
	assert_str(strip.text()).is_equal("(A) Select")

func test_unplugging_the_last_pad_shows_keys() -> void:
	_pad_press("Xbox Series Controller")
	InputDevice.tracker.pad_disconnected(0, PackedStringArray())
	assert_str(strip.text()).is_equal("[Enter] Select")

# --- UI size: the strip grows but keeps its bottom-left corner on screen ---

var _saved_size: Vector2i
var _saved_mode: Window.ContentScaleMode

func _big_root() -> void:
	_saved_size = get_tree().root.size
	_saved_mode = get_tree().root.content_scale_mode
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.size = Vector2i(1280, 720)
	Display.use_prefs(DisplayPrefs.new())

func _restore_root() -> void:
	Display.use_prefs(DisplayPrefs.new())
	get_tree().root.size = _saved_size
	get_tree().root.content_scale_mode = _saved_mode

func _step(times: int) -> void:
	for i in times:
		Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)

func test_screen_transform_pins_the_bottom_left() -> void:
	assert_bool(MenuStrip.screen_transform(1.0) == Transform2D(0.0, Vector2.ONE, 0.0, _corner(1.0))).is_true()
	assert_vector(MenuStrip.screen_transform(2.0).origin).is_equal(_corner(2.0))
	assert_vector(MenuStrip.screen_transform(2.0).get_scale()).is_equal(Vector2(2, 2))
	assert_vector(MenuStrip.screen_transform(1.5).origin).is_equal(_corner(1.5))

func test_grows_in_the_corner_under_a_scaled_layer() -> void:
	_big_root()
	var layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var scaler := UiScale.new()
	scaler.anchor = OverlayScale.ANCHOR_CENTRE
	layer.add_child(scaler)
	var host := Control.new()
	host.size = Screen.SIZE
	layer.add_child(host)
	add_child(layer)
	var s := MenuStrip.new()
	host.add_child(s)
	s.show_hint(DeviceHints.Hint.SELECT_BACK)
	_step(2)
	await get_tree().process_frame
	var t := s.get_global_transform_with_canvas()
	assert_vector(t.origin).is_equal_approx(_corner(2.0), Vector2(0.01, 0.01))
	assert_vector(t.get_scale()).is_equal_approx(Vector2(2, 2), Vector2(0.01, 0.01))
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	t = s.get_global_transform_with_canvas()
	assert_vector(t.origin).is_equal_approx(_corner(1.0), Vector2(0.01, 0.01))
	assert_vector(t.get_scale()).is_equal_approx(Vector2(1, 1), Vector2(0.01, 0.01))
	_restore_root()

func test_grows_in_the_corner_under_a_scaled_control() -> void:
	_big_root()
	var host := auto_free(Control.new()) as Control
	host.size = Screen.SIZE
	host.pivot_offset = Screen.CENTRE
	host.scale = Vector2(1.5, 1.5)
	add_child(host)
	var s := MenuStrip.new()
	host.add_child(s)
	_step(1)
	await get_tree().process_frame
	var t := s.get_global_transform_with_canvas()
	assert_vector(t.origin).is_equal_approx(_corner(1.5), Vector2(0.01, 0.01))
	assert_vector(t.get_scale()).is_equal_approx(Vector2(1.5, 1.5), Vector2(0.01, 0.01))
	_restore_root()

func test_unscaled_host_grows_it_in_place() -> void:
	_big_root()
	var host := auto_free(Control.new()) as Control
	add_child(host)
	var s := MenuStrip.new()
	host.add_child(s)
	_step(2)
	await get_tree().process_frame
	assert_vector(s.position).is_equal_approx(_corner(2.0), Vector2(0.001, 0.001))
	assert_vector(s.scale).is_equal(Vector2(2, 2))
	_restore_root()

# --- lifting above a grown item bar ---

func _bar() -> ItemBar:
	var layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var ui := UiScale.new()
	ui.anchor = OverlayScale.ANCHOR_BOTTOM_CENTRE
	layer.add_child(ui)
	var bar := ItemBar.new()
	layer.add_child(bar)
	add_child(layer)
	return bar

func _hosted_strip() -> MenuStrip:
	var layer := auto_free(CanvasLayer.new()) as CanvasLayer
	var ui := UiScale.new()
	ui.anchor = OverlayScale.ANCHOR_CENTRE
	layer.add_child(ui)
	var host := Control.new()
	host.size = Screen.SIZE
	layer.add_child(host)
	add_child(layer)
	var s := MenuStrip.new()
	host.add_child(s)
	s.show_hint(DeviceHints.Hint.SELECT_BACK)
	return s

func _origin(s: MenuStrip) -> Vector2:
	return s.get_global_transform_with_canvas().origin

func test_lifts_above_a_grown_bar() -> void:
	_big_root()
	_bar()
	var s := _hosted_strip()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	await get_tree().process_frame
	# the bar's top at 2x is Screen.HEIGHT - 2 * 23; the strip sits 2 above it, 2 * 12 tall
	var lifted := Vector2(MenuStrip.LEFT, Screen.HEIGHT - 2 * 23 - 2 - 2 * KeyHint.HEIGHT)
	assert_vector(_origin(s)).is_equal_approx(lifted, Vector2(0.01, 0.01))
	assert_vector(s.get_global_transform_with_canvas().get_scale()).is_equal_approx(Vector2(2, 2), Vector2(0.01, 0.01))
	assert_float(s.screen_top()).is_equal_approx(lifted.y, 0.01)
	Display.use_prefs(DisplayPrefs.new())
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 1)
	await get_tree().process_frame
	assert_vector(_origin(s)).is_equal_approx(Vector2(MenuStrip.LEFT, Screen.HEIGHT - 1.5 * 23 - 2 - 1.5 * KeyHint.HEIGHT), Vector2(0.01, 0.01))
	_restore_root()

func test_does_not_lift_at_normal() -> void:
	_big_root()
	_bar()
	var s := _hosted_strip()
	await get_tree().process_frame
	assert_vector(_origin(s)).is_equal_approx(_corner(1.0), Vector2(0.01, 0.01))
	assert_float(s.screen_top()).is_equal_approx(_corner(1.0).y, 0.01)
	_restore_root()

func test_does_not_lift_over_a_hidden_bar() -> void:
	_big_root()
	_bar().hide()
	var s := _hosted_strip()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	await get_tree().process_frame
	assert_vector(_origin(s)).is_equal_approx(_corner(2.0), Vector2(0.01, 0.01))
	_restore_root()

func test_no_bar_no_lift() -> void:
	_big_root()
	var s := _hosted_strip()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	await get_tree().process_frame
	assert_vector(_origin(s)).is_equal_approx(_corner(2.0), Vector2(0.01, 0.01))
	_restore_root()

func test_returns_to_the_corner_back_at_normal() -> void:
	_big_root()
	_bar()
	var s := _hosted_strip()
	Display.prefs.step(DisplayPrefs.Setting.UI_SIZE, 2)
	await get_tree().process_frame
	Display.use_prefs(DisplayPrefs.new())
	await get_tree().process_frame
	assert_vector(_origin(s)).is_equal_approx(_corner(1.0), Vector2(0.01, 0.01))
	assert_vector(s.get_global_transform_with_canvas().get_scale()).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
	_restore_root()
