class_name Player
extends CharacterBody2D
## The man: walks in eight directions, faces four ways, feet at his origin.

signal trail_mark(kind: StringName, at: Vector2)

const SHEET := preload("res://assets/man/man.png")
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MOVED_EPSILON := 0.05             # px moved in one physics tick that counts as walking
const RUN_ACTION := &"run"

var facing: Walk.Facing = Walk.Facing.DOWN
var moving := false
var control_enabled := true             # false while the waking plays; beach.tscn alone keeps true
var running := false                    # Shift held this tick
var wading := false                     # his feet were on wadeable ground at the start of this tick
var is_wading_at: Callable = func(_at: Vector2) -> bool: return false   # set by the scene that owns the ground
var _trail_clock := 0.0                 # s until the next mark may be emitted
var auto_direction := Vector2.ZERO      # set each tick by a click-walk; used only while no move key is held

func _ready() -> void:
	%Sprite.sprite_frames = ManFrames.build(SHEET)
	_show()

func _physics_process(delta: float) -> void:
	if not control_enabled:
		return
	var dir := Walk.direction(Input.is_action_pressed(&"move_left"), Input.is_action_pressed(&"move_right"),
		Input.is_action_pressed(&"move_up"), Input.is_action_pressed(&"move_down"))
	if dir == Vector2.ZERO:
		dir = auto_direction
	running = Input.is_action_pressed(RUN_ACTION)
	# Sampled before the move: a tick crossing the foam line uses the pace of where it began.
	wading = is_wading_at.call(global_position)
	velocity = Walk.velocity(dir, Walk.speed_for(running, wading))
	var before := global_position
	move_and_slide()
	# A blocked walk stands still rather than walking on the spot; a slide still walks.
	moving = global_position.distance_to(before) > MOVED_EPSILON
	facing = Walk.facing_for(dir, facing)
	_emit_trail(delta, dir)
	_show()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# A key still held when focus returns sends no new press, so he stays stopped until pressed again.
		for action in MOVE_ACTIONS:
			Input.action_release(action)
		Input.action_release(RUN_ACTION)
		velocity = Vector2.ZERO

## Shows one of his poses; only holds while control is off, since walking shows its own.
func play_pose(anim: StringName) -> void:
	if %Sprite.animation != anim:
		%Sprite.play(anim)

## Hands him to the player standing still facing down; a key held until now does not walk him.
func give_control() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	velocity = Vector2.ZERO
	moving = false
	facing = Walk.Facing.DOWN
	control_enabled = true
	_show()

func _show() -> void:
	var anim := Walk.animation_for(facing, moving, wading)
	if %Sprite.animation != anim:
		%Sprite.play(anim)
	%Sprite.speed_scale = Walk.speed_for(running, wading) / Walk.SPEED

func _emit_trail(delta: float, dir: Vector2) -> void:
	var kind := Walk.trail_for(moving, running, wading)
	if kind == &"":
		_trail_clock = 0.0
		return
	_trail_clock -= delta
	if _trail_clock > 0.0:
		return
	_trail_clock = Walk.trail_interval(kind)
	var at := global_position - dir * 4.0 if kind == &"puff" else global_position + Vector2(0, -4)
	trail_mark.emit(kind, at.round())
