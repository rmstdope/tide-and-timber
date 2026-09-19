class_name DebugShow
extends RefCounted
## The Debug panel's Show page: its rows, the readout's lines and the outlines' geometry.

enum Switch { READOUT, COLLISION_AREAS, USE_AREAS }

const LABELS := ["Readout", "Collision areas", "Use areas"]   # index = Switch
const ON := "On"
const OFF := "Off"

## The switch's current value in DebugSwitches.
static func is_on(s: Switch) -> bool:
	match s:
		Switch.READOUT: return DebugSwitches.readout
		Switch.COLLISION_AREAS: return DebugSwitches.collision_areas
		_: return DebugSwitches.use_areas

## Flips that switch in DebugSwitches.
static func flip(s: Switch) -> void:
	match s:
		Switch.READOUT: DebugSwitches.readout = not DebugSwitches.readout
		Switch.COLLISION_AREAS: DebugSwitches.collision_areas = not DebugSwitches.collision_areas
		_: DebugSwitches.use_areas = not DebugSwitches.use_areas

## ON when is_on(s), else OFF.
static func value_text(s: Switch) -> String:
	return ON if is_on(s) else OFF

## Appends to menu's SHOW page one row per switch, in Switch order. Left/Right and Select all flip it.
static func add_rows(menu: DebugMenu) -> void:
	for sw: Switch in Switch.values():
		var s := sw
		menu.add_row(DebugMenu.Page.SHOW, DebugRow.new(LABELS[s],
				func() -> String: return value_text(s),
				func(_delta: int) -> void: flip(s),
				func() -> DebugRow.Result:
					flip(s)
					return DebugRow.Result.DONE))

## The readout's lines, top to bottom; a line with no source (no clock, no man) is left out.
static func readout_lines(fps: float, clock: GameClock, time_scale: float, feet: Variant) -> Array[String]:
	var lines: Array[String] = []
	if clock != null:
		lines.append("DAY %d %s" % [clock.day(), clock.time_text()])
		lines.append("SPEED " + DebugTime.speed_text(time_scale))
	lines.append("FPS %d" % roundi(fps))
	if feet is Vector2:
		lines.append("X %d Y %d" % [roundi(feet.x), roundi(feet.y)])
	return lines

## The map cells a view rectangle (global px) touches, clamped to the map; empty Rect2i when none.
static func cells_in(view: Rect2) -> Rect2i:
	var t := float(BeachLayout.TILE)
	var from := Vector2i((view.position / t).floor()).clamp(Vector2i.ZERO, BeachLayout.map_size())
	var to := Vector2i((view.end / t).ceil()).clamp(Vector2i.ZERO, BeachLayout.map_size())
	if to.x <= from.x or to.y <= from.y:
		return Rect2i()
	return Rect2i(from, to - from)

## The outline of the solid tiles among `cells`, as segment pairs in global px, inset 0.5 px into each cell.
## solid: (Vector2i) -> bool. A neighbour outside the map counts as not solid.
static func tile_edges(cells: Rect2i, solid: Callable) -> PackedVector2Array:
	var map := Rect2i(Vector2i.ZERO, BeachLayout.map_size())
	var is_solid := func(n: Vector2i) -> bool: return map.has_point(n) and solid.call(n)
	var t := float(BeachLayout.TILE)
	var pts := PackedVector2Array()
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var c := Vector2i(x, y)
			if not solid.call(c):
				continue
			var o := Vector2(c * BeachLayout.TILE)
			if not is_solid.call(c + Vector2i.UP):
				pts.append_array([o + Vector2(0, 0.5), o + Vector2(t, 0.5)])
			if not is_solid.call(c + Vector2i.DOWN):
				pts.append_array([o + Vector2(0, t - 0.5), o + Vector2(t, t - 0.5)])
			if not is_solid.call(c + Vector2i.LEFT):
				pts.append_array([o + Vector2(0.5, 0), o + Vector2(0.5, t)])
			if not is_solid.call(c + Vector2i.RIGHT):
				pts.append_array([o + Vector2(t - 0.5, 0), o + Vector2(t - 0.5, t)])
	return pts

## Global rects of every enabled RectangleShape2D CollisionShape2D whose parent is a CollisionObject2D under `world`.
static func solid_rects(world: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for node in world.find_children("*", "CollisionShape2D", true, false):
		var shape_node := node as CollisionShape2D
		if shape_node.disabled or not shape_node.get_parent() is CollisionObject2D \
				or not shape_node.shape is RectangleShape2D:
			continue
		var size: Vector2 = (shape_node.shape as RectangleShape2D).size
		rects.append(Rect2(shape_node.global_position - size / 2, size))
	return rects

## global_position of every usable thing in the tree that is not gone.
static func use_spots(tree: SceneTree) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	for node in tree.get_nodes_in_group(Usable.GROUP):
		var usable := node as Usable
		if usable and not usable.is_gone():
			spots.append(usable.global_position)
	return spots

## Adds the Show layers under `owner`: the outline layer only on the beach, and always the readout layer.
## beach and day_night are null in the shipwreck story.
static func attach(owner: Node, beach: Beach, day_night: DayNight) -> void:
	if beach != null:
		var outline_layer := CanvasLayer.new()
		outline_layer.name = "DebugOutlineLayer"
		outline_layer.layer = 9   # above the world and its night tint, under the HUD (10)
		outline_layer.follow_viewport_enabled = true
		outline_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		var outlines := DebugOutlines.new()
		outlines.name = "Outlines"
		outlines.beach = beach
		outline_layer.add_child(outlines)
		owner.add_child(outline_layer)
	var readout_layer := CanvasLayer.new()
	readout_layer.name = "DebugReadoutLayer"
	readout_layer.layer = 35   # above the covers (30), under the pause layer (40)
	readout_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var readout := DebugReadout.new()
	readout.name = "Readout"
	readout.day_night = day_night
	readout.player = beach.get_node("%Player") if beach else null
	readout_layer.add_child(readout)
	owner.add_child(readout_layer)
