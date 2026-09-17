class_name DeviceHints
extends RefCounted
## What each hint says on each device: pictures and words, no drawing.

enum Hint { MOVE, USE, BUILD_LIST, PLACING }
enum Slot { MOVE, BOTTOM, RIGHT }
enum Shape { KEY, ROUND, STICK, SHOULDER }   # SHOULDER: also every pad picture of more than one glyph

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

const _FACE_BUTTONS := {
	DeviceTracker.Kind.XBOX: [["A", "#3f9a3f", "#ffffff"], ["B", "#c0433a", "#ffffff"], ["X", "#3b6fd0", "#ffffff"],
		["Y", "#e0b030", "#3a2414"]],
	DeviceTracker.Kind.PLAYSTATION: [["✕", "#3a3a44", "#7fb2ff"], ["○", "#3a3a44", "#ff7f7f"],
		["□", "#3a3a44", "#ff9fdf"], ["△", "#3a3a44", "#7fe0b0"]],
	DeviceTracker.Kind.NINTENDO: [["B", "#3a3a44", "#ffffff"], ["A", "#3a3a44", "#ffffff"], ["Y", "#3a3a44", "#ffffff"],
		["X", "#3a3a44", "#ffffff"]],
}
# Buttons 4 to 10 by family: [label, round?].
const _OTHER_BUTTONS := {
	DeviceTracker.Kind.XBOX: [["View", false], ["Home", false], ["Start", false], ["LS", false], ["RS", false],
		["LB", false], ["RB", false]],
	DeviceTracker.Kind.PLAYSTATION: [["Share", false], ["Home", false], ["Opt", false], ["L3", false], ["R3", false],
		["L1", false], ["R1", false]],
	DeviceTracker.Kind.NINTENDO: [["-", true], ["Home", false], ["+", true], ["LS", false], ["RS", false],
		["L", false], ["R", false]],
}
const _DPAD := ["↑", "↓", "←", "→"]   # buttons 11 to 14
const _TRIGGERS := {DeviceTracker.Kind.XBOX: ["LT", "RT"], DeviceTracker.Kind.PLAYSTATION: ["L2", "R2"],
	DeviceTracker.Kind.NINTENDO: ["ZL", "ZR"]}
const _RIGHT_STICK := [[3, -1.0], [3, 1.0], [2, -1.0], [2, 1.0]]   # up, down, left, right
const _MOVE_ORDER := [Controls.Action.WALK_UP, Controls.Action.WALK_LEFT, Controls.Action.WALK_DOWN,
	Controls.Action.WALK_RIGHT]

## The picture of one key, pad button or stick direction, drawn for this pad family (Xbox when not a pad).
static func picture_for(event: InputEvent, kind: DeviceTracker.Kind) -> Picture:
	if event is InputEventKey:
		return Picture.new(Shape.KEY, KeyLabels.label(event), CAP_FACE, CAP_INK)
	var family := kind if _FACE_BUTTONS.has(kind) else DeviceTracker.Kind.XBOX
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index as int
		if index <= 3:
			var face: Array = _FACE_BUTTONS[family][index]
			return Picture.new(Shape.ROUND, face[0], Color(face[1]), Color(face[2]))
		if index <= 10:
			var other: Array = _OTHER_BUTTONS[family][index - 4]
			return Picture.new(Shape.ROUND if other[1] else Shape.SHOULDER, other[0], PAD_FACE, WHITE)
		if index <= 14:
			return Picture.new(Shape.ROUND, _DPAD[index - 11], PAD_FACE, WHITE)
		return Picture.new(Shape.SHOULDER, "B%d" % index, PAD_FACE, WHITE)
	var motion := event as InputEventJoypadMotion
	var negative := motion.axis_value < 0.0
	var label := "A%d" % motion.axis
	match motion.axis as int:
		0: label = "L←" if negative else "L→"
		1: label = "L↑" if negative else "L↓"
		2: label = "R←" if negative else "R→"
		3: label = "R↑" if negative else "R↓"
		4: label = _TRIGGERS[family][0]
		5: label = _TRIGGERS[family][1]
	return Picture.new(Shape.SHOULDER, label, PAD_FACE, WHITE)

## The pictures for a slot on a device, left to right, from the player's controls (the defaults when null).
static func pictures(kind: DeviceTracker.Kind, slot: Slot, controls: Controls = null) -> Array[Picture]:
	if controls == null:
		controls = Controls.new()
	var keyboard := kind == DeviceTracker.Kind.KEYBOARD
	var device := Controls.Device.KEYBOARD if keyboard else Controls.Device.CONTROLLER
	var result: Array[Picture] = []
	match slot:
		Slot.MOVE:
			if not keyboard:
				if _is_stick(controls, func(a: Controls.Action) -> InputEvent:
						return Controls.default_slot(a, Controls.Device.CONTROLLER, 0)):
					result.append(Picture.new(Shape.STICK, "L", PAD_FACE, WHITE))
					return result
				if _is_stick(controls, func(a: Controls.Action) -> InputEvent:
						var d: Array = _RIGHT_STICK[a]
						var m := InputEventJoypadMotion.new()
						m.axis = d[0]
						m.axis_value = d[1]
						return m):
					result.append(Picture.new(Shape.STICK, "R", PAD_FACE, WHITE))
					return result
			for a: Controls.Action in _MOVE_ORDER:
				var e := controls.first_input(a, device)
				if e != null:
					result.append(picture_for(e, kind))
		Slot.BOTTOM:
			var use := controls.first_input(Controls.Action.USE, device)
			if use != null:
				result.append(picture_for(use, kind))
		Slot.RIGHT:
			if keyboard:
				result.append(Picture.new(Shape.KEY, "Esc", CAP_FACE, CAP_INK))
			else:
				result.append(picture_for(_pad_button(1), kind))
	return result

# True when the four walk actions' controller slots are the four directions `direction` gives.
static func _is_stick(controls: Controls, direction: Callable) -> bool:
	for a: Controls.Action in _MOVE_ORDER:
		if not Controls.same_input(controls.slot(a, Controls.Device.CONTROLLER, 0), direction.call(a)):
			return false
	return true

static func _pad_button(index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = index as JoyButton
	return e

## A hint's items in order: each a Picture or a String word. verb is used by USE only.
static func line(hint: Hint, kind: DeviceTracker.Kind, verb: String = "", controls: Controls = null) -> Array:
	var items: Array = []
	match hint:
		Hint.MOVE:
			items.append_array(pictures(kind, Slot.MOVE, controls))
			items.append("Move")
		Hint.USE:
			items.append_array(pictures(kind, Slot.BOTTOM, controls))
			items.append(verb)
		Hint.BUILD_LIST, Hint.PLACING:
			var list := hint == Hint.BUILD_LIST
			var choose := pictures(kind, Slot.BOTTOM, controls)
			if choose.is_empty():
				# Enter and the bottom button always choose, whatever Use is set to.
				if kind == DeviceTracker.Kind.KEYBOARD:
					choose.append(Picture.new(Shape.KEY, "Enter", CAP_FACE, CAP_INK))
				else:
					choose.append(picture_for(_pad_button(0), kind))
			items.append_array(choose)
			items.append("Build" if list else "Place")
			items.append_array(pictures(kind, Slot.RIGHT, controls))
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
