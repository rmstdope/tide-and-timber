class_name HudFrame
extends RefCounted
## The shared knobbed wooden frame a board is drawn with, and how deep its rim is.
## Scenes point their Panel at res://src/hud/frame.tres; code draws STYLE and keeps what a board holds RIM inside its edge.

const STYLE := preload("res://src/hud/frame.tres")
const RIM := 6.0   ## frame.tres's texture margin on every side: nothing a board holds is drawn nearer its edge
