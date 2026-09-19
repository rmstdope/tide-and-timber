class_name Beach
extends Node2D
## The long beach: ground and its waves, props and the spring, the man, the loose camera, and what he carries with its bar.
## Handles no input itself (clicks go to %ClickWalker; B, and Esc while building, to %Builder).

const DRIFTWOOD := preload("res://src/beach/props/driftwood.tscn")
const SHELLFISH := preload("res://src/beach/props/shellfish.tscn")
const PUFF := preload("res://src/beach/marks/puff.tscn")
const RIPPLE := preload("res://src/beach/marks/ripple.tscn")

## The props that are taken for good, by the id a save uses, with their scene; _cells gives their layout cells.
const TAKEABLE := {"driftwood": DRIFTWOOD, "shellfish": SHELLFISH}
const CELL_META := &"cell"

var inventory := Inventory.new()
var walk_grid: WalkGrid

func _ready() -> void:
	var palms := BeachLayout.palms()
	var shells := BeachLayout.shellfish()
	for parent: Node in [%Decor, %World]:
		for child in parent.get_children():
			if child.scene_file_path in BeachLayout.PROP_SCENES:
				child.set_meta(CELL_META, BeachLayout.cell_of_base((child as Node2D).position))
			if child.scene_file_path == BeachLayout.PALM:
				# Each wears the shape of its place in the layout list, so every launch and load looks the same.
				BeachArt.dress_palm(child, palms.find(child.get_meta(CELL_META)) % BeachArt.PALM_SHAPES.size())
				(child.get_node("Shake") as Shake).drop_parent = %Decor
			elif child.scene_file_path == BeachLayout.SHELLFISH:
				BeachArt.dress_shellfish(child, shells.find(child.get_meta(CELL_META)) % BeachArt.SHELL_SHAPES.size())
	%Player.position = BeachLayout.cell_centre(BeachLayout.SPAWN_CELL)
	%Player.facing = Walk.Facing.DOWN
	%Player.is_wading_at = func(at: Vector2) -> bool:
		return BeachLayout.is_wadeable(BeachLayout.kind_at(BeachLayout.cell_at(at)))
	%Player.trail_mark.connect(_on_trail_mark)
	%Camera.target = %Player
	%Camera.keep_inside(BeachLayout.world_rect())
	%Camera.snap_to_target()
	%ItemBar.bind(inventory)
	%Interactor.setup(%Player, inventory, %Prompt)
	inventory.added.connect(_on_added)
	walk_grid = WalkGrid.new(BeachLayout.map_size(), func(t: Vector2i) -> bool: return BeachLayout.is_solid(BeachLayout.kind_at(t)))
	%ClickWalker.setup(%Player, %Interactor, walk_grid, %Decor, _obstacles)
	%Builder.setup(inventory)

## The base boxes of the solid props in %World.
func _obstacles() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for body in %World.get_children():
		if not body is StaticBody2D:
			continue
		for child in body.get_children():
			var shape_node := child as CollisionShape2D
			if shape_node and shape_node.shape is RectangleShape2D:
				var size: Vector2 = (shape_node.shape as RectangleShape2D).size
				rects.append(Rect2(shape_node.global_position - size / 2, size))
	return rects

## The waking scene hands in its clock, so building can stop it and move it on.
func set_day_night(day_night: DayNight) -> void:
	%Builder.day_night = day_night

## Puts the man on `cell`'s centre facing `facing`, standing still, with any click-walk dropped,
## the use prompt hidden until the Interactor next picks, and the camera snapped onto him.
## Works while the tree is paused. Checks nothing: the cell may be solid.
func put_player(cell: Vector2i, facing: Walk.Facing) -> void:
	(%ClickWalker as ClickWalker).cancel()
	%Player.global_position = BeachLayout.cell_centre(cell)
	%Player.facing = facing
	%Player.velocity = Vector2.ZERO
	%Player.moving = false
	%Player.play_pose(Walk.animation_for(facing, false))
	%Prompt.hide()
	%Camera.snap_to_target()

func _on_added(kind: Item.Kind, amount: int) -> void:
	RisingLine.show_over(%Player, Item.gain_line(kind, amount))

func _on_trail_mark(kind: StringName, at: Vector2) -> void:
	# Under %Decor, not the y-sorted %World, so a mark at his heels never sorts over his feet.
	var mark := (PUFF if kind == &"puff" else RIPPLE).instantiate() as Node2D
	mark.position = at
	%Decor.add_child(mark)

## The beach as it is now.
func capture() -> SaveData:
	var data := SaveData.new()
	data.player_position = %Player.global_position
	data.player_facing = %Player.facing
	data.inventory_slots = inventory.to_slots()
	for id: String in TAKEABLE:
		var cells: Array[Vector2i] = []
		for cell: Vector2i in _cells(id):
			if _live_prop(id, cell) == null:
				cells.append(cell)
		data.taken[id] = cells
	%Builder.capture_camp(data)
	return data

## Puts `data` back: the man's place and facing, the bar, the taken props removed, and the camp.
## Returns false and changes nothing when the inventory is refused, a prop id is not in TAKEABLE,
## a cell is not one of that prop's layout cells, or the camp does not fit (Builder.camp_fits).
func restore(data: SaveData) -> bool:
	if not _taken_fits(data) or not Builder.camp_fits(data):
		return false
	if not inventory.restore(data.inventory_slots):
		return false
	for id: String in data.taken:
		for cell: Vector2i in data.taken[id]:
			var prop := _live_prop(id, cell)
			if prop:
				prop.queue_free()
	%Builder.restore_camp(data)
	%Player.global_position = data.player_position
	%Player.facing = data.player_facing
	%Player.velocity = Vector2.ZERO
	%Camera.snap_to_target()
	return true

## Whether restore(data) would accept `data`: every key of data.taken is in TAKEABLE, every cell is
## one of that prop's layout cells, the camp fits, and a new Inventory accepts data.inventory_slots.
## No nodes touched.
static func can_restore(data: SaveData) -> bool:
	return _taken_fits(data) and Builder.camp_fits(data) and Inventory.new().restore(data.inventory_slots)

## The layout cells of the takeable prop `id` (a key of TAKEABLE).
static func _cells(id: String) -> Array[Vector2i]:
	return BeachLayout.driftwood() if id == "driftwood" else BeachLayout.shellfish()

static func _taken_fits(data: SaveData) -> bool:
	for id: String in data.taken:
		if not TAKEABLE.has(id):
			return false
		for cell: Vector2i in data.taken[id]:
			if not _cells(id).has(cell):
				return false
	return true

func _live_prop(id: String, cell: Vector2i) -> Node:
	var path: String = (TAKEABLE[id] as PackedScene).resource_path
	for prop in %Decor.get_children():
		if prop.scene_file_path == path and prop.get_meta(CELL_META, null) == cell and not prop.is_queued_for_deletion():
			return prop
	return null
