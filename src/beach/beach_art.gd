class_name BeachArt
extends RefCounted
## Every Farming 101 region and offset used on the beach, and the helpers that dress a placed prop in one.
## A sub-resource in a .tscn is shared by every instance, so each prop is dressed with a fresh AtlasTexture.

const PALMS := preload("res://assets/beach/palms.png")
const PALM_CROWNS := preload("res://assets/beach/palm_crowns.png")
const COCONUTS := preload("res://assets/farming_101/beach/coconuts.png")
const SHELLS := preload("res://assets/farming_101/beach/seashells.png")
const BARE_SHIFT := 320
## The six palm shapes, in the brown-coconut group of palms.png / palm_crowns.png. The bare tree is BARE_SHIFT left.
const PALM_SHAPES: Array[Rect2i] = [Rect2i(342, 16, 31, 56), Rect2i(389, 18, 36, 54), Rect2i(342, 83, 34, 53),
		Rect2i(391, 82, 33, 54), Rect2i(435, 87, 37, 50), Rect2i(432, 25, 64, 48)]
## Per shape, the trunk's foot x inside its rect.
const PALM_FEET: Array[int] = [16, 18, 16, 18, 20, 60]
## Per shape, where the coconuts hang, from the palm's origin (its foot on the ground).
const PALM_CROWN_AT: Array[Vector2] = [Vector2(0, -32), Vector2(0, -32), Vector2(0, -30), Vector2(0, -30),
		Vector2(0, -32), Vector2(-35, -26)]
const PALM_DROP := 4            # the palm's rect bottom is this far below its origin (the shadow's lower edge)
const COCONUT := Rect2i(3, 19, 10, 10)
## Pink scallop, pink clam, brown spiral, blue scallop.
const SHELL_SHAPES: Array[Rect2i] = [Rect2i(2, 2, 11, 12), Rect2i(0, 18, 14, 11), Rect2i(2, 34, 12, 13),
		Rect2i(18, 2, 11, 12)]
const SHELL_DROP := -1
const BEACH_GRASS := preload("res://assets/farming_101/beach/beach grass.png")
const OCEAN_ROCKS := preload("res://assets/farming_101/beach/ocean rocks.png")
## The four clumps of beach grass.png.
const GRASS_SHAPES: Array[Rect2i] = [Rect2i(0, 12, 15, 17), Rect2i(16, 10, 15, 20), Rect2i(33, 11, 13, 17),
		Rect2i(50, 13, 11, 15)]
## The three rocks of ocean rocks.png.
const SEA_ROCK_SHAPES: Array[Rect2i] = [Rect2i(3, 7, 27, 19), Rect2i(32, 1, 32, 14), Rect2i(33, 16, 14, 15)]
## Per sea rock shape, the width of its Base. The Base is SEA_ROCK_BASE_HEIGHT tall with its bottom on the origin.
const SEA_ROCK_BASE_WIDTHS: Array[int] = [23, 28, 12]
const SEA_ROCK_BASE_HEIGHT := 8

## A fresh AtlasTexture of `region` in `sheet`. It is never shared, so it may be changed.
static func atlas(sheet: Texture2D, region: Rect2i) -> AtlasTexture:
	var t := AtlasTexture.new()
	t.atlas = sheet
	t.region = Rect2(region)
	return t

## The whole-pixel top-left offset (for centered = false) of a `size` sprite whose foot is `foot_x` px in
## from its left and whose bottom is `drop` px below the origin.
static func foot_offset(size: Vector2i, foot_x: int, drop: int) -> Vector2:
	return Vector2(-foot_x, -size.y + drop)

## foot_offset with the foot at the middle (integer division, the drawing's Math.round).
static func centre_offset(size: Vector2i, drop: int) -> Vector2:
	@warning_ignore("integer_division")
	return foot_offset(size, size.x / 2, drop)

## Dresses a palm.tscn instance as shape `shape` (0..5): the bare tree on Sprite, the coconuts on Crown.
static func dress_palm(palm: Node2D, shape: int) -> void:
	var rect := PALM_SHAPES[shape]
	var sprite := palm.get_node("Sprite") as Sprite2D
	sprite.texture = atlas(PALMS, Rect2i(rect.position - Vector2i(BARE_SHIFT, 0), rect.size))
	sprite.centered = false
	sprite.offset = foot_offset(rect.size, PALM_FEET[shape], PALM_DROP)
	var crown := palm.get_node("Crown") as Sprite2D
	crown.texture = atlas(PALM_CROWNS, rect)
	crown.centered = false
	crown.position = PALM_CROWN_AT[shape]
	crown.offset = sprite.offset - crown.position

## Dresses a shellfish.tscn instance as shell `shape` (0..3).
static func dress_shellfish(shell: Node2D, shape: int) -> void:
	var rect := SHELL_SHAPES[shape]
	var sprite := shell.get_node("Sprite") as Sprite2D
	sprite.texture = atlas(SHELLS, rect)
	sprite.centered = false
	sprite.offset = centre_offset(rect.size, SHELL_DROP)

## Dresses a beach_grass.tscn instance as clump `shape` (0..3).
static func dress_grass(grass: Node2D, shape: int) -> void:
	_dress(grass.get_node("Sprite") as Sprite2D, BEACH_GRASS, GRASS_SHAPES[shape])

## Dresses a sea_rock.tscn instance as rock `shape` (0..2): its look, and a new RectangleShape2D on Base of
## Vector2(SEA_ROCK_BASE_WIDTHS[shape], SEA_ROCK_BASE_HEIGHT) at Base.position (0, -SEA_ROCK_BASE_HEIGHT / 2).
static func dress_sea_rock(rock: Node2D, shape: int) -> void:
	_dress(rock.get_node("Sprite") as Sprite2D, OCEAN_ROCKS, SEA_ROCK_SHAPES[shape])
	var base := rock.get_node("Base") as CollisionShape2D
	var box := RectangleShape2D.new()   # never the scene's own: that sub-resource is shared by every rock
	box.size = Vector2(SEA_ROCK_BASE_WIDTHS[shape], SEA_ROCK_BASE_HEIGHT)
	base.shape = box
	@warning_ignore("integer_division")
	base.position = Vector2(0, -SEA_ROCK_BASE_HEIGHT / 2)

static func _dress(sprite: Sprite2D, sheet: Texture2D, rect: Rect2i) -> void:
	sprite.texture = atlas(sheet, rect)
	sprite.centered = false
	sprite.offset = centre_offset(rect.size, 0)
