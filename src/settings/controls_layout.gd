class_name ControlsLayout
extends RefCounted
## Where the Controls page draws its words, tabs, rows and slots at one UI scale and one Text size, in page units.
## Words grow by rel about their baseline-left; tabs, rows and the list grow around them in whole units.

const FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const ASCENT := 8.0          # a line of words' height above its baseline at Normal
const PICTURE_GAP := 4.0     # between a word and a button picture on a line under the list
const TAB_GAP := 4.0         # between the two tabs, across or down
const STACKED_UI := 2.0      # the UI scale ControlsPage's static geometry answers for when stacked

var stacked: bool
var rel: float
var ui: float
var grow: float              # what each line of words adds to a height
var heading_baseline: float
var list_x: float
var list_w: float
var list_top: float
var row_h: float
var slot_top: float          # a row's top to its slots' top
var no_key_lines: int        # lines kept for the no-key line: the most any action's line takes
var fixed_lines: int         # lines kept under it for the fixed lines: the most either tab's take
var _tabs: Array[Rect2] = []
var _names := {}             # name String -> PackedStringArray, for every action name and both Reset names

## True when the rows, with the screen margins, do not fit across at UI scale p_ui with words grown by p_rel.
static func stacks(p_ui: float, p_rel: float) -> bool:
	if (ControlsPage.LIST_W + 2.0 * ControlsPage.SCREEN_MARGIN) * p_ui > 320.0:
		return true
	var action := 0.0
	for a: int in Controls.Action.values():
		action = maxf(action, width(Controls.NAMES[a]))
	var reset := 0.0
	for name: String in ControlsPage.RESET_NAMES:
		reset = maxf(reset, width(name))
	if ControlsPage.NAME_X + ceilf(action * p_rel) > ControlsPage.SLOT_XS[0]:
		return true
	return ControlsPage.NAME_X + ceilf(reset * p_rel) > ControlsPage.LIST_X + ControlsPage.LIST_W

## A word or line's width at FONT_SIZE, unscaled.
static func width(text: String) -> float:
	return FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ControlsPage.FONT_SIZE).x

## One item's width in page units: a word grown by p_rel, or a picture at its UI-size width.
static func item_width(item: Variant, p_rel: float) -> float:
	if item is DeviceHints.Picture:
		return float(HintLine.picture_width(item))
	return ceilf(width(item as String) * p_rel)

## The gap between two neighbouring items: a grown space between two words, else PICTURE_GAP.
static func gap(before: Variant, after: Variant, p_rel: float) -> float:
	if before is String and after is String:
		return ceilf(width(" ") * p_rel)
	return PICTURE_GAP

## A line's width: its items' widths plus the gaps between them.
static func line_width(line: Array, p_rel: float) -> float:
	var total := 0.0
	for i in line.size():
		if i > 0:
			total += gap(line[i - 1], line[i], p_rel)
		total += item_width(line[i], p_rel)
	return total

## Items broken greedily into lines no wider than max_w; an item wider than max_w stays whole on its own line.
static func flow(items: Array, max_w: float, p_rel: float) -> Array:
	var lines := []
	var line := []
	var w := 0.0
	for item: Variant in items:
		var add := item_width(item, p_rel)
		if not line.is_empty():
			add += gap(line.back(), item, p_rel)
		if not line.is_empty() and w + add > max_w:
			lines.append(line)
			line = [item]
			w = item_width(item, p_rel)
		else:
			line.append(item)
			w += add
	lines.append(line)
	return lines

## One line of words, split at spaces.
static func word_lines(text: String) -> Array:
	return [Array(text.split(" "))]

## Today's two keyboard lines, each split at spaces.
static func keyboard_lines() -> Array:
	var lines := []
	for text: String in ControlsPage.KEYBOARD_FIXED:
		lines.append(Array(text.split(" ")))
	return lines

## Today's single controller line: words, the A picture, "and", the B picture.
static func controller_lines(a: DeviceHints.Picture, b: DeviceHints.Picture) -> Array:
	var line := Array(ControlsPage.CONTROLLER_FIXED_WORDS[0].split(" "))
	line.append(a)
	line.append_array(Array(ControlsPage.CONTROLLER_FIXED_WORDS[1].split(" ")))
	line.append(b)
	return [line]

static func make(p_stacked: bool, p_rel: float, p_ui: float) -> ControlsLayout:
	var l := ControlsLayout.new()
	l.stacked = p_stacked
	l.rel = p_rel
	l.ui = p_ui
	l.grow = ceilf(ASCENT * p_rel) - ASCENT
	l.heading_baseline = ControlsPage.HEADING_BASELINE + l.grow
	l._make_tabs()
	if p_stacked:
		l._make_stacked_rows()
	else:
		l._make_side_by_side_rows()
	l._count_lines()
	return l

func _make_tabs() -> void:
	var pad := 4.0 if stacked else 8.0
	var h := ControlsPage.ROW_H + grow
	var top := 14.0 + grow
	var w0 := pad + ceilf(width(ControlsPage.TAB_NAMES[0]) * rel)
	var w1 := pad + ceilf(width(ControlsPage.TAB_NAMES[1]) * rel)
	# Equality is meant: stacked at Text Normal and UI 2x the sum is exactly 320, which keeps today's stacked tabs side by side (controls_layout_test.gd::test_stacked_rows_at_text_normal_are_todays).
	if (w0 + TAB_GAP + w1 + 2.0 * ControlsPage.SCREEN_MARGIN) * ui <= 320.0:
		var x0 := roundf(160.0 - (w0 + TAB_GAP + w1) / 2.0)
		_tabs = [Rect2(x0, top, w0, h), Rect2(x0 + w0 + TAB_GAP, top, w1, h)]
	else:
		var a := TextScale.fit_width(w0, w0, ui)
		var b := TextScale.fit_width(w1, w1, ui)
		_tabs = [Rect2(roundf(160.0 - a / 2.0), top, a, h),
			Rect2(roundf(160.0 - b / 2.0), top + h + TAB_GAP, b, h)]
	list_top = _tabs[1].end.y + 3.0

func _make_side_by_side_rows() -> void:
	list_x = ControlsPage.LIST_X
	list_w = ControlsPage.LIST_W
	row_h = ControlsPage.ROW_H + grow
	slot_top = 1.0 + floorf(grow / 2.0)
	for name: String in _every_name():
		_names[name] = PackedStringArray([name])

func _make_stacked_rows() -> void:
	var normal := {}
	var widest := 0.0
	for name: String in _every_name():
		normal[name] = ControlsPage.name_lines(name, ControlsPage.NAME_WRAP_W, FONT)
		for line: String in normal[name]:
			widest = maxf(widest, width(line))
	var inset := ControlsPage.LIST_W_STACKED - ControlsPage.NAME_WRAP_W
	list_w = TextScale.fit_width(ControlsPage.LIST_W_STACKED, ceilf(widest * rel) + inset, ui)
	list_x = roundf((320.0 - list_w) / 2.0)
	var wrap := list_w - inset
	for name: String in _every_name():
		var fits := true
		for line: String in normal[name]:
			if ceilf(width(line) * rel) > wrap:
				fits = false
		_names[name] = normal[name] if fits else ControlsPage.name_lines(name, wrap / rel, FONT)
	var n_action := 1
	for a: int in Controls.Action.values():
		n_action = maxi(n_action, (_names[Controls.NAMES[a]] as PackedStringArray).size())
	var n_reset := 1
	for name: String in ControlsPage.RESET_NAMES:
		n_reset = maxi(n_reset, (_names[name] as PackedStringArray).size())
	row_h = maxf(_block(n_action) + ControlsPage.ROW_H, _block(n_reset) + 1.0)
	slot_top = row_h - ControlsPage.ROW_H

func _block(n: int) -> float:
	return ControlsPage.ROW_H + grow + (n - 1) * (ControlsPage.NAME_LINE_STEP + grow)

func _every_name() -> Array:
	var names := []
	for a: int in Controls.Action.values():
		names.append(Controls.NAMES[a])
	names.append_array(ControlsPage.RESET_NAMES)
	return names

func _count_lines() -> void:
	no_key_lines = 1
	for a: int in Controls.Action.values():
		var text: String = ControlsMenu.HAS_NO_KEY % Controls.NAMES[a]
		no_key_lines = maxi(no_key_lines, fit_lines(word_lines(text)).size())
	var kind := DeviceTracker.Kind.XBOX
	var pa := DeviceHints.picture_for(ControlsPage.pad_button(JOY_BUTTON_A), kind)
	var pb := DeviceHints.picture_for(ControlsPage.pad_button(JOY_BUTTON_B), kind)
	fixed_lines = maxi(fit_lines(keyboard_lines()).size(), fit_lines(controller_lines(pa, pb)).size())

func tab_rect(i: int) -> Rect2:
	return _tabs[i]

func tab_baseline(i: int) -> float:
	return _tabs[i].position.y + 9.0 + grow

func tab_count() -> int:
	return _tabs.size()

func row_rect(r: int) -> Rect2:
	return Rect2(list_x, list_top + r * row_h, list_w, row_h)

func slot_rect(r: int, s: int) -> Rect2:
	var xs: Array = ControlsPage.SLOT_XS_STACKED if stacked else ControlsPage.SLOT_XS
	return Rect2(xs[s], list_top + r * row_h + slot_top, ControlsPage.SLOT_W, ControlsPage.ROW_H - 2)

## Baseline-left of row r's name's first line.
func name_origin(r: int) -> Vector2:
	var x := list_x + 4.0 if stacked else ControlsPage.NAME_X
	return Vector2(x, list_top + r * row_h + 9.0 + grow)

## Baseline to baseline when a name wraps.
func name_step() -> float:
	return ControlsPage.NAME_LINE_STEP + grow

func name_lines(r: int, device: Controls.Device) -> PackedStringArray:
	var name: String = ControlsPage.RESET_NAMES[device] if r == ControlsMenu.RESET_ROW \
			else Controls.NAMES[r]
	return _names[name]

## Where a name's line starts: the list's inset, or centred on the page when it is wider than the list.
func name_x(line: String) -> float:
	var w := ceilf(width(line) * rel)
	if stacked and w > list_w - 8.0:
		return roundf(160.0 - w / 2.0)
	return name_origin(0).x

## What a point on the page hits: Vector2i(row, slot), slot -1 on the Reset row; Vector2i(-1, -1) for nothing.
func hit(point: Vector2, device: Controls.Device) -> Vector2i:
	for r in ControlsMenu.ROWS:
		if not row_rect(r).has_point(point):
			continue
		if r == ControlsMenu.RESET_ROW:
			return Vector2i(r, -1)
		for s in Controls.slot_count(device):
			if slot_rect(r, s).has_point(point):
				return Vector2i(r, s)
		return Vector2i(-1, -1)   # the name part of an action row hits nothing
	return Vector2i(-1, -1)

## The tab under a point, or -1.
func tab_at(point: Vector2) -> int:
	for i in _tabs.size():
		if _tabs[i].has_point(point):
			return i
	return -1

## A block of lines under the list: today's lines while the grown words fit, else re-broken at spaces.
func fit_lines(lines: Array) -> Array:
	var normal_w := 0.0
	var grown_w := 0.0
	for line: Array in lines:
		normal_w = maxf(normal_w, line_width(line, 1.0))
		grown_w = maxf(grown_w, line_width(line, rel))
	var w := TextScale.fit_width(normal_w, grown_w, ui)
	if grown_w <= w:
		return lines
	var items := []
	for line: Array in lines:
		items.append_array(line)
	return flow(items, w, rel)

## Baseline to baseline for the lines under the list.
func line_step() -> float:
	return 9.0 + grow

func no_key_baseline() -> float:
	return list_top + ControlsMenu.ROWS * row_h + 10.0 + grow

func fixed_baseline() -> float:
	return no_key_baseline() + (no_key_lines - 1) * line_step() + 10.0 + grow

## The last kept fixed line's baseline: the bottom of the scrolled content.
func content_bottom() -> float:
	return fixed_baseline() + (fixed_lines - 1) * line_step()

## Row r's item (top, bottom) in content units (0 at ControlsPage.CONTENT_TOP). The first row reaches up to
## include the heading and tabs; the Reset row reaches down to include the lines under the list.
func row_extent(r: int) -> Vector2:
	var rect := row_rect(r)
	return ScrollWindow.stretch_ends(
			Vector2(rect.position.y - ControlsPage.CONTENT_TOP, rect.end.y - ControlsPage.CONTENT_TOP),
			content_bottom() - ControlsPage.CONTENT_TOP, r == 0, r == ControlsMenu.RESET_ROW)
