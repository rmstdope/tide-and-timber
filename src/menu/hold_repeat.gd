class_name HoldRepeat
extends RefCounted
## Timing of a held menu direction: nothing for DELAY, then one step every INTERVAL. No nodes, no input.

const DELAY := 0.4
const INTERVAL := 0.1

var direction := 0       # -1 or 1 while held, 0 when not
var _held := 0.0         # seconds since press

## Starts timing a hold in `dir` (-1 or 1) from zero.
func press(dir: int) -> void:
	direction = dir
	_held = 0.0

## Stops: direction 0.
func release() -> void:
	direction = 0
	_held = 0.0

## Adds real seconds held; returns how many repeat steps fell due in them (0 when not held).
func advance(seconds: float) -> int:
	if direction == 0:
		return 0
	var before := _fired(_held)
	_held += seconds
	return _fired(_held) - before

static func _fired(t: float) -> int:
	# a hair of tolerance so 0.4 s made of 0.39 + 0.01 counts as reached
	if t < DELAY - 1e-6:
		return 0
	return 1 + int(floor((t - DELAY) / INTERVAL + 1e-6))
