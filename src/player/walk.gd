class_name Walk
extends RefCounted
## Movement rules for the man, free of nodes.

enum Facing { DOWN, UP, LEFT, RIGHT }   # also the row order of every sheet under assets/man/
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

## The unit walking direction for an input vector: snapped to the nearest of eight, or ZERO.
static func direction(input: Vector2) -> Vector2:
	if input == Vector2.ZERO:
		return Vector2.ZERO
	var a := snappedf(input.angle(), PI / 4)
	# Rounded components keep the cardinals exact, so walking straight up never faces him sideways.
	return Vector2(roundf(cos(a)), roundf(sin(a))).normalized()

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

static func animation_for(facing: Facing, moving: bool, wading: bool = false, running: bool = false) -> StringName:
	# Wading is one pace whether Shift is held, so there is no wading run to show.
	if moving and running and not wading:
		return StringName("run_" + _NAMES[facing])
	return StringName(("wade_" if wading else "") + ("walk_" if moving else "still_") + _NAMES[facing])

## The gathering move's animation for how he stands now.
static func collect_animation_for(facing: Facing, wading: bool = false) -> StringName:
	return StringName(("wade_" if wading else "") + "collect_" + _NAMES[facing])

## The fall's animation for the way he was facing when he went down; the waking plays it backwards.
static func fall_animation_for(facing: Facing) -> StringName:
	return StringName("death_" + _NAMES[facing])

## How fast his animation runs: half pace in the water, its own pace everywhere else.
static func animation_scale(wading: bool) -> float:
	return WADE_SPEED / SPEED if wading else 1.0

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
