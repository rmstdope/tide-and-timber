class_name ManFrames
extends RefCounted
## Builds the man's SpriteFrames from the sheets under assets/man/: idle, walk, run, the gathering
## move and the fall, one row per facing, dry and wading.

const FRAME_SIZE := Vector2i(64, 64)
const FOOTLINE := 48                    # rows at and below this in a frame are always empty
const LEGS_HIDDEN := 4                  # px of him cut at the foam line
const IDLE_FPS := 6.0
const WALK_FPS := 12.0
const RUN_FPS := 16.0
const COLLECT_FPS := 12.0
## 8 frames over Collapse.FALL_SECONDS. Nothing plays the fall whole: the collapse and the waking
## set its frame themselves, forwards and then backwards.
const DEATH_FPS := 4.0

const IDLE_SHEET := preload("res://assets/man/idle.png")
const WALK_SHEET := preload("res://assets/man/walk.png")
const RUN_SHEET := preload("res://assets/man/run.png")
const COLLECT_SHEET := preload("res://assets/man/collect.png")
const DEATH_SHEET := preload("res://assets/man/death.png")

static func build() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for wading: bool in [false, true]:
		for facing: int in Walk.Facing.values():
			_add(frames, Walk.animation_for(facing, false, wading), IDLE_SHEET, 4, true, IDLE_FPS,
				facing, wading)
			_add(frames, Walk.animation_for(facing, true, wading), WALK_SHEET, 6, true, WALK_FPS,
				facing, wading)
			_add(frames, Walk.collect_animation_for(facing, wading), COLLECT_SHEET, 8, false,
				COLLECT_FPS, facing, wading)
			# No wade_run_*: wading is one pace whether Shift is held, so he shows the wading walk.
			# No wade_death_* either: he keeps his legs if he goes down in the shallows.
			if not wading:
				_add(frames, Walk.animation_for(facing, true, false, true), RUN_SHEET, 6, true,
					RUN_FPS, facing, false)
				_add(frames, Walk.fall_animation_for(facing), DEATH_SHEET, WakeUp.FALL_FRAMES, false,
					DEATH_FPS, facing, false)
	return frames

static func _add(frames: SpriteFrames, anim: StringName, sheet: Texture2D, columns: int, loop: bool,
		fps: float, facing: int, wading: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	for column in columns:
		frames.add_frame(anim, _frame(sheet, column, facing, wading))

static func _frame(sheet: Texture2D, column: int, row: int, wading := false) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	# Wading cuts him at the foam line: the empty rows below his feet, and LEGS_HIDDEN px of him.
	var hidden := FRAME_SIZE.y - FOOTLINE + LEGS_HIDDEN if wading else 0
	texture.region = Rect2(FRAME_SIZE.x * column, FRAME_SIZE.y * row, FRAME_SIZE.x,
		FRAME_SIZE.y - hidden)
	# The margin keeps a leg-less frame 64x64, so he does not bob at the foam line.
	texture.margin = Rect2(0, 0, 0, hidden)
	return texture
