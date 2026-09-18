class_name OverlayScale
extends Node
## Scales its parent CanvasLayer about a screen anchor, in steps that keep every art pixel a
## whole number of screen pixels, and again whenever the window resizes.

const NORMAL := 1.0
const LARGE := 1.5
const LARGEST := 2.0
const ANCHOR_TOP_LEFT := Vector2(0, 0)
const ANCHOR_BOTTOM_CENTRE := Vector2(Screen.CENTRE.x, Screen.HEIGHT)
const ANCHOR_CENTRE := Screen.CENTRE

@export var anchor := ANCHOR_CENTRE
var multiplier := NORMAL:               # setting it re-applies at once
	set(value):
		multiplier = value
		apply()

## The scale that keeps pixels whole: roundf(m * k) / k. k below 1 counts as 1.
static func factor(m: float, k: int) -> float:
	var whole := maxi(1, k)
	return roundf(m * whole) / whole

## The window's whole-number content scale k, read from its final transform; at least 1.
static func whole_scale(window: Window) -> int:
	return maxi(1, roundi(window.get_final_transform().x.x))

## The layer transform that scales by `s` about the point `about` (the picture's units).
static func layer_transform(s: float, about: Vector2) -> Transform2D:
	return Transform2D(0.0, Vector2(s, s), 0.0, about * (1.0 - s))

func _ready() -> void:
	get_tree().root.size_changed.connect(apply)
	apply()

## Sets the parent CanvasLayer's transform from multiplier, anchor and the root window's k.
## Does nothing when not in the tree or when the parent is not a CanvasLayer.
func apply() -> void:
	if not is_inside_tree():
		return
	var layer := get_parent() as CanvasLayer
	if layer == null:
		return
	layer.transform = layer_transform(factor(multiplier, whole_scale(get_tree().root)), anchor)
