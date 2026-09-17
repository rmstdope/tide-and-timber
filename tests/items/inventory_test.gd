extends GdUnitTestSuite

const K := Item.Kind

func _kinds(inv: Inventory) -> Array:
	var out := []
	for i in Inventory.SLOT_COUNT:
		out.append(inv.slot_kind(i))
	return out

func test_new_is_empty() -> void:
	var inv := Inventory.new()
	for i in Inventory.SLOT_COUNT:
		assert_int(inv.slot_kind(i)).is_equal(Inventory.EMPTY)
		assert_int(inv.slot_count(i)).is_equal(0)
	for kind: int in K.values():
		assert_int(inv.count(kind)).is_equal(0)

func test_add_fills_first_empty_slot_in_order_gained() -> void:
	var inv := Inventory.new()
	inv.add(K.SHELLFISH)
	inv.add(K.DRIFTWOOD)
	assert_int(inv.slot_kind(0)).is_equal(K.SHELLFISH)
	assert_int(inv.slot_kind(1)).is_equal(K.DRIFTWOOD)
	assert_int(inv.slot_kind(2)).is_equal(Inventory.EMPTY)

func test_same_kind_stacks_without_limit() -> void:
	var inv := Inventory.new()
	for i in 150:
		inv.add(K.DRIFTWOOD)
	assert_int(inv.slot_count(0)).is_equal(150)
	assert_int(inv.slot_kind(1)).is_equal(Inventory.EMPTY)

func _three() -> Inventory:
	var inv := Inventory.new()
	inv.add(K.DRIFTWOOD)
	inv.add(K.SHELLFISH)
	inv.add(K.COCONUT)
	return inv

func test_remove_to_zero_empties_slot_others_stay() -> void:
	var inv := _three()
	assert_bool(inv.remove(K.SHELLFISH)).is_true()
	assert_int(inv.slot_kind(1)).is_equal(Inventory.EMPTY)
	assert_int(inv.slot_kind(2)).is_equal(K.COCONUT)
	assert_int(inv.count(K.SHELLFISH)).is_equal(0)

func test_next_new_kind_takes_first_empty_slot() -> void:
	var inv := _three()
	inv.remove(K.SHELLFISH)
	inv.add(K.EMPTY_SHELL)
	assert_int(inv.slot_kind(1)).is_equal(K.EMPTY_SHELL)
	assert_array(_kinds(inv).slice(0, 4)).is_equal([K.DRIFTWOOD, K.EMPTY_SHELL, K.COCONUT, Inventory.EMPTY])

func test_remove_more_than_carried_fails_unchanged() -> void:
	var inv := Inventory.new()
	inv.add(K.DRIFTWOOD)
	assert_bool(inv.remove(K.DRIFTWOOD, 2)).is_false()
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(1)
	assert_bool(inv.remove(K.COCONUT)).is_false()

func test_signals() -> void:
	var inv := Inventory.new()
	var changes := []
	var adds := []
	inv.changed.connect(func() -> void: changes.append(true))
	inv.added.connect(func(kind: int, amount: int) -> void: adds.append([kind, amount]))
	inv.add(K.SHELLFISH)
	assert_int(changes.size()).is_equal(1)
	assert_array(adds).is_equal([[K.SHELLFISH, 1]])
	assert_bool(inv.remove(K.COCONUT)).is_false()
	assert_int(changes.size()).is_equal(1)
	assert_bool(inv.remove(K.SHELLFISH)).is_true()
	assert_int(changes.size()).is_equal(2)
	assert_int(adds.size()).is_equal(1)

func _slots_of(inv: Inventory) -> Array:
	var out := []
	for i in Inventory.SLOT_COUNT:
		out.append([inv.slot_kind(i), inv.slot_count(i)])
	return out

func test_to_slots_keeps_slot_order() -> void:
	var inv := _three()
	inv.remove(K.SHELLFISH)
	var expected: Array[Dictionary] = [{"kind": K.DRIFTWOOD, "count": 1}, {}, {"kind": K.COCONUT, "count": 1}, {}, {}, {}, {}, {}]
	assert_array(inv.to_slots()).is_equal(expected)

func test_restore_round_trips_into_a_new_inventory() -> void:
	var a := _three()
	a.add(K.COCONUT, 4)
	a.remove(K.SHELLFISH)
	var b := Inventory.new()
	assert_bool(b.restore(a.to_slots())).is_true()
	assert_array(_slots_of(b)).is_equal(_slots_of(a))
	assert_int(b.count(K.COCONUT)).is_equal(5)
	b.add(K.FRESH_WATER)
	assert_int(b.slot_kind(1)).is_equal(K.FRESH_WATER)

func test_restore_emits_changed_once_and_never_added() -> void:
	var inv := Inventory.new()
	var seen := {"changed": 0, "added": 0}
	inv.changed.connect(func() -> void: seen["changed"] += 1)
	inv.added.connect(func(_k: Item.Kind, _a: int) -> void: seen["added"] += 1)
	inv.restore(_three().to_slots())
	assert_int(seen["changed"]).is_equal(1)
	assert_int(seen["added"]).is_equal(0)

func test_restore_refuses_bad_shapes_unchanged() -> void:
	var inv := _three()
	var before := _slots_of(inv)
	var seven: Array[Dictionary] = [{}, {}, {}, {}, {}, {}, {}]
	var bad_kind: Array[Dictionary] = [{"kind": 99, "count": 1}, {}, {}, {}, {}, {}, {}, {}]
	var zero: Array[Dictionary] = [{"kind": K.DRIFTWOOD, "count": 0}, {}, {}, {}, {}, {}, {}, {}]
	var twice: Array[Dictionary] = [{"kind": K.DRIFTWOOD, "count": 1}, {"kind": K.DRIFTWOOD, "count": 2}, {}, {}, {}, {}, {}, {}]
	for bad: Array[Dictionary] in [seven, bad_kind, zero, twice]:
		assert_bool(inv.restore(bad)).is_false()
		assert_array(_slots_of(inv)).is_equal(before)

func _counter(sig: Signal) -> Array[int]:
	var n: Array[int] = [0]
	sig.connect(func(_a: Variant = null, _b: Variant = null) -> void: n[0] += 1)
	return n

func test_set_count_up_from_nothing_takes_first_empty_slot() -> void:
	var inv := Inventory.new()
	inv.add(K.SHELLFISH)
	assert_bool(inv.set_count(K.DRIFTWOOD, 5)).is_true()
	assert_int(inv.slot_kind(1)).is_equal(K.DRIFTWOOD)
	assert_int(inv.slot_count(1)).is_equal(5)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(5)

func test_set_count_changes_a_carried_count_in_place() -> void:
	var inv := Inventory.new()
	inv.add(K.DRIFTWOOD)
	inv.add(K.SHELLFISH)
	assert_bool(inv.set_count(K.DRIFTWOOD, 3)).is_true()
	assert_int(inv.slot_kind(0)).is_equal(K.DRIFTWOOD)
	assert_int(inv.slot_count(0)).is_equal(3)

func test_set_count_zero_frees_the_slot() -> void:
	var inv := Inventory.new()
	inv.add(K.DRIFTWOOD, 2)
	assert_bool(inv.set_count(K.DRIFTWOOD, 0)).is_true()
	assert_int(inv.slot_kind(0)).is_equal(Inventory.EMPTY)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(0)

func test_set_count_emits_changed_once_and_never_added() -> void:
	var inv := Inventory.new()
	var changed := _counter(inv.changed)
	var added := _counter(inv.added)
	inv.set_count(K.COCONUT, 4)
	assert_int(changed[0]).is_equal(1)
	assert_int(added[0]).is_equal(0)
	inv.set_count(K.COCONUT, 4)
	assert_int(changed[0]).is_equal(1)
	inv.set_count(K.COCONUT, 0)
	assert_int(changed[0]).is_equal(2)
	assert_int(added[0]).is_equal(0)

func test_set_count_negative_is_refused() -> void:
	var inv := Inventory.new()
	var changed := _counter(inv.changed)
	assert_bool(inv.set_count(K.COCONUT, -1)).is_false()
	assert_int(inv.count(K.COCONUT)).is_equal(0)
	assert_int(changed[0]).is_equal(0)

func test_clear_empties_every_slot_and_emits_changed_once() -> void:
	var inv := _three()
	var changed := _counter(inv.changed)
	var added := _counter(inv.added)
	inv.clear()
	for i in Inventory.SLOT_COUNT:
		assert_int(inv.slot_kind(i)).is_equal(Inventory.EMPTY)
	for kind: K in K.values():
		assert_int(inv.count(kind)).is_equal(0)
	assert_int(changed[0]).is_equal(1)
	assert_int(added[0]).is_equal(0)

func test_clear_on_an_empty_bag_emits_nothing() -> void:
	var inv := Inventory.new()
	var changed := _counter(inv.changed)
	inv.clear()
	assert_int(changed[0]).is_equal(0)
