class_name Usable
extends Node2D
## Something the man can use, as a child of the thing it belongs to. Its origin is where "next to" is measured from.

const GROUP := &"usable"

@export var verb := ""                          ## the prompt's word, e.g. "Take"
@export var prompt_offset := Vector2(0, -10)    ## the prompt's bottom-centre, relative to this node

func _enter_tree() -> void:
	add_to_group(GROUP)

## Whether it can be used now, given what he carries.
func can_use(_inventory: Inventory) -> bool:
	return true

func use(_inventory: Inventory) -> void:
	pass

func is_gone() -> bool:
	return is_queued_for_deletion() or (get_parent() != null and get_parent().is_queued_for_deletion())
