extends Node
## Prints the beach's layout (BeachLayoutDump) and quits. Development only:
## godot --headless --path . res://tools/beach_layout/dump_beach_layout.tscn

func _ready() -> void:
	var beach := (load("res://src/beach/beach.tscn") as PackedScene).instantiate()
	add_child(beach)
	await get_tree().process_frame
	for line in BeachLayoutDump.lines(beach):
		print(line)
	get_tree().quit()
