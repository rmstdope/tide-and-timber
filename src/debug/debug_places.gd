class_name DebugPlaces
extends RefCounted
## The Debug panel's Place page: Walk through things, then the named places he can be put.

enum Place { WOKE, WRECK, BEACH, SPRING, CAMP }

const WALK_THROUGH := "Walk through things"
const ON := "On"
const OFF := "Off"
const NAMES := ["Where he woke", "Wreck", "Beach", "Spring", "Camp"]   # index = Place
const WRECK_CELL := Vector2i(92, 17)    # the last shallows row straight out from Waking.WAKE_CELL; no wreck is on the beach yet
const SPRING_CELL := Vector2i(96, 10)   # the sand just below BeachLayout.springs()[0], facing it
const CAMP_CELL := Vector2i(86, 10)     # open sand; a lean-to built facing down from here fits (cells 85..87 x 11..12)

## The cell he is put on for `place`. has_lean_to/lean_to_anchor matter only for CAMP.
static func cell_for(place: Place, has_lean_to: bool, lean_to_anchor: Vector2i) -> Vector2i:
	match place:
		Place.WOKE:
			return Waking.WAKE_CELL
		Place.WRECK:
			return WRECK_CELL
		Place.BEACH:
			return BeachLayout.SPAWN_CELL
		Place.SPRING:
			return SPRING_CELL
	return WakeSpot.beside_lean_to(lean_to_anchor, Waking.WAKE_CELL) if has_lean_to else CAMP_CELL

## The way he faces on arrival: UP for SPRING (towards it), DOWN for every other place.
static func facing_for(place: Place) -> Walk.Facing:
	return Walk.Facing.UP if place == Place.SPRING else Walk.Facing.DOWN

## "On" when DebugSwitches.walk_through, else "Off".
static func walk_through_text() -> String:
	return ON if DebugSwitches.walk_through else OFF

## Flips DebugSwitches.walk_through.
static func flip_walk_through() -> void:
	DebugSwitches.walk_through = not DebugSwitches.walk_through

## Appends to menu's PLACE page: the Walk through things row, then one row per Place in enum order.
## go_to is (place: Place) -> void; when it is not valid (the story has no man), place rows get no select.
static func add_rows(menu: DebugMenu, go_to: Callable) -> void:
	menu.add_row(DebugMenu.Page.PLACE, DebugRow.new(WALK_THROUGH, walk_through_text,
			func(_delta: int) -> void: flip_walk_through(),
			func() -> DebugRow.Result:
				flip_walk_through()
				return DebugRow.Result.DONE))
	for place: Place in Place.values():
		var p := place
		var select := Callable()
		if go_to.is_valid():
			select = func() -> DebugRow.Result:
				go_to.call(p)
				return DebugRow.Result.DONE
		menu.add_row(DebugMenu.Page.PLACE, DebugRow.new(NAMES[p], Callable(), Callable(), select))
