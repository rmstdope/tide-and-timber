class_name Player
extends CharacterBody2D
## The man: walks in eight directions, faces four ways, feet at his origin.

const SHEET := preload("res://assets/man/man.png")
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MOVED_EPSILON := 0.05             # px moved in one physics tick that counts as walking

var facing: Walk.Facing = Walk.Facing.DOWN
var moving := false
var control_enabled := true             # false while the waking plays; beach.tscn alone keeps true

func _ready() -> void:
	%Sprite.sprite_frames = ManFrames.build(SHEET)
	_show()

func _physics_process(_delta: float) -> void:
	if not control_enabled:
		return
	var dir := Walk.direction(Input.is_action_pressed(&"move_left"), Input.is_action_pressed(&"move_right"),
		Input.is_action_pressed(&"move_up"), Input.is_action_pressed(&"move_down"))
	velocity = Walk.velocity(dir)
	var before := global_position
	move_and_slide()
	# A blocked walk stands still rather than walking on the spot; a slide still walks.
	moving = global_position.distance_to(before) > MOVED_EPSILON
	facing = Walk.facing_for(dir, facing)
	_show()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		# A key still held when focus returns sends no new press, so he stays stopped until pressed again.
		for action in MOVE_ACTIONS:
			Input.action_release(action)
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
	var anim := Walk.animation_for(facing, moving)
	if %Sprite.animation != anim:
		%Sprite.play(anim)
