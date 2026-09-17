class_name DebugItems
extends RefCounted
## The Debug panel's Items page: one row per Item.Kind with its count, then Empty his bag.

const MAX_COUNT := 99
const EMPTY_BAG := "Empty his bag"

## Appends to menu's ITEMS page one row per Item.Kind in Kind order, then the Empty his bag row.
static func add_rows(menu: DebugMenu, inventory: Inventory) -> void:
	for kind: Item.Kind in Item.Kind.values():
		menu.add_row(DebugMenu.Page.ITEMS, item_row(inventory, kind))
	menu.add_row(DebugMenu.Page.ITEMS, empty_bag_row(inventory))

## The row for one kind: its name, the count carried read live, and Left/Right stepping it within 0..MAX_COUNT.
static func item_row(inventory: Inventory, kind: Item.Kind) -> DebugRow:
	return DebugRow.new(Item.name_of(kind),
		func() -> String: return str(inventory.count(kind)),
		func(delta: int) -> void: inventory.set_count(kind, clampi(inventory.count(kind) + delta, 0, MAX_COUNT)))

## The last row: no value, no step; Select empties the bag.
static func empty_bag_row(inventory: Inventory) -> DebugRow:
	return DebugRow.new(EMPTY_BAG, Callable(), Callable(), func() -> DebugRow.Result:
		inventory.clear()
		return DebugRow.Result.DONE)
