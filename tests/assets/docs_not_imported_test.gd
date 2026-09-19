extends GdUnitTestSuite

# docs/ holds mockups with pictures cut from the vendored packs. Godot must not import them:
# an imported picture ships in the game, and leaves an untracked .import in every checkout.


func test_docs_is_hidden_from_godot() -> void:
	assert_bool(FileAccess.file_exists("res://docs/.gdignore")).is_true()


func test_a_picture_under_docs_is_not_a_resource() -> void:
	assert_bool(FileAccess.file_exists("res://docs/ui/vendor-art-swap/waves_warm.png")).is_true()
	assert_bool(ResourceLoader.exists("res://docs/ui/vendor-art-swap/waves_warm.png")).is_false()
