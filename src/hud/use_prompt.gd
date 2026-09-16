class_name UsePrompt
extends Node2D
## The small wooden [E] <verb> prompt in the world, its bottom-centre just above the thing.

func _ready() -> void:
	hide()

func show_for(usable: Usable) -> void:
	global_position = (usable.global_position + usable.prompt_offset).round()
	show()
