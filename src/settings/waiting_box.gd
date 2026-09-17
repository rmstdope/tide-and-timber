class_name WaitingBox
extends Control
## The waiting box: dims the page and draws the action, "Press a new …", and "Hold [Esc] to cancel"
## with a ring that fills while the cancel key is held. It has no rules; ControlsPage feeds it.

const DIM := Color(0, 0, 0, 0.35)       # pause.tscn QuitBox/Dim
const PANEL := Rect2(60, 52, 200, 76)
const NAME_BASELINE := 70.0
const PRESS_BASELINE := 86.0
const HOLD_TOP := 96.0                  # the picture's top; the words' baseline is HOLD_TOP + 8
const GAP := 3                          # word to picture and picture to word
const RING_GAP := 4                     # the line's end to the ring
const HOLD := "Hold"
const TO_CANCEL := "to cancel"
const PLANK_STYLE := preload("res://src/title/plank.tres")

var lines := PackedStringArray()        # [action name, "Press a new key" / "Press a new button"]
var items: Array = []                   # [HOLD, Picture, TO_CANCEL]
var ring: SkipRing

func _ready() -> void:
	ring = SkipRing.new()
	ring.size = Vector2(10, 10)
	ring.mouse_filter = MOUSE_FILTER_IGNORE
	ring.visible = false
	add_child(ring)

## What to show; progress 0..1 fills the ring, which is hidden at 0.
func show_for(p_lines: PackedStringArray, p_items: Array, progress: float) -> void:
	lines = p_lines
	items = p_items
	var font := get_theme_default_font()
	ring.position = Vector2(roundi(160 + hold_width(items, font) / 2.0 + RING_GAP), roundi(HOLD_TOP - 0.5))
	set_progress(progress)
	queue_redraw()

## Only the ring changed (every frame while held).
func set_progress(progress: float) -> void:
	ring.progress = progress
	ring.visible = progress > 0.0

## [HOLD, the Esc cap or the pad's B button picture in `kind`, TO_CANCEL].
static func hold_items(device: Controls.Device, kind: DeviceTracker.Kind) -> Array:
	if device == Controls.Device.KEYBOARD:
		return [HOLD, DeviceHints.Picture.new(DeviceHints.Shape.KEY, "Esc", DeviceHints.CAP_FACE, DeviceHints.CAP_INK),
			TO_CANCEL]
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	return [HOLD, DeviceHints.picture_for(b, kind), TO_CANCEL]

## The hold line's width at font size 8: words, two GAPs, the picture.
static func hold_width(p_items: Array, font: Font) -> int:
	return _word(HOLD, font) + GAP + HintLine.picture_width(p_items[1]) + GAP + _word(TO_CANCEL, font)

static func _word(s: String, font: Font) -> int:
	return ceili(font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE).x)

func _draw() -> void:
	if lines.is_empty():
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(0, 0, 320, 180), DIM)
	draw_style_box(PLANK_STYLE, PANEL)
	_centred(font, lines[0], NAME_BASELINE)
	_centred(font, lines[1], PRESS_BASELINE)
	var x := roundi(160 - hold_width(items, font) / 2.0)
	draw_string(font, Vector2(x, HOLD_TOP + 8), HOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE, ControlsPage.TEXT)
	x += _word(HOLD, font) + GAP
	HintLine.draw_picture(self, items[1], Vector2(x, HOLD_TOP))
	x += HintLine.picture_width(items[1]) + GAP
	draw_string(font, Vector2(x, HOLD_TOP + 8), TO_CANCEL, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE, ControlsPage.TEXT)

func _centred(font: Font, text: String, baseline: float) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE).x
	draw_string(font, Vector2(roundf(160 - w / 2.0), baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE,
		ControlsPage.TEXT)
