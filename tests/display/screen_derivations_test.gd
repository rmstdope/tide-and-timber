extends GdUnitTestSuite

# Every screen-space constant that is derived from an edge or a centre, asserted as the expression
# and never as a number, so these hold at any picture size (tr-1o0.1).

func test_the_item_bar_sits_23_above_the_bottom() -> void:
	assert_float(ItemBar.TOP).is_equal(Screen.HEIGHT - 23.0)

func test_the_hint_strip_sits_4_above_the_bottom() -> void:
	assert_float(MenuStrip.BOTTOM).is_equal(Screen.HEIGHT - 4.0)

func test_the_key_hint_sits_44_above_the_bottom() -> void:
	assert_float(KeyHint.TOP).is_equal(Screen.HEIGHT - 44.0)

func test_the_move_hint_sits_14_above_the_bottom() -> void:
	assert_float(Waking.MOVE_HINT_TOP).is_equal(Screen.HEIGHT - 14.0)

func test_the_settings_board_is_centred() -> void:
	assert_float(SettingsBoard.BOARD_X).is_equal((Screen.WIDTH - SettingsBoard.BOARD_W) / 2.0)

func test_the_controls_list_is_centred() -> void:
	assert_float(ControlsPage.LIST_X).is_equal((Screen.WIDTH - ControlsPage.LIST_W) / 2.0)
	var xs: Array = ControlsPage.SLOT_XS_STACKED
	assert_float((xs[0] + xs[1] + ControlsPage.SLOT_W) / 2.0).is_equal(Screen.CENTRE.x)

func test_the_debug_panel_is_flush_right() -> void:
	assert_float(DebugPanel.PANEL_RECT.end.x).is_equal(Screen.WIDTH)

func test_the_debug_readout_is_4_clear_of_the_right_edge() -> void:
	assert_float(DebugReadout.BOX_X + DebugReadout.BOX_W).is_equal(Screen.WIDTH - 4.0)

func test_the_debug_key_line_is_centred() -> void:
	assert_float(DebugKeyLine.BOX.get_center().x).is_equal(Screen.CENTRE.x)

func test_the_overlay_anchors_follow_the_picture() -> void:
	assert_vector(OverlayScale.ANCHOR_CENTRE).is_equal(Screen.CENTRE)
	assert_vector(OverlayScale.ANCHOR_BOTTOM_CENTRE).is_equal(Vector2(Screen.CENTRE.x, Screen.HEIGHT))

func test_the_caption_bar_sits_42_above_the_bottom() -> void:
	assert_float(Intro.CAPTION_BAR_Y).is_equal(Screen.HEIGHT - 42.0)

func test_text_fits_the_picture() -> void:
	assert_float(TextScale.fit_width(10.0, 10.0 + Screen.WIDTH, 1.0)) 			.is_equal(Screen.WIDTH - 2.0 * SpokenLine.SCREEN_MARGIN)


func test_the_controls_block_is_centred() -> void:
	var above := ControlsPage.CONTENT_TOP
	var below := Screen.HEIGHT - ControlsLayout.make(false, 1.0, 1.0).content_bottom()
	assert_float(absf(above - below)).is_less_equal(1.0)
