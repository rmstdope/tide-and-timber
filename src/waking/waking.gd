class_name Waking
extends Node2D
## The beach after the story: fades up from black, he gets himself up, then control and the move hint.
## A thin view over WakeUp; handles no input, so Esc does nothing.

const WAKE_CELL := Vector2i(92, 14)     # wet sand at the waterline, under the beach's spawn column
const WAKE_SHEET := preload("res://assets/man/man_wake.png")
const Preview := preload("res://src/day_night/day_night_preview.gd")
const SURF_VOLUME := 0.6                # the intro's surf volume, so the cut from the black beat is seamless

var wake := WakeUp.new()
var player: Player
var _last_position := Vector2.ZERO

func _ready() -> void:
	player = %Beach.get_node("%Player")
	%Beach.set_day_night(%DayNight)
	ManFrames.add_waking(player.get_node("%Sprite").sprite_frames, WAKE_SHEET)
	player.control_enabled = false
	player.global_position = BeachLayout.cell_centre(WAKE_CELL)
	(%Beach.get_node("%Camera") as LooseCamera).snap_to_target()
	%Beach.get_node("%Decor").add_child(WaveWash.new())
	_last_position = player.global_position
	wake.control_given.connect(_on_control_given)
	%DayNight.time_scale = Preview.parse_args(OS.get_cmdline_user_args()).speed   # --clock-speed=N, a developer speed-up
	_refresh()
	%Autosave.watch(%Beach, %DayNight)

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

func _refresh() -> void:
	%Cover.modulate.a = wake.cover_alpha()
	if wake.pose() != &"":
		player.play_pose(wake.pose())
	%MoveHint.modulate.a = wake.hint_alpha()
	%MoveHint.visible = wake.hint_alpha() > 0.0
	%Surf.set_audible(true)
	%Surf.volume_linear = SURF_VOLUME * (1.0 - wake.cover_alpha())
