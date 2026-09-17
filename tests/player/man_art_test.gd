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
