class_name TrailMark
extends Sprite2D
## A puff or ripple left behind him: fades, optionally grows, then frees itself.

@export var lifetime := 0.4             # s to fade from START_ALPHA to 0, then free itself
@export var grow := 1.0                 # scale reached at the end of the fade

const START_ALPHA := 0.8

func _ready() -> void:
	modulate.a = START_ALPHA
	# Bound to this node, so the tween dies with it.
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, lifetime)
	t.tween_property(self, "scale", Vector2(grow, grow), lifetime)
	t.chain().tween_callback(queue_free)
