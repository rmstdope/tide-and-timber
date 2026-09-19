extends GdUnitTestSuite

# third_party/ holds development-only material under other licences. Godot must never import or
# export it: anything Godot sees there could ship in the game.


func test_third_party_is_hidden_from_godot() -> void:
	assert_bool(FileAccess.file_exists("res://third_party/.gdignore")).is_true()
