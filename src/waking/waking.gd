class_name Waking
extends Node2D
## The beach after the story: fades up from black, he gets himself up, then control and the move hint.
## A thin view over WakeUp; handles no input itself. Esc/Start pause through %Pause once he has control.

const WAKE_CELL := Vector2i(92, 14)     # wet sand at the waterline, under the beach's spawn column
const Preview := preload("res://src/day_night/day_night_preview.gd")
const MOVE_HINT_TOP := 166.0         # %MoveHint's offset_top in waking.tscn
const MOVE_HINT_HEIGHT := 14.0       # its band's height
const SURF_VOLUME := 0.6                # the intro's surf volume, so the cut from the black beat is seamless

var wake := WakeUp.new()
var player: Player
var _last_position := Vector2.ZERO
var resume_data: SaveData = null        # set before the node enters the tree; null means a new game's waking
var enter_story: Callable = _enter_story   # tests replace it

func _ready() -> void:
	player = %Beach.get_node("%Player")
	%Beach.set_day_night(%DayNight)
	if resume_data == null:
		player.control_enabled = false
		player.global_position = BeachLayout.cell_centre(WAKE_CELL)
		(%Beach.get_node("%Camera") as LooseCamera).snap_to_target()
		%Beach.get_node("%Decor").add_child(WaveWash.new())
		_last_position = player.global_position
		wake.control_given.connect(_on_control_given)
	else:
		player.give_control()   # before restore: it resets facing to DOWN
		if not %Beach.restore(resume_data):
			push_error("Waking: the save was refused")
		%DayNight.clock.total_minutes = resume_data.clock_minutes
		wake.resume()
		_last_position = player.global_position
		%DayNight.start()
	%DayNight.time_scale = Preview.parse_args(OS.get_cmdline_user_args()).speed   # --clock-speed=N, a developer speed-up
	_refresh()
	%Autosave.watch(%Beach, %DayNight)
	var builder: Builder = %Beach.get_node("%Builder")
	%Pause.can_pause = func() -> bool:
		return player.control_enabled and wake.cover_alpha() <= 0.0 \
			and builder.mode == Builder.Mode.CLOSED and %Night.collapse == null
	%Pause.has_saved = func() -> bool: return %DayNight.clock.dawns_passed() >= 1
	var debug: DebugMenu = %Pause.debug_menu()
	if debug != null:
		for row in DebugTime.rows(%DayNight):
			debug.add_row(DebugMenu.Page.TIME, row)
		DebugItems.add_rows(debug, %Beach.inventory)
		DebugPlaces.add_rows(debug, go_to_place)
		DebugShow.add_rows(debug)
		DebugShow.attach(self, %Beach, %DayNight)
		DebugSurvival.add_rows(debug, builder.place_now, builder.remove_builds, %Night.collapse_now)
		StoryPoints.add_rows(debug,
				func() -> StoryPoints.Point: return StoryPoints.current(false, %DayNight.clock.total_minutes),
				jump_to_story)
		DebugKeys.attach(self, %DayNight)
	Display.changed.connect(_place_move_hint_later)
	get_tree().root.size_changed.connect(_place_move_hint_later)
	_place_move_hint_later()

## Keeps the move hint at its rest top, lifted above a grown item bar when it would cover it.
func _place_move_hint() -> void:
	HintLift.place(%MoveHint, MOVE_HINT_TOP, MOVE_HINT_HEIGHT)

func _place_move_hint_later() -> void:
	_place_move_hint.call_deferred()

func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	wake.add_walked(player.global_position.distance_to(_last_position))
	_last_position = player.global_position
	wake.advance(delta)
	_refresh()

func _on_control_given() -> void:
	player.give_control()
	_last_position = player.global_position
	%DayNight.start()

## The Debug panel's Story page: fade out, then start the game again at `point`.
func jump_to_story(point: StoryPoints.Point) -> void:
	%Pause.leave(enter_story.bind(point))

func _enter_story(point: StoryPoints.Point) -> void:
	StoryPoints.enter(get_tree(), point)

## Puts him on a named place (the Debug panel's Place page).
func go_to_place(place: DebugPlaces.Place) -> void:
	var builder: Builder = %Beach.get_node("%Builder")
	var has_lean_to := builder.lean_to != null
	var anchor := builder.lean_to.anchor() if has_lean_to else Vector2i.ZERO
	%Beach.put_player(DebugPlaces.cell_for(place, has_lean_to, anchor), DebugPlaces.facing_for(place))
	_last_position = player.global_position

func _refresh() -> void:
	%Cover.modulate.a = wake.cover_alpha()
	var f := wake.fall_frame()
	if f >= 0:
		player.show_frame(Walk.fall_animation_for(player.facing), f)
	%MoveHint.modulate.a = wake.hint_alpha()
	%MoveHint.visible = wake.hint_alpha() > 0.0
	%Surf.set_audible(true)
	%Surf.volume_linear = SURF_VOLUME * (1.0 - wake.cover_alpha())
