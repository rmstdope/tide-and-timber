class_name Player
extends CharacterBody2D
## The man: walks in eight directions, faces four ways, feet at his origin.

const SHEET := preload("res://assets/man/man.png")
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const MOVED_EPSILON := 0.05             # px moved in one physics tick that counts as walking

var facing: Walk.Facing = Walk.Facing.DOWN
var moving := false

func _ready() -> void:
	%Sprite.sprite_frames = ManFrames.build(SHEET)
	_show()

func _show() -> void:
	var anim := Walk.animation_for(facing, moving)
	if %Sprite.animation != anim:
		%Sprite.play(anim)
