extends GdUnitTestSuite

# The pixel-art project settings tr-ae0.1 pins; copied from its EXPECTED unchanged.
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
	"application/run/main_scene": "res://src/main/main.tscn",
}

func test_project_settings_match_the_pixel_art_setup() -> void:
	for key: String in EXPECTED:
		var expected: Variant = EXPECTED[key]
		var actual: Variant = ProjectSettings.get_setting(key)
		assert_that([typeof(actual), actual]) \
			.override_failure_message("%s: expected %s, got %s" % [key, expected, actual]) \
			.is_equal([typeof(expected), expected])

func test_main_scene_is_an_empty_node2d_named_main() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var scene := load(path) as PackedScene
	assert_object(scene).is_not_null()
	var main: Node = auto_free(scene.instantiate())
	assert_object(main).is_instanceof(Node2D)
	assert_str(String(main.name)).is_equal("Main")
	assert_int(main.get_child_count()).is_equal(0)
