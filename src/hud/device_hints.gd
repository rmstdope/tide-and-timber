class_name DeviceHints
extends RefCounted
## What each hint says on each device: pictures and words, no drawing.

enum Hint { MOVE, USE, BUILD_LIST, PLACING }
enum Slot { MOVE, BOTTOM, RIGHT }
enum Shape { KEY, ROUND, STICK }

const CAP_FACE := Color("#f4e3c1")
const CAP_INK := Color("#3a2414")
const PAD_FACE := Color("#3a3a44")
const WHITE := Color("#ffffff")

class Picture:
	var shape: Shape
	var label: String   # drawn with Glyphs
	var face: Color
	var ink: Color

	func _init(p_shape: Shape, p_label: String, p_face: Color, p_ink: Color) -> void:
		shape = p_shape
		label = p_label
		face = p_face
		ink = p_ink

## The pictures for a slot on a device, left to right.
static func pictures(kind: DeviceTracker.Kind, slot: Slot) -> Array[Picture]:
	var result: Array[Picture] = []
	if kind == DeviceTracker.Kind.KEYBOARD:
		var labels: Array = {Slot.MOVE: ["W", "A", "S", "D"], Slot.BOTTOM: ["E"], Slot.RIGHT: ["Esc"]}[slot]
		for label: String in labels:
			result.append(Picture.new(Shape.KEY, label, CAP_FACE, CAP_INK))
		return result
	if slot == Slot.MOVE:
		result.append(Picture.new(Shape.STICK, "L", PAD_FACE, WHITE))
		return result
	var bottom := slot == Slot.BOTTOM
	match kind:
		DeviceTracker.Kind.XBOX:
			result.append(Picture.new(Shape.ROUND, "A" if bottom else "B",
				Color("#3f9a3f") if bottom else Color("#c0433a"), WHITE))
		DeviceTracker.Kind.PLAYSTATION:
			result.append(Picture.new(Shape.ROUND, "✕" if bottom else "○", PAD_FACE,
				Color("#7fb2ff") if bottom else Color("#ff7f7f")))
		DeviceTracker.Kind.NINTENDO:
			result.append(Picture.new(Shape.ROUND, "B" if bottom else "A", PAD_FACE, WHITE))
	return result

## A hint's items in order: each a Picture or a String word. verb is used by USE only.
static func line(hint: Hint, kind: DeviceTracker.Kind, verb: String = "") -> Array:
	var items: Array = []
	match hint:
		Hint.MOVE:
			items.append_array(pictures(kind, Slot.MOVE))
			items.append("Move")
		Hint.USE:
			items.append_array(pictures(kind, Slot.BOTTOM))
			items.append(verb)
		Hint.BUILD_LIST, Hint.PLACING:
			var list := hint == Hint.BUILD_LIST
			items.append_array(pictures(kind, Slot.BOTTOM))
			items.append("Build" if list else "Place")
			items.append_array(pictures(kind, Slot.RIGHT))
			items.append("Close" if list else "Back")
	return items

## The line in the agreed notation: [label] for KEY, (label) otherwise; a word after a picture gets
## one space before it, a picture after a word gets three.
static func as_text(items: Array) -> String:
	var text := ""
	var previous_word := false
	for i in items.size():
		var item: Variant = items[i]
		if item is Picture:
			if i > 0 and previous_word:
				text += "   "
			var p := item as Picture
			text += ("[%s]" if p.shape == Shape.KEY else "(%s)") % p.label
			previous_word = false
		else:
			if i > 0 and not previous_word:
				text += " "
			text += str(item)
			previous_word = true
	return text
