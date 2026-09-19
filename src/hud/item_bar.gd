class_name ItemBar
extends Control
## The always-shown knobbed frame of 8 slots at the bottom centre, with a name plate on pointer rest.

const PLANK_SIZE := Vector2(204, 34)    # the knobbed frame: 8 slots of 22 at a 24 step, 7 in from each side, 6 from top and bottom
const GROUP := &"item_bar"               # HintLift finds the drawn bar through it
const TOP := Screen.HEIGHT - 35.0       # the frame's top, 35 above the bottom of the picture
const NAME_HEIGHT := 13.0               # the name plate's Normal height
const SLOT_AT := Vector2(7, 6)          # slot 0's top-left
const SLOT_STEP := 24.0                 # from one slot's left edge to the next
const FRAME := preload("res://src/hud/frame.tres")
const NAME_BOTTOM := -6.0               # its bottom edge above the bar, whatever its height

var slots: Array[ItemSlot] = []
var name_plank: Control                 ## hidden unless the pointer rests on a filled slot
var name_label: Label
var _inventory: Inventory
var _hovered := -1

func _ready() -> void:
	add_to_group(GROUP)
	position = Vector2(roundi((Screen.WIDTH - PLANK_SIZE.x) / 2), TOP)
	size = PLANK_SIZE
	mouse_filter = MOUSE_FILTER_STOP
	for i in Inventory.SLOT_COUNT:
		var slot := ItemSlot.new()
		slot.position = SLOT_AT + Vector2(i * SLOT_STEP, 0)
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
	name_label.add_theme_color_override(&"font_color", HudColours.CREAM)
	name_label.position = Vector2(4, 3)
	name_plank.add_child(name_label)
	name_plank.draw.connect(func() -> void:
		var w := name_plank.size.x
		var h := name_plank.size.y
		name_plank.draw_rect(Rect2(0, 0, w, h), HudColours.WOOD_DARK)
		name_plank.draw_rect(Rect2(1, 1, w - 2, h - 2), HudColours.WOOD))
	add_child(name_plank)
	Display.changed.connect(_refit_name)
	get_tree().root.size_changed.connect(_refit_name)

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
	var rel := TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	name_label.text = Item.name_of(slots[i].kind as Item.Kind)
	name_label.scale = Vector2.ONE
	var w := ceili(name_label.get_minimum_size().x * rel) + 8
	var h := NAME_HEIGHT + TextScale.extra(HintLine.FONT_SIZE, rel)
	name_label.scale = Vector2.ONE * rel
	name_plank.size = Vector2(w, h)
	var centre := SLOT_AT.x + i * SLOT_STEP + ItemSlot.SIZE.x / 2.0
	var half := Screen.WIDTH / 2.0 / _scale()
	var left := Screen.WIDTH / 2.0 - half + 2 - position.x
	var right := Screen.WIDTH / 2.0 + half - 2 - position.x - w
	# At 640x360 every plank fits the visible span (item_bar_test.gd holds that), so it is only clamped.
	var x := clampf(floorf(centre - w / 2.0), left, right)
	name_plank.position = Vector2(x, NAME_BOTTOM - h)
	name_plank.show()
	name_plank.queue_redraw()

## Refits the shown name plank when UI size, Text size or the window changes.
func _refit_name() -> void:
	if _hovered >= 0:
		_show_name(_hovered)

# The bar's layer scale: it grows about the bottom centre, so the visible span is Screen.CENTRE.x ± Screen.CENTRE.x / s.
func _scale() -> float:
	return UiScale.current(Display.prefs, get_tree().root) if is_inside_tree() else 1.0

func _draw() -> void:
	draw_style_box(FRAME, Rect2(Vector2.ZERO, PLANK_SIZE))
