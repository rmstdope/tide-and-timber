class_name NightLoss
extends RefCounted
## What the night takes (half of each kind, rounded down) and the morning card's words.

const HEADING := "The night took:"
const NOTHING := "I made it through."

## One entry per kind that loses at least one, in bar (slot) order: Vector2i(kind, amount).
static func losses(inventory: Inventory) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in Inventory.SLOT_COUNT:
		if inventory.slot_kind(i) == Inventory.EMPTY:
			continue
		@warning_ignore("integer_division")
		var n := inventory.slot_count(i) / 2
		if n > 0:
			out.append(Vector2i(inventory.slot_kind(i), n))
	return out

static func apply(inventory: Inventory, taken: Array[Vector2i]) -> void:
	for e in taken:
		inventory.remove(e.x as Item.Kind, e.y)

static func card_lines(day: int, taken: Array[Vector2i]) -> Array[String]:
	var out: Array[String] = ["DAY %d" % day]
	if taken.is_empty():
		out.append(NOTHING)
		return out
	out.append(HEADING)
	for e in taken:
		out.append("%d %s" % [e.y, Item.name_of(e.x as Item.Kind)])
	return out
