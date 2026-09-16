class_name Beach
extends Node2D
## The long beach: ground, props, the man, the loose camera, and what he carries with its bar.
## Handles no input itself, so Esc does nothing.

const TILES := preload("res://assets/beach/tiles.png")
const ROCK := preload("res://src/beach/props/rock.tscn")
const BOULDER := preload("res://src/beach/props/boulder.tscn")
const PALM := preload("res://src/beach/props/palm.tscn")
const DRIFTWOOD := preload("res://src/beach/props/driftwood.tscn")
const SHELLFISH := preload("res://src/beach/props/shellfish.tscn")

var inventory := Inventory.new()

func _ready() -> void:
	%Ground.tile_set = BeachTileSet.build(TILES)
	for y in BeachLayout.MAP_SIZE.y:
		for x in BeachLayout.MAP_SIZE.x:
			var cell := Vector2i(x, y)
			%Ground.set_cell(cell, 0, Vector2i(BeachLayout.kind_at(cell), 0))
	_place(PALM, BeachLayout.PALMS, %World)
	_place(ROCK, BeachLayout.ROCKS, %World)
	_place(BOULDER, BeachLayout.BOULDERS, %World)
	_place(DRIFTWOOD, BeachLayout.DRIFTWOOD, %Decor)
	_place(SHELLFISH, BeachLayout.SHELLFISH, %Decor)
	%Player.position = BeachLayout.cell_centre(BeachLayout.SPAWN_CELL)
	%Player.facing = Walk.Facing.DOWN
	%Camera.target = %Player
	%Camera.snap_to_target()
	%ItemBar.bind(inventory)
	%Interactor.setup(%Player, inventory, %Prompt)

func _place(scene: PackedScene, cells: Array[Vector2i], parent: Node) -> void:
	for cell in cells:
		var prop := scene.instantiate() as Node2D
		prop.position = BeachLayout.cell_base(cell)
		parent.add_child(prop)
