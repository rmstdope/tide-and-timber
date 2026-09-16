class_name CampFire
extends Node2D
## The built fire: lit with a warm glow until its 07:00, then a pile of ash. Not solid.

const LIGHT_RADIUS := 48.0                 # px; the glow fades to nothing exactly here
const LIGHT_OFFSET := Vector2(0, -8)       # the glow's centre: the middle of the fire's cell
const LIGHT_COLOR := Color("#ffc060")
const LIGHT_ENERGY := 0.7

var cell := Vector2i.ZERO
var lit := true
var out_at: float = INF                    # total game minutes; INF = never (no clock)
var glow: PointLight2D

func _ready() -> void:
	glow = PointLight2D.new()
	glow.name = "Glow"
	glow.position = LIGHT_OFFSET
	glow.color = LIGHT_COLOR
	glow.energy = LIGHT_ENERGY
	glow.texture_scale = 1.0
	glow.visible = lit
	glow.texture = _glow_texture()
	add_child(glow)

func light_centre() -> Vector2:
	return global_position + LIGHT_OFFSET

func put_out() -> void:
	lit = false
	if glow:
		glow.visible = false
	queue_redraw()

func _draw() -> void:
	if lit:
		CampArt.draw_fire(self, true, false)
	else:
		CampArt.draw_ash(self)

static func _glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = int(LIGHT_RADIUS * 2)
	tex.height = int(LIGHT_RADIUS * 2)
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	return tex
