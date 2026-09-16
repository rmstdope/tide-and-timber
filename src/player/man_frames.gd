class_name ManFrames
extends RefCounted
## Builds the man's SpriteFrames from man.png: a still and a walk animation per facing, dry and wading.

const FRAME_SIZE := Vector2i(16, 24)
const WALK_FPS := 8.0
const WALK_COLUMNS: Array[int] = [1, 2, 3, 0]
const WAKE_FRAME_SIZE := Vector2i(24, 24)
const WAKE_POSES: Array[StringName] = [&"lie", &"push_up", &"sit"]   # also the frame order of man_wake.png
const LEGS_HIDDEN := 4                  # px cut from the bottom of each frame while wading

static func build(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for wading: bool in [false, true]:
		for facing: int in Walk.Facing.values():
			var still := Walk.animation_for(facing, false, wading)
			frames.add_animation(still)
			frames.set_animation_loop(still, false)
			frames.set_animation_speed(still, 5.0)
			frames.add_frame(still, _frame(sheet, 0, facing, wading))
			var walk := Walk.animation_for(facing, true, wading)
			frames.add_animation(walk)
			frames.set_animation_loop(walk, true)
			frames.set_animation_speed(walk, WALK_FPS)
			for column in WALK_COLUMNS:
				frames.add_frame(walk, _frame(sheet, column, facing, wading))
	return frames

## Adds his getting-up poses from man_wake.png, one still frame each, beside the walk animations.
static func add_waking(frames: SpriteFrames, sheet: Texture2D) -> void:
	for i in WAKE_POSES.size():
		var pose := WAKE_POSES[i]
		frames.add_animation(pose)
		frames.set_animation_loop(pose, false)
		frames.set_animation_speed(pose, 5.0)
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(Vector2(WAKE_FRAME_SIZE.x * i, 0), Vector2(WAKE_FRAME_SIZE))
		frames.add_frame(pose, texture)

static func _frame(sheet: Texture2D, column: int, row: int, wading := false) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	var hidden := LEGS_HIDDEN if wading else 0
	texture.region = Rect2(FRAME_SIZE.x * column, FRAME_SIZE.y * row, FRAME_SIZE.x, FRAME_SIZE.y - hidden)
	# The margin keeps a leg-less frame 16x24, so he does not bob at the foam line.
	texture.margin = Rect2(0, 0, 0, hidden)
	return texture
