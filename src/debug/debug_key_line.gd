class_name DebugKeyLine
extends Control
## The short line top-centre that confirms F1-F4, and the reader of those keys.

const BOX := Rect2(110, 6, 100, 14)
const BOX_COLOUR := Color(0, 0, 0, 0.6)
const TEXT := Color("#9fe89f")
const TEXT_Y := 10.0
const SECONDS := 1.0

var day_night: DayNight   # null in the story
var text := ""            # the line showing, "" when none
var _left := 0.0          # seconds the line still shows

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	size = Vector2(320, 180)
	visible = false

## Shows `line` for SECONDS from now, replacing any line showing.
func show_line(line: String) -> void:
	text = line
	_left = SECONDS
	visible = true
	queue_redraw()

## Counts down `seconds`; at or below zero the line is gone.
func advance(seconds: float) -> void:
	if text == "":
		return
	_left -= seconds
	if _left <= 0.0:
		text = ""
		visible = false

## Top-left of the text, centred in BOX.
static func text_at(line: String) -> Vector2:
	return Vector2(roundi(BOX.get_center().x - Glyphs.width(line) / 2.0), TEXT_Y)

# Real time: the layer always processes and nothing changes Engine.time_scale.
func _process(delta: float) -> void:
	advance(delta)

# _input so nothing marks the key handled first; never handles it, so a bound action still fires.
func _input(event: InputEvent) -> void:
	var shortcut := DebugShortcut.of(event)
	if shortcut == DebugShortcut.Name.NONE or get_tree().paused:
		return
	var line := DebugKeys.press(shortcut, day_night)
	if line != "":
		show_line(line)

func _draw() -> void:
	if text == "":
		return
	draw_rect(BOX, BOX_COLOUR)
	Glyphs.draw(self, text, text_at(text), TEXT)
