class_name Inventory
extends RefCounted
## What the man carries: one slot per kind, 8 slots, no limit per slot.

signal changed                                   ## after any add or successful remove
signal added(kind: Item.Kind, amount: int)       ## after add, emitted after `changed`

const SLOT_COUNT := 8
const EMPTY := -1

var _slots: Array[int] = []      # SLOT_COUNT entries, each an Item.Kind or EMPTY
var _counts: Dictionary = {}     # Item.Kind -> int, only kinds carried (> 0)

func _init() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(EMPTY)

func add(kind: Item.Kind, amount: int = 1) -> void:
	if amount <= 0:
		push_error("Inventory.add: amount must be positive, got %d" % amount)
		return
	if not _counts.has(kind):
		var slot := _slots.find(EMPTY)
		if slot < 0:
			push_error("Inventory.add: no empty slot for %s" % Item.name_of(kind))
			return
		_slots[slot] = kind
		_counts[kind] = 0
	_counts[kind] += amount
	changed.emit()
	added.emit(kind, amount)

func remove(kind: Item.Kind, amount: int = 1) -> bool:
	if amount <= 0 or count(kind) < amount:
		return false
	_counts[kind] -= amount
	if _counts[kind] == 0:
		_counts.erase(kind)
		_slots[_slots.find(kind)] = EMPTY
	changed.emit()
	return true

func count(kind: Item.Kind) -> int:
	return _counts.get(kind, 0)

func slot_kind(index: int) -> int:
	return _slots[index]

func slot_count(index: int) -> int:
	return 0 if _slots[index] == EMPTY else _counts[_slots[index]]
