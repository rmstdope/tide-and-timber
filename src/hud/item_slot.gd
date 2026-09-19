class_name ItemSlot
extends Control
## One 22x22 set-in slot: the recoloured pack slot, icon, count in the bottom-right corner, and a
## pale ring when selected (nothing selects one yet). Clicking it does nothing.

const SIZE := Vector2(22, 22)
const TEXTURE := preload("res://assets/hud/slot.png")
const ICON_AT := Vector2(6, 5)            # where today's 10x10 icon sits, unscaled
const COUNT_CORNER := Vector2(21, 20)     # the count's bottom-right corner in slot units
## The 1 px ring just outside the slot.
const RING: Array[Rect2] = [Rect2(-1, -1, 24, 1), Rect2(-1, 22, 24, 1), Rect2(-1, 0, 1, 22), Rect2(22, 0, 1, 22)]
## The count's halo offsets, in glyph units.
const HALO: Array[Vector2] = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]

var selected := false:
	set(value):
		selected = value
		queue_redraw()
var kind: int = Inventory.EMPTY
var count := 0

func _init() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = MOUSE_FILTER_STOP

func _ready() -> void:
	Display.changed.connect(queue_redraw)
	get_tree().root.size_changed.connect(queue_redraw)

## Where the count's words sit in slot units at relative scale `rel`: bottom-right corner fixed at
## COUNT_CORNER, so a grown count overhangs left and up, never right or down.
static func count_rect(text: String, rel: float) -> Rect2:
	var w := Glyphs.width(text) * rel
	var h := Glyphs.H * rel
	return Rect2(COUNT_CORNER.x - w, COUNT_CORNER.y - h, w, h)

## How much bigger the count is than at Text size Normal; 1.0 out of the tree.
func text_scale() -> float:
	return TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

func show_item(p_kind: int, p_count: int) -> void:
	kind = p_kind
	count = p_count
	queue_redraw()

func count_text() -> String:
	return "" if kind == Inventory.EMPTY or count < 2 else str(count)

func _draw() -> void:
	draw_texture(TEXTURE, Vector2.ZERO)
	if selected:
		for r in RING:
			draw_rect(r, HudColours.PALE)
	if kind == Inventory.EMPTY:
		return
	draw_texture(Item.icon_of(kind as Item.Kind), ICON_AT)
	var text := count_text()
	if text.is_empty():
		return
	var rel := text_scale()
	draw_set_transform(count_rect(text, rel).position, 0.0, Vector2.ONE * rel)
	for o in HALO:
		Glyphs.draw(self, text, o, HudColours.PALE)
	Glyphs.draw(self, text, Vector2.ZERO, HudColours.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
