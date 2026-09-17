class_name SaveData
extends RefCounted
## One saved game as plain values, and its JSON-ready form. No nodes, no disk.

## The save format's version. Before the first public release, new state is added to the format
## in place without bumping it. After a release, every change bumps it and adds a migration (tr-asx.4).
## Loading an older version goes through SaveMigrations; bumping VERSION needs a step there.
const VERSION := 1

var player_position := Vector2.ZERO
var player_facing: Walk.Facing = Walk.Facing.DOWN
var inventory_slots: Array[Dictionary] = []      # Inventory.to_slots() shape
var taken: Dictionary = {}                       # prop id (String) -> Array[Vector2i] of layout cells taken
var clock_minutes: float = GameClock.START_MINUTES   # the clock's total_minutes at the save
var lean_to_cells: Array[Vector2i] = []          # the lean-to's 6 cells, BuildSite.cells_for order; empty = none built
var has_fire := false
var fire_cell := Vector2i.ZERO
var fire_lit := false
var fire_out_at: float = INF                     # total game minutes; INF = never (CampFire.out_at's meaning)

## The files of one slot, by file stem: {"meta": {...}, "player": {...}, "inventory": {...}, "world": {...}, "clock": {...}}.
func to_files() -> Dictionary:
	var slots := []
	for slot in inventory_slots:
		slots.append({} if slot.is_empty() else {"item": Item.id_of(slot["kind"]), "count": slot["count"]})
	var world := {}
	for id: String in taken:
		var cells := []
		for cell: Vector2i in taken[id]:
			cells.append([cell.x, cell.y])
		world[id] = cells
	return {
		"meta": {"version": VERSION, "game_version": str(ProjectSettings.get_setting("application/config/version"))},
		"player": {"x": player_position.x, "y": player_position.y, "facing": Walk.facing_name(player_facing)},
		"inventory": {"slots": slots},
		"world": {"taken": world, "camp": _camp_file()},
		"clock": {"total_minutes": clock_minutes},
	}

## The reverse. Returns null when any file is missing or malformed, or when meta.version != VERSION.
## meta.game_version is ignored: absent or of any type, it changes nothing.
static func from_files(files: Dictionary) -> SaveData:
	for stem in ["meta", "player", "inventory", "world", "clock"]:
		if not files.get(stem) is Dictionary:
			return null
	var version: Variant = files["meta"].get("version")
	if not _is_whole(version) or int(version) != VERSION:
		return null
	var data := SaveData.new()
	var minutes: Variant = files["clock"].get("total_minutes")
	if not _is_number(minutes) or float(minutes) < 0.0:
		return null
	data.clock_minutes = float(minutes)
	var player: Dictionary = files["player"]
	if not _is_number(player.get("x")) or not _is_number(player.get("y")):
		return null
	data.player_position = Vector2(player["x"], player["y"])
	var facing := Walk.facing_for_name(str(player.get("facing"))) if player.get("facing") is String else -1
	if facing < 0:
		return null
	data.player_facing = facing as Walk.Facing
	var slots: Variant = files["inventory"].get("slots")
	if not slots is Array or slots.size() != Inventory.SLOT_COUNT:
		return null
	for slot: Variant in slots:
		if not slot is Dictionary:
			return null
		if slot.is_empty():
			data.inventory_slots.append({})
			continue
		var kind := Item.kind_for_id(slot["item"]) if slot.get("item") is String else -1
		var amount: Variant = slot.get("count")
		if kind < 0 or not _is_whole(amount) or int(amount) < 1:
			return null
		data.inventory_slots.append({"kind": kind, "count": int(amount)})
	var world: Variant = files["world"].get("taken")
	if not world is Dictionary:
		return null
	for id: Variant in world:
		if not id is String or not world[id] is Array:
			return null
		var cells: Array[Vector2i] = []
		for cell: Variant in world[id]:
			if not cell is Array or cell.size() != 2 or not _is_whole(cell[0]) or not _is_whole(cell[1]):
				return null
			cells.append(Vector2i(int(cell[0]), int(cell[1])))
		data.taken[id] = cells
	if not _read_camp(files["world"], data):
		return null
	return data

## world.camp: "lean_to" only when built, "fire" only when built; "out_at" only for a lit fire with a clock.
func _camp_file() -> Dictionary:
	var camp := {}
	if not lean_to_cells.is_empty():
		var cells := []
		for cell in lean_to_cells:
			cells.append([cell.x, cell.y])
		camp["lean_to"] = cells
	if has_fire:
		var fire := {"x": fire_cell.x, "y": fire_cell.y, "lit": fire_lit}
		if fire_lit and is_finite(fire_out_at):
			fire["out_at"] = fire_out_at
		camp["fire"] = fire
	return camp

## Reads world.camp into data. Absent means an older save with no camp. False when malformed.
static func _read_camp(world: Dictionary, data: SaveData) -> bool:
	if not world.has("camp"):
		return true
	var camp: Variant = world["camp"]
	if not camp is Dictionary:
		return false
	if camp.has("lean_to"):
		var cells: Variant = camp["lean_to"]
		if not cells is Array or cells.size() != 6:
			return false
		for cell: Variant in cells:
			if not cell is Array or cell.size() != 2 or not _is_whole(cell[0]) or not _is_whole(cell[1]):
				return false
			data.lean_to_cells.append(Vector2i(int(cell[0]), int(cell[1])))
	if camp.has("fire"):
		var fire: Variant = camp["fire"]
		if not fire is Dictionary or not _is_whole(fire.get("x")) or not _is_whole(fire.get("y")) \
				or typeof(fire.get("lit")) != TYPE_BOOL:
			return false
		if fire.has("out_at"):
			if not _is_number(fire["out_at"]):
				return false
			if fire["lit"]:
				data.fire_out_at = float(fire["out_at"])
		data.has_fire = true
		data.fire_cell = Vector2i(int(fire["x"]), int(fire["y"]))
		data.fire_lit = fire["lit"]
	return true

## The in-game day this save was made on: DAY 1 is 1.
func day() -> int:
	return _day_at(clock_minutes)

static func _day_at(minutes: float) -> int:
	var clock := GameClock.new()
	clock.total_minutes = minutes
	return clock.day()

static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

static func _is_whole(value: Variant) -> bool:
	return _is_number(value) and float(value) == floorf(float(value))
