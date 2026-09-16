class_name Pickup
extends Usable
## A thing that is simply taken: into the inventory, and gone from the ground for good.

@export var item: Item.Kind = Item.Kind.DRIFTWOOD

func use(inventory: Inventory) -> void:
	inventory.add(item, 1)
	get_parent().queue_free()
