class_name LooseCamera
extends Camera2D
## Follows its target loosely, and always draws on whole pixels.

var target: Node2D
var centre := Vector2.ZERO               # unrounded; the drawn position is centre.round()
var bounds := LooseFollow.UNBOUNDED      # the rect `centre` may lie in; the whole world until told

func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	process_physics_priority = 10        # after the Player's 0

## Hold the view inside `world`, in world px. Called before the first snap; re-clamps at once.
func keep_inside(world: Rect2) -> void:
	bounds = LooseFollow.centre_bounds(world, Screen.SIZE)
	centre = LooseFollow.clamp_centre(centre, bounds)
	global_position = centre.round()

func snap_to_target() -> void:
	centre = LooseFollow.clamp_centre(target.global_position, bounds)
	global_position = centre.round()

func _physics_process(delta: float) -> void:
	if target == null:
		return
	centre = LooseFollow.clamp_centre(LooseFollow.step(centre, target.global_position, delta), bounds)
	global_position = centre.round()
