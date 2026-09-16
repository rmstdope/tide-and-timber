class_name Frost
extends TextureRect
## Frost growing in from the screen edges: clear in the middle, icy at the rim.

const ICE := Color("#cfe6ff")
const CLEAR_TO := 0.55        # the gradient is clear out to this fraction of the radius
const MAX_ALPHA := 0.9

static func build_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([CLEAR_TO, 1.0])
	g.colors = PackedColorArray([Color(ICE, 0.0), Color(ICE, 1.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 320
	t.height = 180
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func _ready() -> void:
	texture = build_texture()
	position = Vector2.ZERO
	size = Vector2(320, 180)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	mouse_filter = MOUSE_FILTER_IGNORE
	set_amount(0.0)

func set_amount(amount: float) -> void:
	modulate.a = clampf(amount, 0.0, 1.0) * MAX_ALPHA
	visible = amount > 0.0
