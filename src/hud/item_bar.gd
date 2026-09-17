class_name ItemBar
extends Control
## The always-shown wooden bar of 8 slots at the bottom centre, with a name plank on pointer rest.

const PLANK_SIZE := Vector2(141, 22)    # 8 * 17 + 5
const TOP := 157.0                      # y of the plank in the 320x180 base
const SCREEN_WIDTH := 320

var slots: Array[ItemSlot] = []
var name_plank: Control                 ## hidden unless the pointer rests on a filled slot
var name_label: Label
var _inventory: Inventory
var _hovered := -1

func _ready() -> void:
	position = Vector2(roundi((SCREEN_WIDTH - PLANK_SIZE.x) / 2), TOP)
	size = PLANK_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	for i in Inventory.SLOT_COUNT:
		var slot := ItemSlot.new()
		slot.position = Vector2(3 + i * 17, 3)
		slot.mouse_entered.connect(_on_slot_entered.bind(i))
		slot.mouse_exited.connect(_on_slot_exited.bind(i))
		add_child(slot)
		slots.append(slot)
	name_plank = Control.new()
	name_plank.mouse_filter = MOUSE_FILTER_IGNORE
	name_plank.hide()
	name_label = Label.new()
	name_label.mouse_filter = MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override(&"font_size", 8)
	name_label.add_theme_color_override(&"font_color", Color("#f4e3c1"))
	name_label.position = Vector2(4, 3)
	name_plank.add_child(name_label)
	name_plank.draw.connect(func() -> void:
		var w := name_plank.size.x
		name_plank.draw_rect(Rect2(0, 0, w, 13), Color("#7a5030"))
		name_plank.draw_rect(Rect2(1, 1, w - 2, 11), Color("#b07a45"))
		name_plank.draw_rect(Rect2(1, 1, w - 2, 1), Color("#d9a56b")))
	add_child(name_plank)

func bind(inventory: Inventory) -> void:
	_inventory = inventory
	_inventory.changed.connect(refresh)
	refresh()

func refresh() -> void:
	for i in slots.size():
		slots[i].show_item(_inventory.slot_kind(i), _inventory.slot_count(i))
	if _hovered >= 0:
		_show_name(_hovered)

func _on_slot_entered(i: int) -> void:
	_hovered = i
	_show_name(i)

func _on_slot_exited(i: int) -> void:
	if _hovered == i:
		_hovered = -1
		name_plank.hide()

func _show_name(i: int) -> void:
	if slots[i].kind == Inventory.EMPTY:
		name_plank.hide()
		return
	name_label.text = Item.name_of(slots[i].kind as Item.Kind)
	var w := ceili(name_label.get_minimum_size().x) + 8
	name_plank.size = Vector2(w, 13)
	var centre := 3 + i * 17 + 8
	var half := SCREEN_WIDTH / 2.0 / _scale()
	var left := SCREEN_WIDTH / 2.0 - half + 2 - position.x
	var right := SCREEN_WIDTH / 2.0 + half - 2 - position.x - w
	name_plank.position = Vector2(clampf(floorf(centre - w / 2.0), left, right), -19)
	name_plank.show()
	name_plank.queue_redraw()

# The bar's layer scale: it grows about the bottom centre, so the visible span is 160 ± 160 / s.
func _scale() -> float:
	return UiScale.current(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, PLANK_SIZE), Color("#7a5030"))
	draw_rect(Rect2(1, 1, 139, 20), Color("#b07a45"))
	draw_rect(Rect2(1, 1, 139, 1), Color("#d9a56b"))
