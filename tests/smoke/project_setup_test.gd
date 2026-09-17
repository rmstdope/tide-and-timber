extends GdUnitTestSuite

# The pixel-art project settings tr-ae0.1 pins, plus the title screen wiring from tr-b4o.1.
const EXPECTED := {
	"display/window/size/viewport_width": 320,
	"display/window/size/viewport_height": 180,
	"display/window/stretch/mode": "canvas_items",
	"display/window/stretch/aspect": "keep",
	"display/window/stretch/scale_mode": "integer",
	"rendering/textures/canvas_textures/default_texture_filter": 0,
	"rendering/2d/snap/snap_2d_transforms_to_pixel": true,
	"rendering/2d/snap/snap_2d_vertices_to_pixel": true,
	"rendering/renderer/rendering_method": "gl_compatibility",
	"application/run/main_scene": "res://src/title/title_screen.tscn",
	"application/config/version": "0.1",
	"application/boot_splash/show_image": false,
	"gui/theme/custom_font": "res://assets/fonts/PressStart2P-Regular.ttf",
}

const MENU_KEYS := {
	"menu_up": [KEY_UP, KEY_W],
	"menu_down": [KEY_DOWN, KEY_S],
	"menu_accept": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE],
}

func test_project_settings_match_the_pixel_art_setup() -> void:
	for key: String in EXPECTED:
		var expected: Variant = EXPECTED[key]
		var actual: Variant = ProjectSettings.get_setting(key)
		assert_that([typeof(actual), actual]) \
			.override_failure_message("%s: expected %s, got %s" % [key, expected, actual]) \
			.is_equal([typeof(expected), expected])

# Read from project.godot rather than ProjectSettings: scripts/gate-fast points a gate run at a
# user:// directory of its own through an override.cfg, so the live setting is not what ships.
# What a player's copy uses is what the tracked file says.
func test_the_shipped_user_dir_is_the_players_own() -> void:
	var text := FileAccess.get_file_as_string("res://project.godot")
	assert_str(text).contains("config/use_custom_user_dir=true")
	assert_str(text).contains("config/custom_user_dir_name=\"Tide and Timber\"")

func test_main_scene_is_the_title_screen() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var scene := load(path) as PackedScene
	assert_object(scene).is_not_null()
	if scene == null:
		return
	var main: Node = auto_free(scene.instantiate())
	assert_bool(main is TitleScreen).is_true()
	assert_str(String(main.name)).is_equal("TitleScreen")

func test_menu_actions_are_bound() -> void:
	for action: String in MENU_KEYS:
		assert_bool(InputMap.has_action(action)) \
			.override_failure_message("missing action %s" % action).is_true()
		if not InputMap.has_action(action):
			continue
		for key: int in MENU_KEYS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.pressed = true
			assert_bool(InputMap.event_is_action(event, action)) \
				.override_failure_message("%s not bound to %s" % [action, OS.get_keycode_string(key)]) \
				.is_true()

func test_pause_action_is_bound() -> void:
	assert_bool(InputMap.has_action("pause")).is_true()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	assert_bool(InputMap.event_is_action(event, "pause")).is_true()

func test_box_actions_are_bound() -> void:
	var keys := [["menu_left", KEY_LEFT], ["menu_left", KEY_A], ["menu_right", KEY_RIGHT], ["menu_right", KEY_D],
			["menu_cancel", KEY_ESCAPE]]
	for pair: Array in keys:
		var action: String = pair[0]
		var e := InputEventKey.new()
		e.physical_keycode = pair[1]
		e.pressed = true
		assert_bool(InputMap.has_action(action) and InputMap.event_is_action(e, action)) \
			.override_failure_message("%s key" % action).is_true()
	var buttons := {"menu_left": JOY_BUTTON_DPAD_LEFT, "menu_right": JOY_BUTTON_DPAD_RIGHT, "menu_accept": JOY_BUTTON_A, "menu_cancel": JOY_BUTTON_B}
	for action: String in buttons:
		var b := InputEventJoypadButton.new()
		b.button_index = buttons[action]
		b.pressed = true
		assert_bool(InputMap.has_action(action) and InputMap.event_is_action(b, action)) \
			.override_failure_message("%s button" % action).is_true()
	var axes := {"menu_left": -1.0, "menu_right": 1.0}
	for action: String in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = axes[action]
		assert_bool(InputMap.has_action(action) and InputMap.event_is_action(m, action)) \
			.override_failure_message("%s stick" % action).is_true()
