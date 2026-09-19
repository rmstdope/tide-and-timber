extends GdUnitTestSuite
## The clock sits in the knobbed frame, every line drawn over the world is pale, and the boxes the
## player opens are left where they were.

const IN_PLAY_LINES := {
	"res://src/day_night/day_night.tscn": ["Hud/Plank/DayLabel", "Hud/Plank/TimeLabel", "SunsetLayer/Sunset/Text"],
	"res://src/autosave/autosave.tscn": ["Line/Dawn/Text"],
	"res://src/beach/beach.tscn": ["ShelterLineLayer/ShelterLine/Text"],
	"res://src/waking/waking.tscn": ["Night/LineLayer/NightLine/Text", "Night/BlackLineLayer/BlackLine"],
}

func _scene(path: String) -> Node:
	return auto_free((load(path) as PackedScene).instantiate())

func test_the_clock_sits_in_the_knobbed_frame() -> void:
	var root := _scene("res://src/day_night/day_night.tscn")
	var plank := root.get_node("Hud/Plank") as Control
	var style := plank.get_theme_stylebox(&"panel") as StyleBoxTexture
	assert_object(style).override_failure_message("the clock's panel is not a StyleBoxTexture").is_not_null()
	assert_str(style.resource_path).is_equal("res://src/hud/frame.tres")
	for side: String in ["left", "top", "right", "bottom"]:
		assert_float(style.get("texture_margin_%s" % side)).is_equal(DayNight.FRAME_EDGE)

func test_every_in_play_line_is_pale() -> void:
	for path: String in IN_PLAY_LINES:
		var root := _scene(path)
		for node_path: String in IN_PLAY_LINES[path]:
			var label := root.get_node(node_path) as Label
			assert_object(label).override_failure_message("no %s in %s" % [node_path, path]).is_not_null()
			var colour := label.get_theme_color(&"font_color")
			assert_bool(colour.is_equal_approx(HudColours.PALE)) \
				.override_failure_message("%s in %s is #%s" % [node_path, path, colour.to_html(false)]) \
				.is_true()

func test_the_dawn_save_box_is_the_knobbed_frame() -> void:
	var root := _scene("res://src/autosave/autosave.tscn")
	var box := root.get_node("BoxLayer/Box/Panel") as Control
	var style := box.get_theme_stylebox(&"panel")
	assert_str(style.resource_path).is_equal("res://src/hud/frame.tres")

func test_the_move_hint_words_are_pale() -> void:
	var root := _scene("res://src/waking/waking.tscn")
	var line := root.get_node("MoveHintLayer/MoveHint/Line") as HintView
	assert_bool(line.word_colour.is_equal_approx(HudColours.PALE)).is_true()
