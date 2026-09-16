extends GdUnitTestSuite

var palm: Node2D
var ground: Node2D
var shake: Shake
var inv: Inventory

func before_test() -> void:
	palm = auto_free(load("res://src/beach/props/palm.tscn").instantiate()) as Node2D
	ground = auto_free(Node2D.new()) as Node2D
	add_child(ground)
	add_child(palm)
	palm.position = Vector2(100, 100)
	shake = palm.get_node("Shake") as Shake
	shake.drop_parent = ground
	inv = Inventory.new()

func _coconuts() -> Array:
	return ground.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("coconut.tscn"))

func test_new_palm_has_coconuts() -> void:
	assert_bool(shake.can_use(inv)).is_true()
	assert_str(shake.verb).is_equal("Shake")
	assert_bool(shake.crown.visible).is_true()

func test_shake_drops_every_coconut_once() -> void:
	shake.use(inv)
	var nuts := _coconuts()
	assert_int(nuts.size()).is_equal(Shake.DROPS.size())
	for i in nuts.size():
		assert_vector((nuts[i] as Node2D).position).is_equal(palm.position + Shake.DROPS[i])
	assert_bool(shake.is_shaken()).is_true()
	assert_bool(shake.can_use(inv)).is_false()
	shake.use(inv)
	assert_int(_coconuts().size()).is_equal(Shake.DROPS.size())

func test_shake_empties_the_crown() -> void:
	shake.use(inv)
	assert_bool(shake.crown.visible).is_false()

func test_shake_gains_nothing() -> void:
	shake.use(inv)
	for i in Inventory.SLOT_COUNT:
		assert_int(inv.slot_kind(i)).is_equal(Inventory.EMPTY)

func test_fallen_coconut_is_a_take() -> void:
	shake.use(inv)
	var pickup := (_coconuts()[0] as Node).get_node("Pickup") as Pickup
	assert_str(pickup.verb).is_equal("Take")
	assert_int(pickup.item).is_equal(Item.Kind.COCONUT)

func test_coconut_lands_on_the_sand() -> void:
	shake.use(inv)
	await await_millis(int(Shake.FALL_TIME * 1000) + 100)
	for c in _coconuts():
		assert_float(((c as Node).get_node("Sprite") as Sprite2D).offset.y).is_equal(-3.0)
