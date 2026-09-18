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

func test_device_hints_keeps_only_the_controller_marks() -> void:
	assert_bool(DeviceHints.CAP_FACE.is_equal_approx(HudColours.CREAM)).is_true()
	assert_bool(DeviceHints.CAP_INK.is_equal_approx(HudColours.INK)).is_true()
	assert_str(DeviceHints.PAD_FACE.to_html(false)).is_equal("3a3a44")
	assert_str(DeviceHints.WHITE.to_html(false)).is_equal("ffffff")
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	var xbox := DeviceHints.picture_for(a, DeviceTracker.Kind.XBOX)
	assert_str(xbox.label).is_equal("A")
	assert_str(xbox.face.to_html(false)).is_equal("3f9a3f")
	assert_str(xbox.ink.to_html(false)).is_equal("ffffff")
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	var ps := DeviceHints.picture_for(y, DeviceTracker.Kind.PLAYSTATION)
	assert_str(ps.label).is_equal("△")
	assert_str(ps.face.to_html(false)).is_equal("3a3a44")
	assert_str(ps.ink.to_html(false)).is_equal("7fe0b0")

func test_the_camp_wood_is_the_hud_wood() -> void:
	assert_bool(CampArt.WOOD_DARK.is_equal_approx(HudColours.WOOD_DARK)).is_true()
	assert_bool(CampArt.WOOD.is_equal_approx(HudColours.WOOD)).is_true()
	assert_bool(CampArt.WOOD_LIGHT.is_equal_approx(HudColours.WOOD_LIGHT)).is_true()
	assert_str(CampArt.FLAME.to_html(false)).is_equal("ff9a2a")
	assert_str(CampArt.ASH.to_html(false)).is_equal("8a827a")
