class_name ClickMark
extends Node2D
## A small pale cross where a click landed, shown briefly, then gone.

const COLOUR := HudColours.PALE
const LIFETIME := 0.5            # s until freed
const FADE_DELAY := 0.2          # s fully opaque before fading
const NODE_NAME := &"ClickMark"

## Shows a mark at `at` under `parent`, replacing one still there.
static func show_at(parent: Node2D, at: Vector2) -> ClickMark:
	var old := parent.get_node_or_null(NodePath(NODE_NAME))
	if old:
		parent.remove_child(old)
		old.queue_free()
	var mark := ClickMark.new()
	mark.name = NODE_NAME
	mark.position = at
	parent.add_child(mark)
	var tween := mark.create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, LIFETIME - FADE_DELAY).set_delay(FADE_DELAY)
	tween.tween_callback(mark.queue_free)
	return mark

func _draw() -> void:
	draw_rect(Rect2(-2, 0, 5, 1), COLOUR)
	draw_rect(Rect2(0, -2, 1, 5), COLOUR)
