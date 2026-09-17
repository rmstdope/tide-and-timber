extends GdUnitTestSuite
## The man's sheets under assets/man/: the pack's own frames, dressed as a castaway, with the pack's
## silhouette, outline and eyes untouched.

const PACK := "res://assets/pixel_crawler/Entities/Characters/Body_A/Animations"
## Our sheet -> [pack animation name, its width]. Every sheet is 256 tall: four 64 px facing rows.
const SHEETS := {
	"idle": ["Idle", 256],
	"walk": ["Walk", 384],
	"run": ["Run", 384],
	"collect": ["Collect", 512],
}
## Our row (Walk.Facing) -> the pack facing it comes from; row 2 (LEFT) is row 3 mirrored.
const ROWS := {0: "Down", 1: "Up", 2: "Side", 3: "Side"}
const MIRRORED := 2

func _sheet(name_: String) -> Image:
	var texture := load("res://assets/man/%s.png" % name_) as Texture2D
	assert_object(texture).override_failure_message("assets/man/%s.png did not load" % name_).is_not_null()
	return null if texture == null else texture.get_image()

func _pack(anim: String, facing: String) -> Image:
	return (load("%s/%s_Base/%s_%s-Sheet.png" % [PACK, anim, anim, facing]) as Texture2D).get_image()

## The pack pixel our pixel (x, y) of `row` frame `frame` comes from, mirrored for the LEFT row.
func _source(pack: Image, row: int, frame: int, x: int, y: int) -> Color:
	return pack.get_pixel(frame * 64 + (63 - x if row == MIRRORED else x), y)

func test_sheets_are_the_pack_frames() -> void:
	for name_: String in SHEETS:
		var ours := _sheet(name_)
		if ours == null:
			continue
		var anim: String = SHEETS[name_][0]
		var width: int = SHEETS[name_][1]
		assert_vector(Vector2(ours.get_size())).override_failure_message(name_).is_equal(Vector2(width, 256))
		for row: int in ROWS:
			var pack := _pack(anim, ROWS[row])
			for frame in width / 64:
				for y in 64:
					for x in 64:
						var mine := ours.get_pixel(frame * 64 + x, row * 64 + y)
						var theirs := _source(pack, row, frame, x, y)
						if mine.a != theirs.a:
							assert_float(mine.a).override_failure_message(
								"%s row %d frame %d (%d, %d): alpha %.2f, pack has %.2f"
								% [name_, row, frame, x, y, mine.a, theirs.a]).is_equal(theirs.a)
							return

const SKIN := ["fac895", "d9a066", "a26543", "763d2b"]
const SHIRT := ["dfe3ed", "ced8ed", "b4c4e4", "adbcdb"]
const TROUSERS := ["4c8cce", "3b7ec2", "004d83", "0e325d"]
const HAIR := ["663b27", "4b2a1b", "301d0e", "160f09"]
const EYES := ["a7acae", "fffcfc", "4cb528"]
const OUTLINE := "000000"

const RAMPS := {"shirt": SHIRT, "trousers": TROUSERS, "hair": HAIR}
## What every frame must wear, so he reads as a castaway rather than a bare figure.
const WORN := {"shirt": 12, "trousers": 12, "hair": 6}
## Skin left below his head: his swinging arms, his shins and his bare feet.
const BARE := 8
const HEAD_ROWS := 14                   # his head is the same rigid block in every frame the pack draws

## How many pixels of frame `frame` of `row` are one of `wanted`.
func _tally(sheet: Image, row: int, frame: int, wanted: Array, from_y := 0) -> int:
	var n := 0
	for y in range(from_y, 64):
		for x in 64:
			var c := sheet.get_pixel(frame * 64 + x, row * 64 + y)
			if c.a == 1.0 and wanted.has(c.to_html(false)):
				n += 1
	return n

## The first and last rows of frame `frame` of `row` holding any of him.
func _extent(sheet: Image, row: int, frame: int) -> Vector2i:
	var top := 64
	var bottom := -1
	for y in 64:
		for x in 64:
			if sheet.get_pixel(frame * 64 + x, row * 64 + y).a > 0.0:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return Vector2i(top, bottom)

## Calls `each(sheet_name, ours, row, frame)` for every frame of every row of every sheet.
func _each_frame(each: Callable) -> void:
	for name_: String in SHEETS:
		var ours := _sheet(name_)
		if ours == null:
			continue
		for row: int in ROWS:
			for frame in int(SHEETS[name_][1]) / 64:
				each.call(name_, ours, row, frame)

func test_he_wears_a_castaway_s_clothes() -> void:
	_each_frame(func(name_: String, ours: Image, row: int, frame: int) -> void:
		for worn: String in WORN:
			var n := _tally(ours, row, frame, RAMPS[worn])
			assert_int(n).override_failure_message(
				"%s row %d frame %d: %d %s pixels, wanted at least %d"
				% [name_, row, frame, n, worn, WORN[worn]]).is_greater_equal(WORN[worn]))

func test_the_pack_s_shape_is_untouched() -> void:
	for name_: String in SHEETS:
		var ours := _sheet(name_)
		if ours == null:
			continue
		var width: int = SHEETS[name_][1]
		for row: int in ROWS:
			var pack := _pack(SHEETS[name_][0], ROWS[row])
			for frame in width / 64:
				for y in 64:
					for x in 64:
						var mine := ours.get_pixel(frame * 64 + x, row * 64 + y).to_html(false)
						var theirs := _source(pack, row, frame, x, y).to_html(false)
						# The outline and his eyes are the pack's drawing, and stay exactly where it put them.
						if theirs == OUTLINE or EYES.has(theirs):
							assert_str(mine).override_failure_message(
								"%s row %d frame %d (%d, %d): %s over the pack's %s"
								% [name_, row, frame, x, y, mine, theirs]).is_equal(theirs)
							if mine != theirs:
								return
						elif mine == OUTLINE or EYES.has(mine):
							assert_str(mine).override_failure_message(
								"%s row %d frame %d (%d, %d): %s where the pack has %s"
								% [name_, row, frame, x, y, mine, theirs]).is_equal(theirs)
							return

func test_only_pack_and_body_colours() -> void:
	var allowed := [OUTLINE] + SKIN + EYES + SHIRT + TROUSERS + HAIR
	_each_frame(func(name_: String, ours: Image, row: int, frame: int) -> void:
		for y in 64:
			for x in 64:
				var c := ours.get_pixel(frame * 64 + x, row * 64 + y)
				if c.a == 1.0 and not allowed.has(c.to_html(false)):
					assert_bool(true).override_failure_message(
						"%s row %d frame %d (%d, %d): %s is not a pack or body colour"
						% [name_, row, frame, x, y, c.to_html(false)]).is_false()
					return)
	# What he is dressed in is the pack's own palette; only his skin stays outside it, unrecoloured.
	for ramp: Array in [SHIRT, TROUSERS, HAIR]:
		for hex: String in ramp:
			assert_bool(PackPalette.has(Color(hex))).override_failure_message(
				"%s is not a colour of the pack" % hex).is_true()

func test_his_arms_and_feet_are_bare() -> void:
	_each_frame(func(name_: String, ours: Image, row: int, frame: int) -> void:
		var extent := _extent(ours, row, frame)
		# His feet: the last two rows of him wear nothing and are still his own skin.
		for y in [extent.y - 1, extent.y]:
			for x in 64:
				var c := ours.get_pixel(frame * 64 + x, row * 64 + y)
				if c.a == 1.0 and TROUSERS.has(c.to_html(false)):
					assert_bool(true).override_failure_message(
						"%s row %d frame %d: trousers on his foot at (%d, %d)"
						% [name_, row, frame, x, y]).is_false()
					return
		var feet := _tally(ours, row, frame, SKIN, extent.y - 1)
		assert_int(feet).override_failure_message(
			"%s row %d frame %d: no bare skin in his bottom two rows" % [name_, row, frame]).is_greater(0)
		# His arms, shins and feet: bare skin below his head.
		var bare := _tally(ours, row, frame, SKIN, extent.x + HEAD_ROWS)
		assert_int(bare).override_failure_message(
			"%s row %d frame %d: only %d bare pixels below his head, wanted at least %d"
			% [name_, row, frame, bare, BARE]).is_greater_equal(BARE))

func test_left_is_right_mirrored() -> void:
	for name_: String in SHEETS:
		var ours := _sheet(name_)
		if ours == null:
			continue
		for frame in int(SHEETS[name_][1]) / 64:
			for y in 64:
				for x in 64:
					var left := ours.get_pixel(frame * 64 + x, 2 * 64 + y)
					var right := ours.get_pixel(frame * 64 + 63 - x, 3 * 64 + y)
					if left != right:
						assert_str(left.to_html()).override_failure_message(
							"%s frame %d (%d, %d): left %s, right mirrored %s"
							% [name_, frame, x, y, left.to_html(), right.to_html()]).is_equal(right.to_html())
						return
