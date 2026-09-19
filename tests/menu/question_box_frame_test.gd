extends GdUnitTestSuite
## Every question box's panel is the one knobbed frame (tr-1ci.5).

const FRAME_PATH := "res://src/hud/frame.tres"

func test_every_question_box_panel_is_the_frame() -> void:
	var frame := load(FRAME_PATH)
	for pair: Array in [
		["res://src/pause/pause.tscn", "Board/QuitBox/Panel"],
		["res://src/title/title_screen.tscn", "StartOverBox"],
		["res://src/title/title_screen.tscn", "ReplaceBox"],
		["res://src/autosave/autosave.tscn", "BoxLayer/Box/Panel"],
		["res://src/settings/controls_page.tscn", "Box/Panel"],
	]:
		var root := auto_free((load(pair[0]) as PackedScene).instantiate()) as Node
		var panel := root.get_node(pair[1] as String) as Control
		assert_bool(is_same(panel.get_theme_stylebox("panel"), frame)) \
			.override_failure_message("%s %s is not the knobbed frame" % pair).is_true()
