class_name Intro
extends Control
## The shipwreck intro: draws an IntroStory and turns input into its moves.

const CAPTIONS := ["Three weeks out of port.", "Then the storm found us.", "The mast gave way.", "..."]
const CAPTION_BAR_Y := 138.0             # on pictures 0..2
const BLACK_BEAT_CAPTION_BAR_Y := 79.0   # vertically centred on the black beat
const SURF_VOLUME := 0.6
const WAKING_SCENE := "res://src/waking/waking.tscn"

var story := IntroStory.new()
var end_story: Callable = _end_story    # tests replace it; it ends on the beach waking

func _ready() -> void:
	story.finished.connect(func() -> void: end_story.call())
	%Pause.can_pause = func() -> bool: return story.phase == IntroStory.Phase.PLAYING
	%Pause.opened.connect(func() -> void:
		story.toggle_pause()
		_refresh())
	%Pause.resumed.connect(func() -> void:
		story.toggle_pause()
		_refresh())
	%Pause.skip_story_chosen.connect(func() -> void:
		story.skip()
		_refresh())
	_refresh()
	var debug: DebugMenu = %Pause.debug_menu()
	if debug != null:
		DebugItems.add_rows(debug, Inventory.new())   # the story has no bag: every item at 0
		DebugPlaces.add_rows(debug, Callable())

func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	story.advance(delta)
	_refresh()

# _shortcut_input, not _unhandled_input: it gets keys and pad buttons, and gdUnit4 delivers it once.
func _shortcut_input(event: InputEvent) -> void:
	if story.phase == IntroStory.Phase.PLAYING:
		if event.is_action_pressed("menu_accept") or InputDevice.action_pressed(event, "use"):
			story.press()
		elif event.is_action_released("menu_accept") or InputDevice.action_released(event, "use"):
			story.release()
		else:
			return
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:   # _shortcut_input never gets motion: a stick-bound Use comes here
		_shortcut_input(event)
		return
	var click := event as InputEventMouseButton
	if story.phase != IntroStory.Phase.PLAYING or click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		story.press()
	else:
		story.release()
	_refresh()
	get_viewport().set_input_as_handled()

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
	%Surf.set_audible(story.surf_audible())
	%Surf.volume_linear = SURF_VOLUME * (1.0 - story.skip_cover_alpha())

func _end_story() -> void:
	get_tree().change_scene_to_file(WAKING_SCENE)
