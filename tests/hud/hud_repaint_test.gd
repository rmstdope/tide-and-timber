extends GdUnitTestSuite
## Nothing drawn over the living world holds a colour of its own: every one comes from HudColours.

const IN_PLAY := [
	"res://src/hud/item_bar.gd", "res://src/hud/item_slot.gd", "res://src/hud/use_prompt.gd",
	"res://src/hud/rising_line.gd", "res://src/hud/click_mark.gd", "res://src/hud/hint_line.gd",
	"res://src/hud/hint_view.gd", "res://src/camp/key_hint.gd", "res://src/camp/build_list.gd",
	"res://src/day_night/clock_dial.gd", "res://src/autosave/journal_icon.gd",
	"res://src/night/morning_card_view.gd",
]

func test_in_play_scripts_hold_no_colour_literals() -> void:
	var bad := ""
	for path: String in IN_PLAY:
		var text := FileAccess.get_file_as_string(path)
		assert_str(text).override_failure_message("could not read %s" % path).is_not_empty()
		if bad == "" and (text.contains('Color("#') or text.contains("Color8(")):
			bad = "%s still writes a colour of its own" % path
	assert_str(bad).is_empty()
