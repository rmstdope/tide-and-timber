class_name DebugKeys
extends RefCounted
## F1-F4 while playing in a debug build: what each key flips, and the line it confirms with.

const CYCLE: Array[float] = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
const READOUT_ON := "Readout on"
const READOUT_OFF := "Readout off"
const COLLISION_ON := "Collision areas on"
const COLLISION_OFF := "Collision areas off"
const WALK_THROUGH_ON := "Walk through things on"
const WALK_THROUGH_OFF := "Walk through things off"
const SPEED := "Speed "   # followed by DebugTime.speed_text: "Speed x4"

## The first CYCLE entry strictly above scale; 1.0 when none (x32 wraps to x1; x0.25 and x0.5 go to x1).
static func next_speed(scale: float) -> float:
	if scale < 1.0:
		return 1.0
	for s in CYCLE:
		if s > scale:
			return s
	return 1.0

## Applies the shortcut and returns its line; "" when it does nothing here.
## day_night is null in the shipwreck story: no clock and no man, so SPEED and WALK_THROUGH do nothing.
static func press(shortcut: DebugShortcut.Name, day_night: DayNight) -> String:
	match shortcut:
		DebugShortcut.Name.READOUT:
			DebugShow.flip(DebugShow.Switch.READOUT)
			return READOUT_ON if DebugSwitches.readout else READOUT_OFF
		DebugShortcut.Name.COLLISION_AREAS:
			DebugShow.flip(DebugShow.Switch.COLLISION_AREAS)
			return COLLISION_ON if DebugSwitches.collision_areas else COLLISION_OFF
		DebugShortcut.Name.SPEED:
			if day_night == null:
				return ""
			day_night.time_scale = next_speed(day_night.time_scale)
			return SPEED + DebugTime.speed_text(day_night.time_scale)
		DebugShortcut.Name.WALK_THROUGH:
			if day_night == null:
				return ""
			DebugPlaces.flip_walk_through()
			return WALK_THROUGH_ON if DebugSwitches.walk_through else WALK_THROUGH_OFF
	return ""

## Adds a CanvasLayer "DebugKeyLayer" (layer 35, always processing) holding a DebugKeyLine "KeyLine".
static func attach(owner: Node, day_night: DayNight) -> DebugKeyLine:
	var layer := CanvasLayer.new()
	layer.name = "DebugKeyLayer"
	layer.layer = 35   # above the covers (30, 31), under the pause layer (40)
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var line := DebugKeyLine.new()
	line.name = "KeyLine"
	line.day_night = day_night
	layer.add_child(line)
	owner.add_child(layer)
	return line
