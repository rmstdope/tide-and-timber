class_name Walk
extends RefCounted
## Movement rules for the man, free of nodes.

enum Facing { DOWN, UP, LEFT, RIGHT }   # also the row order of assets/man/man.png
const SPEED := 48.0                     # px per second: three 16 px tiles
const RUN_SPEED := 96.0                 # px/s: double walking pace
const WADE_SPEED := 24.0                # px/s: half walking pace, Shift or not
const PUFF_INTERVAL := 0.15             # s between sand puffs while running
const RIPPLE_INTERVAL := 0.3            # s between ripples while wading and moving

const _NAMES := ["down", "up", "left", "right"]

static func facing_name(facing: Facing) -> String:
	return _NAMES[facing]

## The Facing a name gives, or -1 when unknown.
static func facing_for_name(facing_name_: String) -> int:
	return _NAMES.find(facing_name_)

static func direction(left: bool, right: bool, up: bool, down: bool) -> Vector2:
	return Vector2(int(right) - int(left), int(down) - int(up)).normalized()

static func speed_for(running: bool, wading: bool) -> float:
	if wading:
		return WADE_SPEED
	return RUN_SPEED if running else SPEED

static func velocity(dir: Vector2, speed: float = SPEED) -> Vector2:
	return dir * speed

static func facing_for(dir: Vector2, previous: Facing) -> Facing:
	if dir.x < 0:
		return Facing.LEFT
	if dir.x > 0:
		return Facing.RIGHT
	if dir.y < 0:
		return Facing.UP
	if dir.y > 0:
		return Facing.DOWN
	return previous

static func facing_vector(facing: Facing) -> Vector2:
	return [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT][facing]

static func animation_for(facing: Facing, moving: bool, wading: bool = false) -> StringName:
	return StringName(("wade_" if wading else "") + ("walk_" if moving else "still_") + _NAMES[facing])

static func trail_for(moving: bool, running: bool, wading: bool) -> StringName:
	if not moving:
		return &""
	if wading:
		return &"ripple"
	return &"puff" if running else &""

static func trail_interval(kind: StringName) -> float:
	match kind:
		&"puff":
			return PUFF_INTERVAL
		&"ripple":
			return RIPPLE_INTERVAL
	return 0.0
