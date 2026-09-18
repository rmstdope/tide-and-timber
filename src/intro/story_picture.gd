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
	var full := Rect2(Vector2.ZERO, Screen.SIZE)
	match index:
		0:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(false))
			out.append_array(_waves(240, false))
			out.append_array(_ship(240, 206, 0.0, false))
			out.append_array(_rain(160))
		1:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(false))
			out.append_array(_waves(220, true))
			out.append_array(_ship(240, 184, -14.0, false))
			out.append_array(_rain(480))
			out.append_array(_bolt(460))
		2:
			out.append(_shape(full, SKY))
			out.append_array(_clouds(true))
			out.append_array(_waves(200, true))
			out.append_array(_ship(260, 170, 35.0, true))
			out.append_array(_rain(560))
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
		_shape(Rect2(0, 0, Screen.WIDTH, 80), CLOUD_HI if light else CLOUD),
		_shape(Rect2(40, 76, 90, 10), CLOUD),
		_shape(Rect2(320, 74, 120, 12), CLOUD),
		_shape(Rect2(120, 84, 40, 6), CLOUD),
		_shape(Rect2(430, 78, 110, 10), CLOUD),
		_shape(Rect2(250, 86, 50, 6), CLOUD),
	]

static func _waves(top: int, big: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		_shape(Rect2(0, top, Screen.WIDTH, Screen.HEIGHT - top), SEA),
		_shape(Rect2(0, top + 60, Screen.WIDTH, Screen.HEIGHT), SEA_DEEP),
	]
	var h := 10 if big else 5
	var x := 0
	while x < Screen.WIDTH:
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
		var x := floori(v / 233280.0 * (Screen.WIDTH + 10.0))
		v = (v * 9301 + 49297) % 233280
		var y := floori(v / 233280.0 * Screen.HEIGHT)
		out.append(_shape(Rect2(x, y, 1, 5), RAIN))
	return out

static func _bolt(x: int) -> Array[Dictionary]:
	return [
		_shape(Rect2(x, 80, 3, 20), LIGHTNING),
		_shape(Rect2(x - 4, 98, 4, 3), LIGHTNING),
		_shape(Rect2(x - 6, 100, 3, 24), LIGHTNING),
	]
