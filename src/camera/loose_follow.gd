class_name LooseFollow
extends RefCounted
## The loose camera's follow maths, free of nodes.

const DEAD_ZONE_HALF := Vector2(24, 20)   # he moves ±24 x, ±20 y from the centre before it follows
const CATCH_UP_RATE := 5.0                # per second, exponential
const SETTLE := 0.5                       # px of overflow closed at once, so it stops

static func step(centre: Vector2, target: Vector2, delta: float) -> Vector2:
	var offset := target - centre
	var overflow := offset - offset.clamp(-DEAD_ZONE_HALF, DEAD_ZONE_HALF)
	if overflow.length() <= SETTLE:
		return centre + overflow
	return centre + overflow * (1.0 - exp(-CATCH_UP_RATE * delta))
