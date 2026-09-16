class_name MorningCard
extends RefCounted
## The morning card's fade, in real seconds: 0.5 in, 3.0 held, 0.5 out; about 4 seconds in all.

const FADE_IN_SECONDS := 0.5
const HOLD_SECONDS := 3.0
const FADE_OUT_SECONDS := 0.5

var _elapsed := -1.0   # -1 = not showing

func start() -> void:
	_elapsed = 0.0

func advance(real_seconds: float) -> void:
	if not is_showing():
		return
	_elapsed += real_seconds
	if _elapsed >= FADE_IN_SECONDS + HOLD_SECONDS + FADE_OUT_SECONDS:
		_elapsed = -1.0

func is_showing() -> bool:
	return _elapsed >= 0.0

func alpha() -> float:
	if not is_showing():
		return 0.0
	var a := 1.0
	if _elapsed < FADE_IN_SECONDS:
		a = _elapsed / FADE_IN_SECONDS
	elif _elapsed > FADE_IN_SECONDS + HOLD_SECONDS:
		a = 1.0 - (_elapsed - FADE_IN_SECONDS - HOLD_SECONDS) / FADE_OUT_SECONDS
	return clampf(a, 0.0, 1.0)
