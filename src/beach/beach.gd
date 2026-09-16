class_name Beach
extends Node2D
## The long beach: ground, props and the spring, the man, the loose camera, and what he carries with its bar.
## Handles no input itself (clicks go to %ClickWalker; B, and Esc while building, to %Builder).

const TILES := preload("res://assets/beach/tiles.png")
const ROCK := preload("res://src/beach/props/rock.tscn")
const BOULDER := preload("res://src/beach/props/boulder.tscn")
const PALM := preload("res://src/beach/props/palm.tscn")
const DRIFTWOOD := preload("res://src/beach/props/driftwood.tscn")
const SHELLFISH := preload("res://src/beach/props/shellfish.tscn")
const SPRING := preload("res://src/beach/props/spring.tscn")
const PUFF := preload("res://src/beach/marks/puff.tscn")
const RIPPLE := preload("res://src/beach/marks/ripple.tscn")

## The props that are taken for good, by the id a save uses, with their scene and layout cells.
const TAKEABLE := {
	"driftwood": {"scene": DRIFTWOOD, "cells": BeachLayout.DRIFTWOOD},
	"shellfish": {"scene": SHELLFISH, "cells": BeachLayout.SHELLFISH},
}
const CELL_META := &"cell"

var inventory := Inventory.new()
var walk_grid: WalkGrid

func _ready() -> void:
	%Ground.tile_set = BeachTileSet.build(TILES)
	for y in BeachLayout.MAP_SIZE.y:
		for x in BeachLayout.MAP_SIZE.x:
			var cell := Vector2i(x, y)
			%Ground.set_cell(cell, 0, Vector2i(BeachLayout.kind_at(cell), 0))
	for palm in _place(PALM, BeachLayout.PALMS, %World):
		(palm.get_node("Shake") as Shake).drop_parent = %Decor
	_place(ROCK, BeachLayout.ROCKS, %World)
	_place(BOULDER, BeachLayout.BOULDERS, %World)
	_place(SPRING, BeachLayout.SPRINGS, %World)
	_place(DRIFTWOOD, BeachLayout.DRIFTWOOD, %Decor)
	_place(SHELLFISH, BeachLayout.SHELLFISH, %Decor)
	%Player.position = BeachLayout.cell_centre(BeachLayout.SPAWN_CELL)
	%Player.facing = Walk.Facing.DOWN
	%Player.is_wading_at = func(at: Vector2) -> bool:
		return BeachLayout.is_wadeable(BeachLayout.kind_at(BeachLayout.cell_at(at)))
	%Player.trail_mark.connect(_on_trail_mark)
	%Camera.target = %Player
	%Camera.snap_to_target()
	%ItemBar.bind(inventory)
	%Interactor.setup(%Player, inventory, %Prompt)
	inventory.added.connect(_on_added)
	walk_grid = WalkGrid.new(BeachLayout.MAP_SIZE, func(t: Vector2i) -> bool: return BeachLayout.is_solid(BeachLayout.kind_at(t)))
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

func _on_added(kind: Item.Kind, amount: int) -> void:
	RisingLine.show_over(%Player, Item.gain_line(kind, amount))

func _place(scene: PackedScene, cells: Array[Vector2i], parent: Node) -> Array[Node2D]:
	var placed: Array[Node2D] = []
	for cell in cells:
		var prop := scene.instantiate() as Node2D
		prop.position = BeachLayout.cell_base(cell)
		prop.set_meta(CELL_META, cell)
		parent.add_child(prop)
		placed.append(prop)
	return placed

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
		for cell: Vector2i in TAKEABLE[id]["cells"]:
			if _live_prop(id, cell) == null:
				cells.append(cell)
		data.taken[id] = cells
	return data

## Puts `data` back: the man's place and facing, the bar, and the taken props removed.
## Returns false and changes nothing when the inventory is refused, a prop id is not in TAKEABLE,
## or a cell is not one of that prop's layout cells.
func restore(data: SaveData) -> bool:
	for id: String in data.taken:
		if not TAKEABLE.has(id):
			return false
		for cell: Vector2i in data.taken[id]:
			if not (TAKEABLE[id]["cells"] as Array).has(cell):
				return false
	if not inventory.restore(data.inventory_slots):
		return false
	for id: String in data.taken:
		for cell: Vector2i in data.taken[id]:
			var prop := _live_prop(id, cell)
			if prop:
				prop.queue_free()
	%Player.global_position = data.player_position
	%Player.facing = data.player_facing
	%Player.velocity = Vector2.ZERO
	%Camera.snap_to_target()
	return true

func _live_prop(id: String, cell: Vector2i) -> Node:
	var path: String = (TAKEABLE[id]["scene"] as PackedScene).resource_path
	for prop in %Decor.get_children():
		if prop.scene_file_path == path and prop.get_meta(CELL_META, null) == cell and not prop.is_queued_for_deletion():
			return prop
	return null
