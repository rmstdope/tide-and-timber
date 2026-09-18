class_name SpokenLine
extends Control
## One of his lines. The dark band is as wide as the words plus a margin each side, centred on the
## picture. Once that no longer fits at the current UI size it narrows to nearly the screen's width,
## wraps, and grows taller.
## Children, all optional: "Band" (ColorRect, resized to the whole control), "Text" (Label; when
## absent, this node itself must be the Label). Any other child (the dawn line's journal) keeps its offsets.

const SCREEN_MARGIN := 4.0          # on-screen art px kept clear at each side once a line narrows
const BAND_MARGIN := 8.0            # art px of band kept each side of the words

@export var grows_up := true        # true: the bottom edge stays put; false: the vertical centre stays put

var _full_height := 0.0
var _bottom := 0.0
var _centre_y := 0.0
var _text: Label
var _band: Control
var _text_left := 0.0

func _ready() -> void:
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

## The band a line wants, unclamped: the words plus BAND_MARGIN each side, and never less than
## `text_left` each side, so a leading child (the dawn line's journal) keeps its room and the
## words stay centred in the band.
static func wanted_width(words_width: float, text_left: float) -> float:
	return words_width + 2.0 * maxf(text_left, BAND_MARGIN)

## Lays the line out for UI scale s, with the words at `rel` times that (1.0: Text size Normal).
func fit(s: float, rel: float = 1.0) -> void:
	var own := _text == (self as Object)
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_text.scale = Vector2.ONE
	_text.update_minimum_size()     # else the unwrapped minimum width still clamps the narrower size
	var words := ceilf(_text.get_minimum_size().x * rel)
	var inset := 0.0 if own else maxf(_text_left, BAND_MARGIN)
	var want := wanted_width(words, _text_left)
	var w := TextScale.fit_width(want, want, s)
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF if w == want else TextServer.AUTOWRAP_WORD_SMART
	_text.scale = Vector2.ONE * rel
	_text.size.x = (w - 2.0 * inset) / rel
	_text.update_minimum_size()
	var lines := maxi(1, _text.get_line_count())
	var step := _text.get_line_height() + _text.get_theme_constant(&"line_spacing")
	var h := _full_height + (lines - 1) * step + lines * (ceilf(step * rel) - step)
	position = Vector2(roundf((Screen.WIDTH - w) / 2.0), _bottom - h if grows_up else roundf(_centre_y - h / 2.0))
	if own:
		size = Vector2(w, h) / rel
	else:
		size = Vector2(w, h)
		if _band:
			_band.size = size
		_text.position.x = inset
		_text.size = Vector2((w - 2.0 * inset) / rel, h / rel)

func _refit() -> void:
	fit(UiScale.current(Display.prefs, get_tree().root), TextScale.relative(Display.prefs, get_tree().root))

func _find_text() -> Label:
	var child := get_node_or_null(^"Text") as Label
	return child if child else (self as Object) as Label
