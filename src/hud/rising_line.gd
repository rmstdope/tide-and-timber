class_name RisingLine
extends Node2D
## "+1 Driftwood" rising over the man and fading within a second, then gone.

const START := Vector2(0, -36)        # above his head (his sprite spans y -30..0)
const RISE := 12.0                    # px risen over LIFETIME
const LIFETIME := 0.9                 # s until freed
const FADE_DELAY := 0.3               # s fully opaque before fading
const NODE_NAME := &"RisingLine"

## Shows `text` over `host`, replacing a line still rising there.
static func show_over(host: Node2D, text: String) -> RisingLine:
	var old := host.get_node_or_null(NodePath(NODE_NAME))
	if old:
		host.remove_child(old)
		old.queue_free()
	var line := RisingLine.new()
	line.name = NODE_NAME
	line.position = START
	if host.is_inside_tree():
		line.scale = Vector2.ONE * UiScale.current(Display.prefs, host.get_tree().root)
	line.z_index = 20
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", 8)
	label.add_theme_color_override(&"font_color", HudColours.PALE)
	label.add_theme_color_override(&"font_outline_color", HudColours.INK)
	label.add_theme_constant_override(&"outline_size", 2)
	label.size = label.get_minimum_size()
	var rel := TextScale.relative(Display.prefs, host.get_tree().root) if host.is_inside_tree() else 1.0
	label.scale = Vector2.ONE * rel
	label.position = Vector2(-floorf(label.size.x * rel / 2), -ceilf(label.size.y * rel))
	line.add_child(label)
	host.add_child(line)
	var tween := line.create_tween().set_parallel()
	tween.tween_property(line, "position:y", START.y - RISE, LIFETIME)
	tween.tween_property(line, "modulate:a", 0.0, LIFETIME - FADE_DELAY).set_delay(FADE_DELAY)
	tween.chain().tween_callback(line.queue_free)
	return line
