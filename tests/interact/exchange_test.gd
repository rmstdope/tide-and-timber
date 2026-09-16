extends GdUnitTestSuite

const K := Item.Kind

var ex: Exchange
var inv: Inventory

func before_test() -> void:
	ex = auto_free(Exchange.new()) as Exchange
	ex.takes = K.COCONUT
	ex.gives = K.EMPTY_SHELL
	inv = Inventory.new()

func test_cannot_use_without_what_it_takes() -> void:
	assert_bool(ex.can_use(inv)).is_false()
	inv.add(K.EMPTY_SHELL)
	assert_bool(ex.can_use(inv)).is_false()

func test_can_use_with_one() -> void:
	inv.add(K.COCONUT)
	assert_bool(ex.can_use(inv)).is_true()

func test_use_turns_one_into_the_other() -> void:
	inv.add(K.COCONUT, 3)
	ex.use(inv)
	assert_int(inv.count(K.COCONUT)).is_equal(2)
	assert_int(inv.count(K.EMPTY_SHELL)).is_equal(1)

func test_last_one_frees_its_slot_for_the_gift() -> void:
	inv.add(K.DRIFTWOOD)
	inv.add(K.COCONUT)
	inv.add(K.SHELLFISH)
	ex.use(inv)
	assert_int(inv.slot_kind(1)).is_equal(K.EMPTY_SHELL)
	assert_int(inv.slot_kind(2)).is_equal(K.SHELLFISH)
	assert_int(inv.count(K.COCONUT)).is_equal(0)

func test_use_without_one_changes_nothing() -> void:
	inv.add(K.SHELLFISH)
	ex.use(inv)
	assert_int(inv.count(K.EMPTY_SHELL)).is_equal(0)
	assert_int(inv.count(K.SHELLFISH)).is_equal(1)
	assert_int(inv.slot_kind(1)).is_equal(Inventory.EMPTY)

func test_fill_direction() -> void:
	ex.takes = K.EMPTY_SHELL
	ex.gives = K.FRESH_WATER
	inv.add(K.EMPTY_SHELL)
	ex.use(inv)
	assert_int(inv.count(K.FRESH_WATER)).is_equal(1)
	assert_int(inv.count(K.EMPTY_SHELL)).is_equal(0)

func test_gift_is_announced() -> void:
	var seen: Array = []
	inv.added.connect(func(kind: Item.Kind, amount: int) -> void: seen.append([kind, amount]))
	inv.add(K.COCONUT)
	seen.clear()
	ex.use(inv)
	assert_array(seen).is_equal([[K.EMPTY_SHELL, 1]])
