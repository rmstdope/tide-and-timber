extends GdUnitTestSuite

const SIZES := {
	"res://assets/beach/tiles.png": Vector2i(112, 16),
	"res://assets/beach/rock.png": Vector2i(16, 16),
	"res://assets/beach/boulder.png": Vector2i(32, 32),
	"res://assets/beach/palm.png": Vector2i(32, 48),
	"res://assets/beach/driftwood.png": Vector2i(32, 8),
	"res://assets/man/man.png": Vector2i(64, 96),
}

func test_art_sizes() -> void:
	for path: String in SIZES:
		var texture := load(path) as Texture2D
		assert_object(texture).override_failure_message("%s did not load" % path).is_not_null()
		if texture:
			assert_vector(Vector2(texture.get_size())).override_failure_message(path).is_equal(Vector2(SIZES[path]))
