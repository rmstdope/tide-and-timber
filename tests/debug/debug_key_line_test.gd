extends GdUnitTestSuite
## The line top-centre that confirms F1-F4.

var line: DebugKeyLine

func before_test() -> void:
	line = auto_free(DebugKeyLine.new())
	add_child(line)
	line.set_process(false)

func test_line_shows_for_one_second() -> void:
	line.show_line("Speed x4")
	assert_str(line.text).is_equal("Speed x4")
	assert_bool(line.visible).is_true()
	line.advance(0.99)
	assert_bool(line.visible).is_true()
	line.advance(0.02)
	assert_str(line.text).is_equal("")
	assert_bool(line.visible).is_false()

func test_a_new_line_replaces_and_restarts() -> void:
	line.show_line("Readout on")
	line.advance(0.8)
	line.show_line("Collision areas on")
	assert_str(line.text).is_equal("Collision areas on")
	line.advance(0.8)
	assert_bool(line.visible).is_true()
	line.advance(0.3)
	assert_bool(line.visible).is_false()

func test_starts_hidden() -> void:
	assert_bool(line.visible).is_false()
	assert_str(line.text).is_equal("")

func test_text_is_centred_in_the_box() -> void:
	assert_vector(DebugKeyLine.text_at("Speed x4")).is_equal(Vector2(145, 10))
	assert_float(DebugKeyLine.text_at("Walk through things off").x).is_greater_equal(DebugKeyLine.BOX.position.x)

func test_attach_builds_the_layer() -> void:
	var owner: Node = auto_free(Node.new())
	add_child(owner)
	var got := DebugKeys.attach(owner, null)
	var layer := owner.get_node("DebugKeyLayer") as CanvasLayer
	assert_object(layer).is_not_null()
	assert_int(layer.layer).is_equal(35)
	assert_int(layer.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	assert_object(owner.get_node("DebugKeyLayer/KeyLine")).is_same(got)
	assert_object(got.day_night).is_null()
