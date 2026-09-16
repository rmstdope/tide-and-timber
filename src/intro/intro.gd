class_name Intro
extends Control
## The shipwreck intro: draws an IntroStory and turns input into its moves.

const CAPTIONS := ["Three weeks out of port.", "Then the storm found us.", "The mast gave way.", "..."]
const CAPTION_BAR_Y := 138.0             # on pictures 0..2
const BLACK_BEAT_CAPTION_BAR_Y := 79.0   # vertically centred on the black beat
const SELECTED := Color("#ffd58a")
const UNSELECTED := Color("#fff6e0")

var story := IntroStory.new()
var end_story: Callable = _end_story    # tests replace it; part 2 points it at the beach

func _ready() -> void:
	story.finished.connect(func() -> void: end_story.call())
	_connect_pause_item(%Resume, IntroStory.PauseItem.RESUME)
	_connect_pause_item(%SkipStory, IntroStory.PauseItem.SKIP_STORY)
	_refresh()

func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	story.advance(delta)
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		story.toggle_pause()
	elif story.phase == IntroStory.Phase.PAUSED:
		if event.is_action_pressed("menu_up"):
			story.move_pause_selection(-1)
		elif event.is_action_pressed("menu_down"):
			story.move_pause_selection(1)
		elif event.is_action_pressed("menu_accept"):
			story.choose_pause(story.pause_selected)
		else:
			return
	elif story.phase == IntroStory.Phase.PLAYING:
		if event.is_action_pressed("menu_accept"):
			story.press()
		elif event.is_action_released("menu_accept"):
			story.release()
		else:
			return
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if story.phase != IntroStory.Phase.PLAYING or click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		story.press()
	else:
		story.release()
	_refresh()
	get_viewport().set_input_as_handled()

func _connect_pause_item(item_label: Control, item: IntroStory.PauseItem) -> void:
	item_label.mouse_entered.connect(_on_pause_item_hovered.bind(item))
	item_label.gui_input.connect(_on_pause_item_input.bind(item))

func _on_pause_item_hovered(item: IntroStory.PauseItem) -> void:
	story.hover_pause(item)
	_refresh()

func _on_pause_item_input(event: InputEvent, item: IntroStory.PauseItem) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		story.choose_pause(item)
		_refresh()

func _refresh() -> void:
	var black_beat := story.panel == IntroStory.BLACK_BEAT
	%Picture.picture = story.panel
	%Caption.text = CAPTIONS[story.panel]
	%CaptionBar.position.y = BLACK_BEAT_CAPTION_BAR_Y if black_beat else CAPTION_BAR_Y
	%TapMarker.visible = story.tap_marker_visible()
	%PanelCover.modulate.a = story.panel_cover_alpha()
	%SkipHint.visible = story.skip_hint_shown
	%SkipRing.progress = story.hold_progress
	%SkipCover.modulate.a = story.skip_cover_alpha()
	var paused := story.phase == IntroStory.Phase.PAUSED
	%PauseDim.visible = paused
	%PauseBox.visible = paused
	var resume := story.pause_selected == IntroStory.PauseItem.RESUME
	%Resume.add_theme_color_override("font_color", SELECTED if resume else UNSELECTED)
	%SkipStory.add_theme_color_override("font_color", UNSELECTED if resume else SELECTED)
	%ResumeMarker.visible = resume
	%SkipMarker.visible = not resume

func _end_story() -> void:
	pass # the screen stays black; part 2 points end_story at the beach
