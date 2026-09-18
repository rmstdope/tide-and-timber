extends GdUnitTestSuite
## The clock plank is the HUD's own wood, every line drawn over the world is pale, and the boxes the
## player opens are left where they were.

const IN_PLAY_LINES := {
	"res://src/day_night/day_night.tscn": ["Hud/Plank/DayLabel", "Hud/Plank/TimeLabel", "SunsetLayer/Sunset/Text"],
	"res://src/autosave/autosave.tscn": ["Line/Dawn/Text"],
	"res://src/beach/beach.tscn": ["ShelterLineLayer/ShelterLine/Text"],
	"res://src/waking/waking.tscn": ["Night/LineLayer/NightLine/Text", "Night/BlackLineLayer/BlackLine"],
}

func _scene(path: String) -> Node:
	return auto_free((load(path) as PackedScene).instantiate())

func test_the_clock_plank_is_the_hud_plank() -> void:
	var root := _scene("res://src/day_night/day_night.tscn")
	var plank := root.get_node("Hud/Plank") as Control
	var style := plank.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_str(style.resource_path).is_equal("res://src/hud/plank.tres")
	assert_bool(style.bg_color.is_equal_approx(HudColours.WOOD)).is_true()
	assert_bool(style.border_color.is_equal_approx(HudColours.WOOD_DARK)).is_true()
	for side: String in ["left", "top", "right", "bottom"]:
		assert_int(style.get("border_width_%s" % side)).is_equal(2)

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

func test_the_dawn_save_box_is_untouched() -> void:
	var root := _scene("res://src/autosave/autosave.tscn")
	var box := root.get_node("BoxLayer/Box/Panel") as Control
	var style := box.get_theme_stylebox(&"panel") as StyleBoxFlat
	assert_str(style.resource_path).is_equal("res://src/title/plank.tres")

func test_the_move_hint_words_are_pale() -> void:
	var root := _scene("res://src/waking/waking.tscn")
	var line := root.get_node("MoveHintLayer/MoveHint/Line") as HintView
	assert_bool(line.word_colour.is_equal_approx(HudColours.PALE)).is_true()
