class_name ManFrames
extends RefCounted
## Builds the man's SpriteFrames from man.png: a still and a walk animation per facing.

const FRAME_SIZE := Vector2i(16, 24)
const WALK_FPS := 8.0
const WALK_COLUMNS: Array[int] = [1, 2, 3, 0]

static func build(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for facing: int in Walk.Facing.values():
		var still := Walk.animation_for(facing, false)
		frames.add_animation(still)
		frames.set_animation_loop(still, false)
		frames.set_animation_speed(still, 5.0)
		frames.add_frame(still, _frame(sheet, 0, facing))
		var walk := Walk.animation_for(facing, true)
		frames.add_animation(walk)
		frames.set_animation_loop(walk, true)
		frames.set_animation_speed(walk, WALK_FPS)
		for column in WALK_COLUMNS:
			frames.add_frame(walk, _frame(sheet, column, facing))
	return frames

static func _frame(sheet: Texture2D, column: int, row: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(Vector2(FRAME_SIZE.x * column, FRAME_SIZE.y * row), Vector2(FRAME_SIZE))
	return texture
