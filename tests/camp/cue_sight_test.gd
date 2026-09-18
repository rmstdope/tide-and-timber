extends GdUnitTestSuite
## The two colour-blind cues, rechecked: the red outline of a spot he cannot build on is seen against
## every ground, and the four marks are told apart, under normal, protanopic, deuteranopic and
## tritanopic sight.

const TILES := "res://assets/beach/tiles.png"

func _ground(kind: int) -> Color:
	var tiles := (load(TILES) as Texture2D).get_image()
	var counts := {}
	for y in 16:
		for x in 16:
			var hex := tiles.get_pixel(kind * 16 + x, y).to_html(false)
			counts[hex] = counts.get(hex, 0) + 1
	var best := ""
	for hex: String in counts:
		if best == "" or counts[hex] > counts[best]:
			best = hex
	return Color(best)

## The ghost's outline over each ground's commonest colour, at the ghost's own alpha. No red clears
## 8.0 over every ground: under deuteranopia a red over the jungle's green becomes that green. The pack
## red BAD scores 7.4 at worst, against 6.8 for the red it replaces, so 7.0 states an improvement.
func test_the_bad_outline_is_seen_against_every_ground() -> void:
	for kind: int in BeachLayout.Kind.values():
		var ground := _ground(kind)
		var drawn := ColourSight.over(HudColours.BAD, ground, BuildGhost.ALPHA)
		var apart := ColourSight.worst_distance(drawn, ground)
		assert_float(apart).override_failure_message(
			"over ground %d (#%s) the outline is only %.1f away" % [kind, ground.to_html(false), apart]
		).is_greater_equal(7.0)

## Every pair of marks at least 20 apart, but one: the orange "!" against the plain dash it sits beside.
## No orange in the pack reaches 20 against DIM (the nearest that does is a yellow), so that pair's
## floor is 7.0 — today's pair scores 5.8, so this still states an improvement, and under Shapes cues
## the "!" carries the meaning without colour. Every pair measures further apart than today's.
const WARN_BESIDE_DIM_FLOOR := 7.0
const APART_FLOOR := 20.0

func test_the_cues_are_told_apart() -> void:
	var marks := {
		"BAD": HudColours.BAD, "WARN": HudColours.WARN,
		"CROSS": HudColours.CROSS, "DIM": HudColours.DIM,
	}
	var names := marks.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			var pair := [names[i], names[j]]
			var floor_ := WARN_BESIDE_DIM_FLOOR if pair.has("WARN") and pair.has("DIM") else APART_FLOOR
			var apart := ColourSight.worst_distance(marks[names[i]], marks[names[j]])
			assert_float(apart).override_failure_message(
				"%s and %s are only %.1f apart" % [names[i], names[j], apart]
			).is_greater_equal(floor_)

func test_the_cues_are_the_hud_palette() -> void:
	assert_bool(CampArt.RED.is_equal_approx(HudColours.BAD)).is_true()
	assert_bool(CampArt.PALE.is_equal_approx(HudColours.CROSS)).is_true()
	assert_bool(ControlsPage.ORANGE.is_equal_approx(HudColours.WARN)).is_true()
	assert_bool(ControlsPage.QUIET.is_equal_approx(HudColours.DIM)).is_true()

func test_the_cues_keep_their_shapes() -> void:
	assert_that(CampArt.LEAN_TO_CROSS).is_equal(Rect2i(-5, -25, 11, 11))
	assert_that(CampArt.FIRE_CROSS).is_equal(Rect2i(-3, -8, 7, 7))
	assert_str(ControlsPage.SHAPES_EMPTY).is_equal("! —")
