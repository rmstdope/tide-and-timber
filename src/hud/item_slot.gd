class_name ItemSlot
extends Control
## One 16x16 slot: frame, icon, count in the bottom-right corner. Clicking it does nothing.

var kind: int = Inventory.EMPTY
var count := 0

func _init() -> void:
	custom_minimum_size = Vector2(16, 16)
	size = Vector2(16, 16)
	mouse_filter = MOUSE_FILTER_STOP

func show_item(p_kind: int, p_count: int) -> void:
	kind = p_kind
	count = p_count
	queue_redraw()

func count_text() -> String:
	return "" if kind == Inventory.EMPTY else str(count)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 16, 16), Color("#7a5030"))
	draw_rect(Rect2(1, 1, 14, 14), Color("#e8cf9c"))
	draw_rect(Rect2(1, 1, 14, 1), Color("#f6e4bb"))
	if kind == Inventory.EMPTY:
		return
	draw_texture(Item.icon_of(kind as Item.Kind), Vector2(3, 2))
	var text := count_text()
	Glyphs.draw(self, text, Vector2(15 - Glyphs.width(text), 10), Color("#3a2414"))
