class_name DebugSurvival
extends RefCounted
## The Debug panel's Survival page: Place lean-to, Place fire, Remove builds, Collapse now.

const PLACE_LEAN_TO := "Place lean-to"
const PLACE_FIRE := "Place fire"
const REMOVE_BUILDS := "Remove builds"
const COLLAPSE_NOW := "Collapse now"

## Appends the four rows to menu's SURVIVAL page in that order.
## place: (thing: BuildMenu.Thing) -> bool; remove_builds: () -> void; collapse_now: () -> void.
## A callable left invalid gives its row(s) no select (the story's rows, which are inert anyway).
static func add_rows(menu: DebugMenu, place := Callable(), remove_builds := Callable(), collapse_now := Callable()) -> void:
	menu.add_row(DebugMenu.Page.SURVIVAL, place_row(PLACE_LEAN_TO, place, BuildMenu.Thing.LEAN_TO))
	menu.add_row(DebugMenu.Page.SURVIVAL, place_row(PLACE_FIRE, place, BuildMenu.Thing.FIRE))
	menu.add_row(DebugMenu.Page.SURVIVAL, remove_row(remove_builds))
	menu.add_row(DebugMenu.Page.SURVIVAL, collapse_row(collapse_now))

## label; no value, no step; select: DONE when place.call(thing) is true, else REFUSED.
static func place_row(label: String, place: Callable, thing: BuildMenu.Thing) -> DebugRow:
	if not place.is_valid():
		return DebugRow.new(label)
	return DebugRow.new(label, Callable(), Callable(), func() -> DebugRow.Result:
		return DebugRow.Result.DONE if place.call(thing) else DebugRow.Result.REFUSED)

## REMOVE_BUILDS; no value, no step; select: remove_builds.call(), DONE.
static func remove_row(remove_builds: Callable) -> DebugRow:
	if not remove_builds.is_valid():
		return DebugRow.new(REMOVE_BUILDS)
	return DebugRow.new(REMOVE_BUILDS, Callable(), Callable(), func() -> DebugRow.Result:
		remove_builds.call()
		return DebugRow.Result.DONE)

## COLLAPSE_NOW; no value, no step; select: collapse_now.call(), RESUME.
static func collapse_row(collapse_now: Callable) -> DebugRow:
	if not collapse_now.is_valid():
		return DebugRow.new(COLLAPSE_NOW)
	return DebugRow.new(COLLAPSE_NOW, Callable(), Callable(), func() -> DebugRow.Result:
		collapse_now.call()
		return DebugRow.Result.RESUME)
