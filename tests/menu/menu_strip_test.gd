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

func test_starts_on_select_with_keys() -> void:
	assert_str(strip.text()).is_equal("[Enter] Select")
	assert_vector(strip.position).is_equal(Vector2(4, 164))
	assert_vector(strip.size).is_equal(Vector2(84, 12))
	assert_int(strip.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

func test_select_back_lays_out() -> void:
	strip.show_hint(DeviceHints.Hint.SELECT_BACK)
	assert_str(strip.text()).is_equal("[Enter] Select   [Esc] Back")
	assert_vector(strip.size).is_equal(Vector2(148, 12))
	assert_vector(strip.position).is_equal(Vector2(4, 164))

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
