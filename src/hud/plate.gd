class_name Plate
extends RefCounted
## The plain two-colour plate every row and every small thing over the world is drawn on, and the
## colour of the words on it. Boards get the knobbed frame; rows never do.

const STYLE: StyleBoxFlat = preload("res://src/title/plank.tres")                  # WOOD_DARK edge, WOOD fill
const CHOSEN_STYLE: StyleBoxFlat = preload("res://src/title/plank_highlight.tres")  # PALE edge, WOOD_LIGHT fill

## CHOSEN_STYLE when chosen, else STYLE.
static func style(chosen: bool) -> StyleBoxFlat:
	return CHOSEN_STYLE if chosen else STYLE

## The words' colour: INK when chosen (chosen wins over dimmed), DIM when dimmed, else CREAM.
static func words(chosen: bool, dimmed := false) -> Color:
	if chosen:
		return HudColours.INK
	return HudColours.DIM if dimmed else HudColours.CREAM

## Styles a row as a plate and colours every Label named "Words" below it, dropping their shadow.
static func paint(plate: Control, chosen: bool, dimmed := false) -> void:
	plate.add_theme_stylebox_override("panel", style(chosen))
	var colour := words(chosen, dimmed)
	for node in plate.find_children("Words", "Label", true, false):
		var label := node as Label
		label.add_theme_color_override("font_color", colour)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
