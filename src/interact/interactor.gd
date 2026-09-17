class_name Interactor
extends Node
## Chooses what the man would use now, shows its prompt, and uses it on E.

const USE_ACTION := &"use"

var player: Player
var inventory: Inventory
var prompt: UsePrompt

func setup(p_player: Player, p_inventory: Inventory, p_prompt: UsePrompt) -> void:
	player = p_player
	inventory = p_inventory
	prompt = p_prompt

## The usable thing E would act on now, or null.
func target() -> Usable:
	if player == null:
		return null
	var candidates: Array[Usable] = []
	var spots: Array[Vector2] = []
	for node in get_tree().get_nodes_in_group(Usable.GROUP):
		var usable := node as Usable
		if usable and not usable.is_gone() and usable.can_use(inventory):
			candidates.append(usable)
			spots.append(usable.global_position)
	var i := Reach.pick(player.global_position, Walk.facing_vector(player.facing), spots)
	return null if i < 0 else candidates[i]

## Uses it as E would. Does not check distance: the caller has already brought him there.
func try_use(usable: Usable) -> bool:
	if usable == null or not is_instance_valid(usable) or usable.is_gone() or not usable.can_use(inventory):
		return false
	usable.use(inventory)
	if player != null:
		player.collect()
	return true

func _process(_delta: float) -> void:
	if player == null:
		return
	var t := target()
	if t:
		prompt.show_for(t)
	else:
		prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if player == null:
		return
	if InputDevice.action_pressed(event, USE_ACTION):
		try_use(target())
		get_viewport().set_input_as_handled()
