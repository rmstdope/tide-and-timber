class_name ItemSlot
extends Control
## One 16x16 slot: frame, icon, count in the bottom-right corner. Clicking it does nothing.

var kind: int = Inventory.EMPTY
var count := 0

func _init() -> void:
	custom_minimum_size = Vector2(16, 16)
	size = Vector2(16, 16)
	mouse_filter = MOUSE_FILTER_STOP

func _ready() -> void:
	Display.changed.connect(queue_redraw)
	get_tree().root.size_changed.connect(queue_redraw)

## Where the count's words sit in slot units at relative scale `rel`: bottom-right corner fixed at
## (15, 15), so a grown count overhangs left and up, never right or down.
static func count_rect(text: String, rel: float) -> Rect2:
	var w := Glyphs.width(text) * rel
	var h := Glyphs.H * rel
	return Rect2(15.0 - w, 15.0 - h, w, h)

## How much bigger the count is than at Text size Normal; 1.0 out of the tree.
func text_scale() -> float:
	return TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

func show_item(p_kind: int, p_count: int) -> void:
	kind = p_kind
	count = p_count
	queue_redraw()

func count_text() -> String:
	return "" if kind == Inventory.EMPTY else str(count)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 16, 16), HudColours.WOOD_DARK)
	draw_rect(Rect2(1, 1, 14, 14), HudColours.SLOT_FACE)
	draw_rect(Rect2(1, 1, 14, 1), HudColours.SLOT_EDGE)
	if kind == Inventory.EMPTY:
		return
	draw_texture(Item.icon_of(kind as Item.Kind), Vector2(3, 2))
	var text := count_text()
	var rel := text_scale()
	draw_set_transform(count_rect(text, rel).position, 0.0, Vector2.ONE * rel)
	Glyphs.draw(self, text, Vector2.ZERO, HudColours.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
