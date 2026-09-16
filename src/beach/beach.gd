class_name Beach
extends Node2D
## The long beach: ground, props and the spring, the man, the loose camera, and what he carries with its bar.
## Handles no input itself, so Esc does nothing.

const TILES := preload("res://assets/beach/tiles.png")
const ROCK := preload("res://src/beach/props/rock.tscn")
const BOULDER := preload("res://src/beach/props/boulder.tscn")
const PALM := preload("res://src/beach/props/palm.tscn")
const DRIFTWOOD := preload("res://src/beach/props/driftwood.tscn")
const SHELLFISH := preload("res://src/beach/props/shellfish.tscn")
const SPRING := preload("res://src/beach/props/spring.tscn")
const PUFF := preload("res://src/beach/marks/puff.tscn")
const RIPPLE := preload("res://src/beach/marks/ripple.tscn")

var inventory := Inventory.new()

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

func _on_added(kind: Item.Kind, amount: int) -> void:
	RisingLine.show_over(%Player, Item.gain_line(kind, amount))

func _place(scene: PackedScene, cells: Array[Vector2i], parent: Node) -> Array[Node2D]:
	var placed: Array[Node2D] = []
	for cell in cells:
		var prop := scene.instantiate() as Node2D
		prop.position = BeachLayout.cell_base(cell)
		parent.add_child(prop)
		placed.append(prop)
	return placed

func _on_trail_mark(kind: StringName, at: Vector2) -> void:
	# Under %Decor, not the y-sorted %World, so a mark at his heels never sorts over his feet.
	var mark := (PUFF if kind == &"puff" else RIPPLE).instantiate() as Node2D
	mark.position = at
	%Decor.add_child(mark)
