class_name DebugReadout
extends Control
## The readout box top-right while DebugSwitches.readout is on.

const BOX_X := 236.0
const BOX_Y := 4.0
const BOX_W := 80.0
const LINE_X := 240.0
const FIRST_LINE_Y := 7.0
const LINE_STEP := 8.0
const BOX := Color(0, 0, 0, 0.6)
const TEXT := Color("#9fe89f")

var day_night: DayNight   # null in the story
var player: Player        # null in the story

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(320, 180)
	visible = DebugSwitches.readout

func _process(_delta: float) -> void:
	visible = DebugSwitches.readout
	if visible:
		queue_redraw()

func _draw() -> void:
	var ls := lines()
	draw_rect(box_rect(ls.size()), BOX)
	for i in ls.size():
		Glyphs.draw(self, ls[i], Vector2(LINE_X, FIRST_LINE_Y + i * LINE_STEP), TEXT)

## The lines for now, from whatever sources this scene has.
func lines() -> Array[String]:
	var clock: GameClock = day_night.clock if day_night else null
	var scale := day_night.time_scale if day_night else 1.0
	var feet: Variant = player.global_position if player else null
	return DebugShow.readout_lines(Engine.get_frames_per_second(), clock, scale, feet)

## The box behind n lines.
static func box_rect(n: int) -> Rect2:
	return Rect2(BOX_X, BOX_Y, BOX_W, LINE_STEP * n + 2)
