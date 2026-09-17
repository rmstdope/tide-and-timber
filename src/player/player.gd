class_name Player
extends CharacterBody2D
## The man: walks in eight directions, faces four ways, feet at his origin.

signal trail_mark(kind: StringName, at: Vector2)

const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MOVED_EPSILON := 0.05             # px moved in one physics tick that counts as walking
const RUN_ACTION := &"run"
const SOLID_MASK := 1                   # the physics layer of tiles, props and builds (player.tscn, beach_tile_set.gd)
const WALK_THROUGH_MASK := 0            # nothing stops him

var facing: Walk.Facing = Walk.Facing.DOWN
var moving := false
var control_enabled := true             # false while the waking plays; beach.tscn alone keeps true
var running := false                    # Shift held this tick
var wading := false                     # his feet were on wadeable ground at the start of this tick
var is_wading_at: Callable = func(_at: Vector2) -> bool: return false   # set by the scene that owns the ground
var _trail_clock := 0.0                 # s until the next mark may be emitted
var auto_direction := Vector2.ZERO      # set each tick by a click-walk; used only while no move key is held
var collecting := false                 # a one-shot gathering move is playing

func _ready() -> void:
	%Sprite.sprite_frames = ManFrames.build()
	%Sprite.animation_finished.connect(_on_sprite_finished)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_show()

func _physics_process(delta: float) -> void:
	collision_mask = WALK_THROUGH_MASK if DebugSwitches.walk_through else SOLID_MASK
	if not control_enabled:
		return
	var dir := Walk.direction(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down"))
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
		release_held()

## Lets go of every held move and run: a key or stick still held sends no new press, so he stays
## stopped until pressed again. A click-walk in progress is left alone.
func release_held() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
	Input.action_release(RUN_ACTION)
	velocity = Vector2.ZERO

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected:
		release_held()

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
	collecting = false
	_show()

## Plays the gathering move once from where he stands; walking cuts it short. Ignored while control
## is off, so a collapse or the waking keeps the pose it is playing.
func collect() -> void:
	if not control_enabled:
		return
	collecting = true
	%Sprite.play(Walk.collect_animation_for(facing, wading))

## Only the gathering move and the waking poses do not loop, and control is off while those play.
func _on_sprite_finished() -> void:
	collecting = false
	if control_enabled:
		_show()

func _show() -> void:
	%Sprite.speed_scale = Walk.animation_scale(wading)
	if collecting:
		if not moving:
			return
		collecting = false
	var anim := Walk.animation_for(facing, moving, wading, running)
	if %Sprite.animation != anim:
		%Sprite.play(anim)

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
