extends GdUnitTestSuite

# The pixel-art project settings tr-ae0.1 pins, plus the title screen wiring from tr-b4o.1.
const EXPECTED := {
	"display/window/size/viewport_width": 320,
	"display/window/size/viewport_height": 180,
	"display/window/stretch/mode": "viewport",
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
