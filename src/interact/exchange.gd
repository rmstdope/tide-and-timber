class_name Exchange
extends Usable
## Turns one carried thing into another, here, as often as he brings one. Never runs out.

@export var takes: Item.Kind = Item.Kind.COCONUT
@export var gives: Item.Kind = Item.Kind.EMPTY_SHELL

func can_use(inventory: Inventory) -> bool:
	return inventory.count(takes) >= 1

func use(inventory: Inventory) -> void:
	# Remove first, so the last one's slot is free for what it becomes.
	if inventory.remove(takes, 1):
		inventory.add(gives, 1)
