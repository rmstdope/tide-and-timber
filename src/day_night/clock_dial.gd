class_name ClockDial
extends Control
## Draws the dial's arc and the sun or moon on it. Holds no time of its own.

const ARC_CENTER := Vector2(32, 24)
const ARC_RADIUS := 14.0
const ARC_SAMPLES := 64
const ARC_COLOR := Color8(246, 227, 176)    # #f6e3b0
const SUN_COLOR := Color8(255, 210, 74)     # #ffd24a
const MOON_COLOR := Color8(232, 236, 255)   # #e8ecff
const SUN_PIXELS := [
	"...#...",
	".#####.",
	".#####.",
	"#######",
	".#####.",
	".#####.",
	"...#...",
]
const MOON_PIXELS := [
	"..###..",
	".##....",
	"##.....",
	"##.....",
	"##.....",
	".##....",
	"..###..",
]

var fraction := 0.0    # set by DayNight
var is_day := true     # set by DayNight


static func marker_position(frac: float) -> Vector2i:
	var a := PI * (1.0 - frac)
	return Vector2i(roundi(ARC_CENTER.x + ARC_RADIUS * cos(a)), roundi(ARC_CENTER.y - ARC_RADIUS * sin(a)))


static func marker_pixels(day: bool) -> Array:
	return SUN_PIXELS if day else MOON_PIXELS


func _draw() -> void:
	for i in ARC_SAMPLES + 1:
		draw_rect(Rect2(marker_position(float(i) / ARC_SAMPLES), Vector2.ONE), ARC_COLOR)
	var at := marker_position(fraction)
	var colour := SUN_COLOR if is_day else MOON_COLOR
	var pixels := marker_pixels(is_day)
	for row in pixels.size():
		var line: String = pixels[row]
		for col in line.length():
			if line[col] == "#":
				draw_rect(Rect2(at + Vector2i(col - 3, row - 3), Vector2.ONE), colour)
