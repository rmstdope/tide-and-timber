extends GdUnitTestSuite

const PALM := "res://src/beach/props/palm.tscn"
const SHELLFISH := "res://src/beach/props/shellfish.tscn"
## Per shape: Sprite region, Sprite offset, Crown position, Crown offset.
const PALM_TABLE := [
	[Rect2(22, 16, 31, 56), Vector2(-16, -52), Vector2(0, -32), Vector2(-16, -20)],
	[Rect2(69, 18, 36, 54), Vector2(-18, -50), Vector2(0, -32), Vector2(-18, -18)],
	[Rect2(22, 83, 34, 53), Vector2(-16, -49), Vector2(0, -30), Vector2(-16, -19)],
	[Rect2(71, 82, 33, 54), Vector2(-18, -50), Vector2(0, -30), Vector2(-18, -20)],
	[Rect2(115, 87, 37, 50), Vector2(-20, -46), Vector2(0, -32), Vector2(-20, -14)],
	[Rect2(112, 25, 64, 48), Vector2(-60, -44), Vector2(-35, -26), Vector2(-25, -18)],
]
const GRASS := "res://src/beach/props/beach_grass.tscn"
const SEA_ROCK := "res://src/beach/props/sea_rock.tscn"
const GRASS_OFFSETS: Array[Vector2] = [Vector2(-7, -17), Vector2(-7, -20), Vector2(-6, -17), Vector2(-5, -15)]
const SEA_ROCK_OFFSETS: Array[Vector2] = [Vector2(-13, -19), Vector2(-16, -14), Vector2(-7, -15)]
const SEA_ROCK_BASES: Array[Vector2] = [Vector2(23, 8), Vector2(28, 8), Vector2(12, 8)]
const SHELL_OFFSETS: Array[Vector2] = [Vector2(-5, -13), Vector2(-7, -12), Vector2(-6, -14), Vector2(-5, -13)]

func _new(path: String) -> Node2D:
	return auto_free((load(path) as PackedScene).instantiate()) as Node2D

func test_dress_palm_sets_each_shape() -> void:
	for i in 6:
		var palm := _new(PALM)
		BeachArt.dress_palm(palm, i)
		var sprite := palm.get_node("Sprite") as Sprite2D
		var crown := palm.get_node("Crown") as Sprite2D
		var st := sprite.texture as AtlasTexture
		var ct := crown.texture as AtlasTexture
		assert_str(st.atlas.resource_path).is_equal("res://assets/beach/palms.png")
		assert_bool(st.region == PALM_TABLE[i][0]).override_failure_message("shape %d region %s" % [i, st.region]).is_true()
		assert_vector(sprite.offset).is_equal(PALM_TABLE[i][1])
		assert_vector(crown.position).is_equal(PALM_TABLE[i][2])
		assert_vector(crown.offset).is_equal(PALM_TABLE[i][3])
		assert_str(ct.atlas.resource_path).is_equal("res://assets/beach/palm_crowns.png")
		assert_bool(ct.region == Rect2(BeachArt.PALM_SHAPES[i])).is_true()
		assert_bool(sprite.centered).is_false()
		assert_bool(crown.centered).is_false()

func test_dress_palm_leaves_other_palms_alone() -> void:
	var a := _new(PALM)
	var b := _new(PALM)
	BeachArt.dress_palm(a, 5)
	assert_bool(((b.get_node("Sprite") as Sprite2D).texture as AtlasTexture).region == Rect2(22, 16, 31, 56)).is_true()

func test_dress_palm_keeps_base_and_shake() -> void:
	var palm := _new(PALM)
	BeachArt.dress_palm(palm, 5)
	var base := palm.get_node("Base") as CollisionShape2D
	assert_vector(base.position).is_equal(Vector2(0, -3))
	assert_vector((base.shape as RectangleShape2D).size).is_equal(Vector2(6, 6))
	assert_vector((palm.get_node("Shake") as Shake).prompt_offset).is_equal(Vector2(0, -48))

func test_dress_shellfish_sets_each_shell() -> void:
	for i in 4:
		var shell := _new(SHELLFISH)
		BeachArt.dress_shellfish(shell, i)
		var sprite := shell.get_node("Sprite") as Sprite2D
		var t := sprite.texture as AtlasTexture
		assert_str(t.atlas.resource_path).is_equal("res://assets/farming_101/beach/seashells.png")
		assert_bool(t.region == Rect2(BeachArt.SHELL_SHAPES[i])).is_true()
		assert_vector(sprite.offset).is_equal(SHELL_OFFSETS[i])
		assert_bool(sprite.centered).is_false()

func test_offsets_are_whole_pixels() -> void:
	assert_vector(BeachArt.centre_offset(Vector2i(11, 12), -1)).is_equal(Vector2(-5, -13))
	assert_vector(BeachArt.foot_offset(Vector2i(64, 48), 60, 4)).is_equal(Vector2(-60, -44))

func test_dress_grass_sets_each_look() -> void:
	for i in 4:
		var grass := _new(GRASS)
		BeachArt.dress_grass(grass, i)
		var sprite := grass.get_node("Sprite") as Sprite2D
		var t := sprite.texture as AtlasTexture
		assert_str(t.atlas.resource_path).is_equal("res://assets/farming_101/beach/beach grass.png")
		assert_bool(t.region == Rect2(BeachArt.GRASS_SHAPES[i])).override_failure_message("grass %d region %s" % [i, t.region]).is_true()
		assert_vector(sprite.offset).is_equal(GRASS_OFFSETS[i])
		assert_bool(sprite.centered).is_false()

func test_dress_sea_rock_sets_look_and_base() -> void:
	for i in 3:
		var rock := _new(SEA_ROCK)
		BeachArt.dress_sea_rock(rock, i)
		var sprite := rock.get_node("Sprite") as Sprite2D
		var t := sprite.texture as AtlasTexture
		assert_str(t.atlas.resource_path).is_equal("res://assets/farming_101/beach/ocean rocks.png")
		assert_bool(t.region == Rect2(BeachArt.SEA_ROCK_SHAPES[i])).override_failure_message("rock %d region %s" % [i, t.region]).is_true()
		assert_vector(sprite.offset).is_equal(SEA_ROCK_OFFSETS[i])
		assert_bool(sprite.centered).is_false()
		var base := rock.get_node("Base") as CollisionShape2D
		assert_vector((base.shape as RectangleShape2D).size).is_equal(SEA_ROCK_BASES[i])
		assert_vector(base.position).is_equal(Vector2(0, -4))

func test_dress_sea_rock_leaves_other_rocks_alone() -> void:
	var a := _new(SEA_ROCK)
	var b := _new(SEA_ROCK)
	BeachArt.dress_sea_rock(a, 1)
	assert_bool(((b.get_node("Sprite") as Sprite2D).texture as AtlasTexture).region == Rect2(3, 7, 27, 19)).is_true()
	assert_vector(((b.get_node("Base") as CollisionShape2D).shape as RectangleShape2D).size).is_equal(Vector2(23, 8))
