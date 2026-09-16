class_name Reach
extends RefCounted
## Which usable thing the man acts on: pure, free of nodes.

const DISTANCE := 20.0        # px from his feet (his origin) to a usable's origin
const FACING_DOT := 0.7071    # within 45 degrees of his facing counts as faced
const ON_SPOT := 2.0          # a usable this close counts as faced whatever his facing

## The index of the closest faced spot in reach, else the closest in reach, else -1.
static func pick(from: Vector2, facing: Vector2, spots: Array[Vector2]) -> int:
	var best_faced := -1
	var best_any := -1
	for i in spots.size():
		var d := from.distance_to(spots[i])
		if d > DISTANCE:
			continue
		if best_any < 0 or d < from.distance_to(spots[best_any]):
			best_any = i
		var faced := d <= ON_SPOT or (spots[i] - from).normalized().dot(facing) >= FACING_DOT
		if faced and (best_faced < 0 or d < from.distance_to(spots[best_faced])):
			best_faced = i
	return best_faced if best_faced >= 0 else best_any
