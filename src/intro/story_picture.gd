class_name StoryPicture
extends Control
## One storybook picture of the shipwreck, drawn as the mockup's own rects (placeholder art).

const SKY := Color("#2e3a5c")
const CLOUD := Color("#4a5478")
const CLOUD_HI := Color("#6b7396")
const SEA := Color("#24506b")
const SEA_DEEP := Color("#173a52")
const FOAM := Color("#d8e6e8")
const LIGHTNING := Color("#fff4c2")
const WOOD := Color("#8a5a34")
const WOOD_DK := Color("#5c3a22")
const SAIL := Color("#e9dcc0")
const SHIRT := Color("#b8462e")
const RAIN := Color(Color("#9fb0d0"), 0.55)
const FLASH := Color(Color("#fff8e8"), 0.35)
const BLACK := Color("#000000")

var picture := 0:                       # 0..3; setting it calls queue_redraw()
	set(value):
		picture = value
		queue_redraw()

static func shapes(index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var full := Rect2(0, 0, 320, 180)
	match index:
		0:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(false))
			out.append_array(_waves(120, false))
			out.append_array(_ship(120, 86, 0.0, false))
			out.append_array(_rain(40))
		1:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(false))
			out.append_array(_waves(110, true))
			out.append_array(_ship(120, 74, -14.0, false))
			out.append_array(_rain(120))
			out.append_array(_bolt(230))
		2:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(true))
			out.append_array(_waves(100, true))
			out.append_array(_ship(130, 70, 35.0, true))
			out.append_array(_rain(140))
			out.append(_shape(full, FLASH))
		_:
			out.append(_shape(full, BLACK))
	return out

func _draw() -> void:
	for shape in shapes(picture):
		if shape.rotation_degrees == 0.0:
			draw_rect(shape.rect, shape.color)
			continue
		for run in PixelRuns.turned_rect(shape.rect, shape.pivot, shape.rotation_degrees):
			draw_rect(run, shape.color)

static func _shape(rect: Rect2, color: Color, rotation := 0.0, pivot := Vector2.ZERO) -> Dictionary:
	return { "rect": rect, "color": color, "rotation_degrees": rotation, "pivot": pivot }

static func _clouds(light: bool) -> Array[Dictionary]:
	return [
		_shape(Rect2(0, 0, 320, 40), CLOUD_HI if light else CLOUD),
		_shape(Rect2(20, 36, 90, 10), CLOUD),
		_shape(Rect2(160, 34, 120, 12), CLOUD),
		_shape(Rect2(60, 44, 40, 6), CLOUD),
	]

static func _waves(top: int, big: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		_shape(Rect2(0, top, 320, 180 - top), SEA),
		_shape(Rect2(0, top + 30, 320, 180), SEA_DEEP),
	]
	var h := 10 if big else 5
	var x := 0
	while x < 320:
		out.append(_shape(Rect2(x, top - h, 26 if big else 14, h), SEA))
		out.append(_shape(Rect2(x + 4, top - h, 14 if big else 8, 2), FOAM))
		x += 40 if big else 24
	return out

static func _ship(x: int, y: int, tilt: float, broken: bool) -> Array[Dictionary]:
	var pivot := Vector2(x + 30, y + 20)
	var sail := Rect2(x + 31, y - 22, 16, 8) if broken else Rect2(x + 31, y - 18, 22, 30)
	return [
		_shape(Rect2(x, y + 18, 60, 10), WOOD, tilt, pivot),
		_shape(Rect2(x + 6, y + 28, 48, 4), WOOD_DK, tilt, pivot),
		_shape(Rect2(x + 28, y - 22, 3, 40), WOOD_DK, tilt, pivot),
		_shape(sail, SAIL, tilt, pivot),
		_shape(Rect2(x + 44, y + 12, 3, 6), SHIRT, tilt, pivot),
	]

static func _rain(n: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var v := 3
	for i in n:
		v = (v * 9301 + 49297) % 233280
		var x := floori(v / 233280.0 * 330)
		v = (v * 9301 + 49297) % 233280
		var y := floori(v / 233280.0 * 180)
		out.append(_shape(Rect2(x, y, 1, 5), RAIN))
	return out

static func _bolt(x: int) -> Array[Dictionary]:
	return [
		_shape(Rect2(x, 40, 3, 20), LIGHTNING),
		_shape(Rect2(x - 4, 58, 4, 3), LIGHTNING),
		_shape(Rect2(x - 6, 60, 3, 24), LIGHTNING),
	]
