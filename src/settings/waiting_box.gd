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
const SCREEN := Vector2(320, 180)
const SIDE_PAD := 4.0                   # each side of the plank, outside the words
const TOP_PAD := 8.0                    # plank top to the first word row's top
const BOTTOM_PAD := 16.0                # the hold row's bottom to the plank bottom
const HOLD_GAP := 4.0                   # the last word row's bottom to the hold row's top
const LINE_STEP := 16.0                 # a word row's height at Text size Normal
const BASELINE_IN_ROW := 10.0           # a name/press row's top to its baseline
const HOLD_BASELINE_IN_ROW := 8.0
const RING_SIZE := 10.0

## The whole measured layout in page units; the host layer multiplies by the UI scale.
class Layout extends RefCounted:
	var rel := 1.0                      # the words' scale inside the box; 1.0 at Text size Normal
	var panel := Rect2()                # the plank, whole units, centred on (160, 90)
	var names := PackedStringArray()    # the action name, wrapped
	var presses := PackedStringArray()  # "Press a new key" / "Press a new button", wrapped
	var hold: Array = []                # 1 or 2 rows; each an Array of String and DeviceHints.Picture
	var step := 0.0                     # a word row's height
	var hold_h := 0.0                   # a hold row's height
	var pic_dy := 0.0                   # a hold row's top to the picture's and ring's top
	var ring := Vector2.ZERO            # the ring's top-left
	var fits := false

var lines := PackedStringArray()        # [action name, "Press a new key" / "Press a new button"]
var items: Array = []                   # [HOLD, Picture, TO_CANCEL]
var layout: Layout = null               # the measured layout drawn right now
var ring: SkipRing

func _ready() -> void:
	ring = SkipRing.new()
	ring.size = Vector2(10, 10)
	ring.mouse_filter = MOUSE_FILTER_IGNORE
	ring.visible = false
	add_child(ring)
	Display.changed.connect(_relayout)
	get_tree().root.size_changed.connect(_relayout)

## What to show; progress 0..1 fills the ring, which is hidden at 0.
func show_for(p_lines: PackedStringArray, p_items: Array, progress: float) -> void:
	lines = p_lines
	items = p_items
	_relayout()
	set_progress(progress)

## Re-measures the box for the current Text size, UI size and window, and moves the ring.
func _relayout() -> void:
	if lines.is_empty() or not is_inside_tree():
		return
	var root := get_tree().root
	var ui := UiScale.current(Display.prefs, root)
	layout = layout_at(lines, items, TextScale.relative(Display.prefs, root), ui,
			get_theme_default_font())
	ring.position = layout.ring
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
	if lines.is_empty() or layout == null:
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, SCREEN), DIM)
	draw_style_box(PLANK_STYLE, layout.panel)
	var y := layout.panel.position.y + TOP_PAD
	for line in layout.names:
		_centred(font, line, y + ceilf(BASELINE_IN_ROW * layout.rel), layout.rel)
		y += layout.step
	for line in layout.presses:
		_centred(font, line, y + ceilf(BASELINE_IN_ROW * layout.rel), layout.rel)
		y += layout.step
	y += HOLD_GAP
	for row: Array in layout.hold:
		var x := roundf(160.0 - _row_width(row, layout.rel, font) / 2.0)
		for i in row.size():
			if i > 0:
				x += GAP
			var item: Variant = row[i]
			if item is String:
				_grown(font, item as String,
					Vector2(x, y + ceilf(HOLD_BASELINE_IN_ROW * layout.rel)), layout.rel)
				x += ceilf(_word(item as String, font) * layout.rel)
			else:
				HintLine.draw_picture(self, item as DeviceHints.Picture, Vector2(x, y + layout.pic_dy))
				x += HintLine.picture_width(item as DeviceHints.Picture)
		y += layout.hold_h

## Draws one word at `at` (its baseline-left) grown by `rel`. The transform is reset at once, so
## nothing else - pictures, glyphs, the ring - is ever scaled by it.
func _grown(font: Font, text: String, at: Vector2, rel: float) -> void:
	draw_set_transform(at, 0.0, Vector2.ONE * rel)
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, HintLine.FONT_SIZE,
		ControlsPage.TEXT)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _centred(font: Font, text: String, baseline: float, rel: float) -> void:
	_grown(font, text, Vector2(roundf(160.0 - ceilf(_word(text, font) * rel) / 2.0), baseline), rel)
## A hold row's width in page units: its items at `rel`, one GAP between each adjacent pair. The
## ring is not part of it: the row is centred on its words and picture, and the ring follows.
static func _row_width(row: Array, rel: float, font: Font) -> float:
	var w := 0.0
	for i in row.size():
		if i > 0:
			w += GAP
		var item: Variant = row[i]
		if item is String:
			w += ceilf(_word(item as String, font) * rel)
		else:
			w += HintLine.picture_width(item as DeviceHints.Picture)
	return w

## The layout at a given words' scale `rel`, whether or not it fits.
static func layout_at(p_lines: PackedStringArray, p_items: Array, rel: float, ui: float,
		font: Font) -> Layout:
	var l := Layout.new()
	l.rel = rel
	var nw := ceilf(_word(p_lines[0], font) * rel)
	var pw := ceilf(_word(p_lines[1], font) * rel)
	var whole_hold: Array = [p_items[0], p_items[1], p_items[2]]
	var hw := _row_width(whole_hold, rel, font)
	# The hold row is centred on 160 and the ring hangs off its right end, so a whole hold line
	# wants the ring's room on one side of the centre: twice it, in a width centred on 160.
	var panel_w := TextScale.fit_width(PANEL.size.x,
			maxf(maxf(nw, pw), hw + 2.0 * (RING_GAP + RING_SIZE)) + 2.0 * SIDE_PAD, ui)
	var area := panel_w - 2.0 * SIDE_PAD
	l.names = ControlsPage.name_lines(p_lines[0], area / rel, font)
	l.presses = ControlsPage.name_lines(p_lines[1], area / rel, font)
	if hw <= area:
		l.hold = [whole_hold]
	else:
		l.hold = [[p_items[0], p_items[1]], [p_items[2]]]
	l.step = ceilf(LINE_STEP * rel)
	l.hold_h = maxf(l.step, float(HintLine.HEIGHT))
	l.pic_dy = floorf((l.step - LINE_STEP) / 2.0)
	var word_rows := float(l.names.size() + l.presses.size())
	var panel_h := TOP_PAD + word_rows * l.step + HOLD_GAP + l.hold.size() * l.hold_h + BOTTOM_PAD
	l.panel = Rect2(roundf(160.0 - panel_w / 2.0), roundf(90.0 - panel_h / 2.0), panel_w, panel_h)
	var last: Array = l.hold[l.hold.size() - 1]
	var row_w := _row_width(last, rel, font)
	var row_top := l.panel.position.y + TOP_PAD + word_rows * l.step + HOLD_GAP \
			+ (l.hold.size() - 1) * l.hold_h
	l.ring = Vector2(roundf(160.0 - row_w / 2.0) + row_w + RING_GAP, roundi(row_top + l.pic_dy - 0.5))
	l.fits = _fits(l, area, ui, font)
	return l

## The whole box is on screen, every row is inside the words area, and the ring is on the plank.
static func _fits(l: Layout, area: float, ui: float, font: Font) -> bool:
	if l.panel.size.y * ui > SCREEN.y - 2.0 * SpokenLine.SCREEN_MARGIN:
		return false
	for line in l.names:
		if ceilf(_word(line, font) * l.rel) > area:
			return false
	for line in l.presses:
		if ceilf(_word(line, font) * l.rel) > area:
			return false
	for row: Array in l.hold:
		if _row_width(row, l.rel, font) > area:
			return false
	return l.ring.x + RING_SIZE <= l.panel.end.x
