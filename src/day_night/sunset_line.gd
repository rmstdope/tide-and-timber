class_name SunsetLine
extends RefCounted
## The fade of the 18:30 line, in real seconds, with no nodes.

const FADE_IN_SECONDS := 0.5
const HOLD_SECONDS := 4.0
const FADE_OUT_SECONDS := 0.5

var hold_seconds := HOLD_SECONDS
var _elapsed := -1.0   # -1 = not showing


func _init(hold := HOLD_SECONDS) -> void:
	hold_seconds = hold


func start() -> void:
	_elapsed = 0.0


func advance(real_seconds: float) -> void:
	if not is_showing():
		return
	_elapsed += real_seconds
	if _elapsed >= FADE_IN_SECONDS + hold_seconds + FADE_OUT_SECONDS:
		_elapsed = -1.0


func is_showing() -> bool:
	return _elapsed >= 0.0


func alpha() -> float:
	if not is_showing():
		return 0.0
	var a := 1.0
	if _elapsed < FADE_IN_SECONDS:
		a = _elapsed / FADE_IN_SECONDS
	elif _elapsed > FADE_IN_SECONDS + hold_seconds:
		a = 1.0 - (_elapsed - FADE_IN_SECONDS - hold_seconds) / FADE_OUT_SECONDS
	return clampf(a, 0.0, 1.0)
