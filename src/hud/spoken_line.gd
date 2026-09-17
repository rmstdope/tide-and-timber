class_name SpokenLine
extends Control
## One of his lines. It keeps its Normal width while that fits on the screen at the current UI size.
## Otherwise it narrows to nearly the screen's width, wraps, and grows taller.
## Children, all optional: "Band" (ColorRect, resized to the whole control), "Text" (Label; when
## absent, this node itself must be the Label). Any other child (the dawn line's journal) keeps its offsets.

const SCREEN_WIDTH := 320.0
const SCREEN_MARGIN := 4.0          # on-screen art px kept clear at each side once a line narrows

@export var grows_up := true        # true: the bottom edge stays put; false: the vertical centre stays put

var _full_width := 0.0
var _full_height := 0.0
var _bottom := 0.0
var _centre_y := 0.0
var _text: Label
var _band: Control
var _text_left := 0.0

func _ready() -> void:
	_full_width = size.x
	_full_height = size.y
	_bottom = position.y + size.y
	_centre_y = position.y + size.y / 2.0
	_text = _find_text()
	_band = get_node_or_null(^"Band") as Control
	_text_left = 0.0 if _text == (self as Object) else _text.position.x
	Display.changed.connect(_refit)
	get_tree().root.size_changed.connect(_refit)
	_refit()

## Sets the words and fits at once (fits on _ready if called before it).
func say(text: String) -> void:
	_find_text().text = text
	if is_node_ready():
		_refit()

## The width at scale s: full_width while full_width * s fits the screen, else the screen less its margins.
static func width_at(full_width: float, s: float) -> float:
	return TextScale.fit_width(full_width, full_width, s)

## Lays the line out for scale s.
func fit(s: float) -> void:
	var w := width_at(_full_width, s)
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF if w == _full_width else TextServer.AUTOWRAP_WORD_SMART
	_text.update_minimum_size()     # else the unwrapped minimum width still clamps the narrower size
	var own := _text == (self as Object)
	if own:
		size.x = w
	else:
		_text.size.x = w - _text_left
	var lines := maxi(1, _text.get_line_count())
	var step := _text.get_line_height() + _text.get_theme_constant(&"line_spacing")
	var h := _full_height + (lines - 1) * step
	position = Vector2(roundf((SCREEN_WIDTH - w) / 2.0), _bottom - h if grows_up else roundf(_centre_y - h / 2.0))
	size = Vector2(w, h)
	if _band:
		_band.size = size
	if not own:
		_text.size = Vector2(w - _text_left, h)

func _refit() -> void:
	fit(UiScale.current(Display.prefs, get_tree().root))

func _find_text() -> Label:
	var child := get_node_or_null(^"Text") as Label
	return child if child else (self as Object) as Label
