class_name LooseCamera
extends Camera2D
## Follows its target loosely, and always draws on whole pixels.

var target: Node2D
var centre := Vector2.ZERO               # unrounded; the drawn position is centre.round()

func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	process_physics_priority = 10        # after the Player's 0

func snap_to_target() -> void:
	centre = target.global_position
	global_position = centre.round()
