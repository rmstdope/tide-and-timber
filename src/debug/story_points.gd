class_name StoryPoints
extends RefCounted
## The Debug panel's Story page: the story's points in order, which one is current, and the world at each.

enum Point { SHIPWRECK, WAKING, FIRST_DAY, FIRST_NIGHT, MORNING_AFTER }

const NAMES: Array[String] = ["Shipwreck story", "Waking on the beach", "First day", "First night", "Morning after"]   # index = Point
const STAR := "★"

const FIRST_DAY_MINUTES := 960.0        # DAY 1 16:00
const FIRST_NIGHT_MINUTES := 1200.0     # DAY 1 20:00
const MORNING_AFTER_MINUTES := 1830.0   # DAY 2 06:30
const FIRE_OUT_AT := 1860.0             # DAY 2 07:00: FireLife.out_at of a fire lit on DAY 1 evening

const CAMP_CELL := Vector2i(86, 10)     # where he stands on the first day, facing down: a lean-to built from here lands on CAMP_LEAN_TO
const CAMP_LEAN_TO: Array[Vector2i] = [Vector2i(85, 11), Vector2i(86, 11), Vector2i(87, 11), Vector2i(85, 12), Vector2i(86, 12), Vector2i(87, 12)]
const CAMP_FIRE := Vector2i(86, 13)     # BuildSite.fire_spot of the lean-to's anchor (86, 12)
const BY_THE_FIRE := Vector2i(85, 13)   # WakeSpot.beside_lean_to(Vector2i(86, 12), Waking.WAKE_CELL)

## The driftwood nearest where he woke, nearest first: 6 picked by the first day, 12 by the first night.
const DRIFTWOOD_BY_NIGHT: Array[Vector2i] = [Vector2i(88, 13), Vector2i(80, 13), Vector2i(107, 13), Vector2i(74, 12), Vector2i(111, 13), Vector2i(69, 12),
	Vector2i(116, 12), Vector2i(64, 13), Vector2i(61, 13), Vector2i(124, 13), Vector2i(130, 13), Vector2i(53, 13)]
const FIRST_DAY_DRIFTWOOD := 6
const SHELLFISH_TAKEN: Array[Vector2i] = [Vector2i(96, 14), Vector2i(75, 14)]

## The point the world is at: SHIPWRECK in the story, else by the clock.
static func current(in_story: bool, total_minutes: float) -> Point:
	if in_story:
		return Point.SHIPWRECK
	if total_minutes >= MORNING_AFTER_MINUTES:
		return Point.MORNING_AFTER
	if total_minutes >= FIRST_NIGHT_MINUTES:
		return Point.FIRST_NIGHT
	if total_minutes >= FIRST_DAY_MINUTES:
		return Point.FIRST_DAY
	return Point.WAKING

## STAR when point == current_point, else "".
static func star_text(point: Point, current_point: Point) -> String:
	return STAR if point == current_point else ""

## The world at a point, as Continue would load it; null for SHIPWRECK and WAKING (they are scenes, not saves).
## A new SaveData on every call.
static func world_for(point: Point) -> SaveData:
	if point == Point.SHIPWRECK or point == Point.WAKING:
		return null
	var d := SaveData.new()
	d.player_facing = Walk.Facing.DOWN
	var shellfish: Array[Vector2i] = SHELLFISH_TAKEN.duplicate()
	if point == Point.FIRST_DAY:
		d.clock_minutes = FIRST_DAY_MINUTES
		d.player_position = BeachLayout.cell_centre(CAMP_CELL)
		d.inventory_slots = _slots(FIRST_DAY_DRIFTWOOD)
		d.taken = {"driftwood": DRIFTWOOD_BY_NIGHT.slice(0, FIRST_DAY_DRIFTWOOD), "shellfish": shellfish}
		return d
	d.clock_minutes = FIRST_NIGHT_MINUTES if point == Point.FIRST_NIGHT else MORNING_AFTER_MINUTES
	d.player_position = BeachLayout.cell_centre(BY_THE_FIRE)
	d.inventory_slots = _slots(0)
	d.taken = {"driftwood": DRIFTWOOD_BY_NIGHT.duplicate(), "shellfish": shellfish}
	d.lean_to_cells = CAMP_LEAN_TO.duplicate()
	d.has_fire = true
	d.fire_cell = CAMP_FIRE
	d.fire_lit = true
	d.fire_out_at = FIRE_OUT_AT
	return d

## The scene a point starts, not in the tree: the intro, a new game's waking, or a waking resumed from world_for(point).
static func scene_for(point: Point) -> Node:
	if point == Point.SHIPWRECK:
		return (load(TitleScreen.INTRO_SCENE) as PackedScene).instantiate()
	var game := (load(TitleScreen.GAME_SCENE) as PackedScene).instantiate() as Waking
	game.resume_data = world_for(point)
	return game

## Unpauses the tree and replaces the current scene with scene_for(point).
static func enter(tree: SceneTree, point: Point) -> void:
	tree.paused = false
	tree.change_scene_to_node(scene_for(point))

## Appends one row per Point to menu's STORY page: its name, the star on the current point, select jumps then resumes.
## current: () -> Point. jump: (point: Point) -> void.
static func add_rows(menu: DebugMenu, current_point: Callable, jump: Callable) -> void:
	for point: Point in Point.values():
		var p := point as Point
		menu.add_row(DebugMenu.Page.STORY, DebugRow.new(NAMES[p],
			func() -> String: return star_text(p, current_point.call()),
			Callable(),
			func() -> DebugRow.Result:
				jump.call(p)
				return DebugRow.Result.RESUME))

static func _slots(driftwood: int) -> Array[Dictionary]:
	var first: Dictionary = {} if driftwood == 0 else {"kind": Item.Kind.DRIFTWOOD, "count": driftwood}
	var slots: Array[Dictionary] = [first, {"kind": Item.Kind.SHELLFISH, "count": 2}, {"kind": Item.Kind.COCONUT, "count": 1},
		{"kind": Item.Kind.FRESH_WATER, "count": 1}, {}, {}, {}, {}]
	return slots
