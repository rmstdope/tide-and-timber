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

## Slot by slot, SLOT_COUNT entries: {} for an empty slot, else {"kind": Item.Kind, "count": int}.
func to_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in SLOT_COUNT:
		out.append({} if _slots[i] == EMPTY else {"kind": _slots[i], "count": _counts[_slots[i]]})
	return out

## Replaces everything carried with `slots` (the shape to_slots returns) and returns true.
## Returns false and changes nothing when the shape is wrong: not exactly SLOT_COUNT entries,
## a kind not in Item.Kind, a count < 1, or one kind in two slots.
## Emits `changed` once on success and never `added`, so no "+1" line rises on a load.
func restore(slots: Array[Dictionary]) -> bool:
	if slots.size() != SLOT_COUNT:
		return false
	var seen := {}
	for slot in slots:
		if slot.is_empty():
			continue
		var kind: Variant = slot.get("kind")
		var amount: Variant = slot.get("count")
		if typeof(kind) != TYPE_INT or not Item.Kind.values().has(kind) or seen.has(kind):
			return false
		if typeof(amount) != TYPE_INT or amount < 1:
			return false
		seen[kind] = true
	_slots.fill(EMPTY)
	_counts.clear()
	for i in SLOT_COUNT:
		if not slots[i].is_empty():
			_slots[i] = slots[i]["kind"]
			_counts[slots[i]["kind"]] = slots[i]["count"]
	changed.emit()
	return true
