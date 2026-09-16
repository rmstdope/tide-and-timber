extends GdUnitTestSuite
## What the night takes: half of each kind, rounded down, in bar order; and the card's words.

const K := Item.Kind

func _inv() -> Inventory:
	var inv := Inventory.new()
	inv.add(K.SHELLFISH, 3)
	inv.add(K.DRIFTWOOD, 9)
	inv.add(K.COCONUT, 1)
	inv.add(K.FRESH_WATER, 2)
	return inv

func test_half_of_each_kind_rounded_down_in_bar_order() -> void:
	var expected: Array[Vector2i] = [Vector2i(K.SHELLFISH, 1), Vector2i(K.DRIFTWOOD, 4), Vector2i(K.FRESH_WATER, 1)]
	assert_array(NightLoss.losses(_inv())).is_equal(expected)

func test_apply_leaves_the_rest() -> void:
	var inv := _inv()
	NightLoss.apply(inv, NightLoss.losses(inv))
	assert_int(inv.count(K.SHELLFISH)).is_equal(2)
	assert_int(inv.count(K.DRIFTWOOD)).is_equal(5)
	assert_int(inv.count(K.COCONUT)).is_equal(1)
	assert_int(inv.count(K.FRESH_WATER)).is_equal(1)
	assert_int(inv.slot_kind(0)).is_equal(K.SHELLFISH)

func test_nothing_to_lose() -> void:
	assert_array(NightLoss.losses(Inventory.new())).is_empty()
	var inv := Inventory.new()
	inv.add(K.COCONUT, 1)
	inv.add(K.EMPTY_SHELL, 1)
	assert_array(NightLoss.losses(inv)).is_empty()

func test_big_counts() -> void:
	var inv := Inventory.new()
	inv.add(K.DRIFTWOOD, 301)
	var expected: Array[Vector2i] = [Vector2i(K.DRIFTWOOD, 150)]
	assert_array(NightLoss.losses(inv)).is_equal(expected)

func test_card_lines_with_losses() -> void:
	var taken: Array[Vector2i] = [Vector2i(K.DRIFTWOOD, 4), Vector2i(K.SHELLFISH, 1), Vector2i(K.EMPTY_SHELL, 2), Vector2i(K.FRESH_WATER, 1)]
	assert_array(NightLoss.card_lines(2, taken)).is_equal(
		["DAY 2", "The night took:", "4 Driftwood", "1 Shellfish", "2 Empty shell", "1 Fresh water"])

func test_card_lines_nothing_lost() -> void:
	var none: Array[Vector2i] = []
	assert_array(NightLoss.card_lines(3, none)).is_equal(["DAY 3", "I made it through."])
