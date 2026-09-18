class_name LooseFollow
extends RefCounted
## The loose camera's follow maths, free of nodes.

const DEAD_ZONE_HALF := Vector2(24, 20)   # he moves ±24 x, ±20 y from the centre before it follows
const CATCH_UP_RATE := 5.0                # per second, exponential
const SETTLE := 0.5                       # px of overflow closed at once, so it stops
const UNBOUNDED := Rect2(-1e7, -1e7, 2e7, 2e7)   # wider than any map; clamping to it changes nothing

static func step(centre: Vector2, target: Vector2, delta: float) -> Vector2:
	var offset := target - centre
	var overflow := offset - offset.clamp(-DEAD_ZONE_HALF, DEAD_ZONE_HALF)
	if overflow.length() <= SETTLE:
		return centre + overflow
	return centre + overflow * (1.0 - exp(-CATCH_UP_RATE * delta))

## The rectangle the centre may lie in, so that a view `view` px across, centred on it, never
## leaves `world`. Where `world` is narrower or shorter than the view, the centre is pinned to
## the middle of `world` in that dimension: half of it is shown rather than a drifting slice.
static func centre_bounds(world: Rect2, view: Vector2) -> Rect2:
	var half := view / 2.0
	var lo := world.position + half
	var hi := world.position + world.size - half
	if lo.x > hi.x:
		lo.x = world.position.x + world.size.x / 2.0
		hi.x = lo.x
	if lo.y > hi.y:
		lo.y = world.position.y + world.size.y / 2.0
		hi.y = lo.y
	return Rect2(lo, hi - lo)

## `centre` brought inside `bounds`.
static func clamp_centre(centre: Vector2, bounds: Rect2) -> Vector2:
	return centre.clamp(bounds.position, bounds.position + bounds.size)
