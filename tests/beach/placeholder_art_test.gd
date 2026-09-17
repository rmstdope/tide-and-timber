extends GdUnitTestSuite

const SIZES := {
	"res://assets/beach/tiles.png": Vector2i(112, 16),
	"res://assets/beach/palm.png": Vector2i(32, 48),
	"res://assets/beach/driftwood.png": Vector2i(32, 8),
	"res://assets/beach/puff.png": Vector2i(4, 4),
	"res://assets/beach/ripple.png": Vector2i(12, 4),
	"res://assets/beach/shellfish.png": Vector2i(12, 6),
	"res://assets/items/driftwood.png": Vector2i(10, 10),
	"res://assets/items/shellfish.png": Vector2i(10, 10),
	"res://assets/items/coconut.png": Vector2i(10, 10),
	"res://assets/items/empty_shell.png": Vector2i(10, 10),
	"res://assets/items/fresh_water.png": Vector2i(10, 10),
	"res://assets/beach/palm_coconuts.png": Vector2i(10, 4),
	"res://assets/beach/coconut.png": Vector2i(6, 6),
	"res://assets/beach/spring.png": Vector2i(32, 24),
	"res://assets/hud/glyphs.png": Vector2i(348, 5),
}

func test_art_sizes() -> void:
	for path: String in SIZES:
		var texture := load(path) as Texture2D
		assert_object(texture).override_failure_message("%s did not load" % path).is_not_null()
		if texture:
			assert_vector(Vector2(texture.get_size())).override_failure_message(path).is_equal(Vector2(SIZES[path]))

func test_wake_art_size() -> void:
	var texture := load("res://assets/man/man_wake.png") as Texture2D
	assert_object(texture).is_not_null()
	if texture:
		assert_vector(Vector2(texture.get_size())).is_equal(Vector2(192, 64))
