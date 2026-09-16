class_name Walk
extends RefCounted
## Movement rules for the man, free of nodes.

enum Facing { DOWN, UP, LEFT, RIGHT }   # also the row order of assets/man/man.png
const SPEED := 48.0                     # px per second: three 16 px tiles

const _NAMES := ["down", "up", "left", "right"]

static func direction(left: bool, right: bool, up: bool, down: bool) -> Vector2:
	return Vector2(int(right) - int(left), int(down) - int(up)).normalized()

static func velocity(dir: Vector2) -> Vector2:
	return dir * SPEED

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

static func animation_for(facing: Facing, moving: bool) -> StringName:
	return StringName(("walk_" if moving else "still_") + _NAMES[facing])
