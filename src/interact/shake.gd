class_name Shake
extends Usable
## A palm's coconuts: all fall to the sand under its crown on the first shake, then the palm is bare for good.

const COCONUT := preload("res://src/beach/props/coconut.tscn")
const DROPS: Array[Vector2] = [Vector2(-12, 9), Vector2(18, 11)]   # where each coconut lands, from the palm's foot
const WIGGLE_STEP := 0.06     # s per step of the trunk's 1 px wiggle: +1, -1, +1, 0
const FALL_TIME := 0.3        # s for a coconut to fall from the crown to the sand

@export var crown: Node2D            ## the coconuts drawn in the crown; hidden once shaken
@export var tree_sprite: Sprite2D    ## the palm's sprite, wiggled on a shake
var drop_parent: Node                ## where fallen coconuts go; Beach sets it to %Decor
var _shaken := false

func can_use(_inventory: Inventory) -> bool:
	return not _shaken

func use(_inventory: Inventory) -> void:
	if _shaken:
		return
	if drop_parent == null:
		push_error("Shake has no drop_parent")
		return
	_shaken = true
	crown.hide()
	var wiggle := tree_sprite.create_tween()
	for x: float in [1.0, -1.0, 1.0, 0.0]:
		wiggle.tween_property(tree_sprite, "position:x", x, WIGGLE_STEP)
	for d in DROPS:
		var c := COCONUT.instantiate() as Node2D
		drop_parent.add_child(c)
		c.global_position = global_position + d + Vector2(crown.position.x, 0)
		var s := c.get_node("Sprite") as Sprite2D
		var rest := s.offset.y
		s.offset.y = crown.position.y - d.y
		c.create_tween().tween_property(s, "offset:y", rest, FALL_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func is_shaken() -> bool:
	return _shaken
