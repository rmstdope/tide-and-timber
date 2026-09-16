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
