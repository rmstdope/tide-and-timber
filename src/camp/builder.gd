class_name Builder
extends Node
## Runs building: the list, placing, and the black. Reaches the beach's nodes by unique name.
## Not the scene root, so gdUnit4 delivers its input once.

enum Mode { CLOSED, LIST, PLACING, BUILDING }

const SHELTER_TEXT := "That should see me through the night."

var mode: Mode = Mode.CLOSED
var menu := BuildMenu.new()
var placing: BuildMenu.Thing = BuildMenu.Thing.LEAN_TO
var fade: BuildFade                      # non-null only while BUILDING
var lean_to: LeanTo                      # null until built
var fire: CampFire                       # null until built
var day_night: DayNight                  # injected; null when the beach runs alone
var inventory: Inventory
var _frozen: Dictionary = {}             # Node -> its process_mode before freezing
var _crossed_sunset := false
var _props: Dictionary = {}              # BuildSite.prop_cells(), computed once in setup
var shelter_line := SunsetLine.new()     # the fade timer of his shelter line
var _shelter_line_pending := false       # lit, waiting for the sunset line to go

func setup(p_inventory: Inventory) -> void:
	inventory = p_inventory
	_props = BuildSite.prop_cells()
	%ShelterLine.get_node("Text").text = SHELTER_TEXT
	%BuildList.row_hovered.connect(_on_row_hovered)
	%BuildList.row_clicked.connect(_on_row_clicked)

func open_list() -> void:
	var from_placing := mode == Mode.PLACING
	menu.set_state(inventory.count(Item.Kind.DRIFTWOOD), lean_to != null, fire != null and fire.lit)
	if from_placing:
		menu.highlighted = placing
	else:
		menu.open()
	mode = Mode.LIST
	_freeze_only(_world_nodes())
	%Prompt.hide()
	var walker := get_node_or_null("%ClickWalker")
	if walker:
		walker.cancel()
	%Ghost.hide()
	%BuildList.position = BuildList.top_left_for(%Player.get_global_transform_with_canvas().origin)
	%BuildList.show_menu(menu)
	%BuildList.show()
	%BuildBlocker.show()
	%KeyHint.show_hint(DeviceHints.Hint.BUILD_LIST)

func close_list() -> void:
	mode = Mode.CLOSED
	_freeze_only([])
	%BuildList.hide()
	%BuildBlocker.hide()
	%KeyHint.hide()

func choose(thing: int) -> void:
	if mode != Mode.LIST or not menu.can_build(thing as BuildMenu.Thing):
		return
	placing = thing as BuildMenu.Thing
	mode = Mode.PLACING
	_freeze_only([%Interactor])
	%Prompt.hide()
	%BuildList.hide()
	%BuildBlocker.hide()
	%KeyHint.show_hint(DeviceHints.Hint.PLACING)
	_update_ghost()

## Leaves placing as if it never began: nothing spent, outline and hint gone, the world unfrozen.
func abandon_placing() -> void:
	if mode != Mode.PLACING:
		return
	mode = Mode.CLOSED
	_freeze_only([])
	%Ghost.hide()
	%KeyHint.hide()

func back_to_list() -> void:
	open_list()

func placing_cells() -> Array[Vector2i]:
	return BuildSite.cells_for(placing, BuildSite.cell_of(%Player.global_position), %Player.facing)

func can_place_now() -> bool:
	var taken := _props.duplicate()
	for node in get_tree().get_nodes_in_group(Usable.GROUP):
		var usable := node as Usable
		if usable and not usable.is_gone():
			taken[BuildSite.cell_of(usable.global_position - Vector2(0, 1))] = true
	if lean_to:
		for c in lean_to.cells:
			taken[c] = true
	return BuildSite.can_place(placing, placing_cells(), taken, BuildSite.feet_rect(%Player.global_position),
		lean_to != null, lean_to.anchor() if lean_to else Vector2i.ZERO)

func try_place() -> bool:
	if mode != Mode.PLACING or not can_place_now():
		return false
	var cells := placing_cells()
	inventory.remove(Item.Kind.DRIFTWOOD, BuildMenu.COSTS[placing])
	mode = Mode.BUILDING
	_freeze_only(_world_nodes())
	%Ghost.hide()
	%KeyHint.hide()
	%Prompt.hide()
	fade = BuildFade.new()
	fade.went_black.connect(_on_went_black.bind(cells, placing))
	fade.black_ended.connect(_on_black_ended.bind(placing))
	fade.finished.connect(_on_finished.bind(placing))
	_crossed_sunset = false
	_refresh_cover()
	return true

## A lean-to stands with a lit fire in front of it (the fire can stand nowhere else).
func has_shelter() -> bool:
	return lean_to != null and fire != null and fire.lit

## True if at (global px) is inside a lit fire's glow.
func in_firelight(at: Vector2) -> bool:
	return fire != null and fire.lit and at.distance_to(fire.light_centre()) <= CampFire.LIGHT_RADIUS

func tick(delta: float) -> void:
	var was := mode
	_check_burn_out()
	match mode:
		Mode.BUILDING:
			fade.advance(delta)
			_refresh_cover()
		Mode.PLACING:
			_update_ghost()
	if was == Mode.CLOSED or was == Mode.PLACING:
		_update_shelter_line(delta)

func _process(delta: float) -> void:
	tick(delta)

func _shortcut_input(event: InputEvent) -> void:
	match mode:
		Mode.CLOSED:
			if event.is_action_pressed(&"build", false) and %Player.control_enabled:
				open_list()
				_handled()
		Mode.LIST:
			if _list_step(InputDevice.menu_step(event)):
				_handled()
			# The fixed menu meaning is checked before the player's own keys, so it wins when they share one.
			elif event.is_action_pressed(&"build_accept", false):
				_choose_highlighted()
			elif event.is_action_pressed(&"build_back", false):
				close_list()
				_handled()
			elif event.is_action_pressed(&"use", false):
				_choose_highlighted()
			elif event.is_action_pressed(&"build", false):
				close_list()
				_handled()
		Mode.PLACING:
			if event.is_action_pressed(&"build_accept", false):
				try_place()
				_handled()
			elif event.is_action_pressed(&"build_back", false):
				back_to_list()
				_handled()
			elif event.is_action_pressed(&"use", false):
				try_place()
				_handled()
			elif event.is_action_pressed(&"build", false):
				back_to_list()
				_handled()
		Mode.BUILDING:
			_handled()

func _input(event: InputEvent) -> void:
	if mode == Mode.BUILDING:
		_handled()
	elif mode == Mode.LIST and event is InputEventJoypadMotion:
		# The only way the stick reaches the list: _shortcut_input never gets motion.
		if _list_step(InputDevice.menu_step(event)):
			_handled()
	elif mode == Mode.PLACING:
		var click := event as InputEventMouseButton
		if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			try_place()
			_handled()

func _choose_highlighted() -> void:
	if menu.highlighted >= 0:
		choose(menu.highlighted)
	_handled()

## Up and down on the open list, one line per push; false for any other step.
func _list_step(step: MenuPush.Step) -> bool:
	match step:
		MenuPush.Step.UP:
			menu.move(-1)
		MenuPush.Step.DOWN:
			menu.move(1)
		_:
			return false
	%BuildList.show_menu(menu)
	return true

func _handled() -> void:
	get_viewport().set_input_as_handled()

func _world_nodes() -> Array[Node]:
	var nodes: Array[Node] = [%World, %Decor, %Interactor]
	if day_night:
		nodes.append(day_night)
	return nodes

## Freezes exactly these nodes, putting back the mode each of the rest had.
func _freeze_only(nodes: Array[Node]) -> void:
	for node: Node in _frozen.keys():
		if not nodes.has(node):
			if is_instance_valid(node):
				node.process_mode = _frozen[node]
			_frozen.erase(node)
	for node in nodes:
		if node and not _frozen.has(node):
			_frozen[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED

func _update_ghost() -> void:
	%Ghost.show_at(placing, BuildSite.origin_for(placing, placing_cells()), can_place_now())

func _refresh_cover() -> void:
	var a := fade.cover_alpha() if fade else 0.0
	%BuildCover.modulate.a = a
	%BuildCover.visible = a > 0.0

func _on_went_black(cells: Array[Vector2i], thing: BuildMenu.Thing) -> void:
	if thing == BuildMenu.Thing.LEAN_TO:
		_add_lean_to(cells)
	else:
		_add_fire(cells[0])
	%BuildSound.set_audible(true)

## Adds a lean-to on `cells` under %World and keeps it as lean_to.
func _add_lean_to(cells: Array[Vector2i]) -> void:
	lean_to = LeanTo.new()
	lean_to.cells = cells
	lean_to.position = BuildSite.origin_for(BuildMenu.Thing.LEAN_TO, cells)
	%World.add_child(lean_to)

## Frees any fire, adds a new lit one on `cell` under %World, keeps it as fire, returns it.
func _add_fire(cell: Vector2i) -> CampFire:
	if fire != null:
		fire.queue_free()
	fire = CampFire.new()
	fire.cell = cell
	fire.position = BuildSite.origin_for(BuildMenu.Thing.FIRE, [cell])
	%World.add_child(fire)
	return fire

## Writes the camp as it is now into data's camp fields.
func capture_camp(data: SaveData) -> void:
	data.lean_to_cells = lean_to.cells.duplicate() if lean_to else ([] as Array[Vector2i])
	data.has_fire = fire != null
	if fire == null:
		return
	data.fire_cell = fire.cell
	data.fire_lit = fire.lit
	data.fire_out_at = fire.out_at
	if fire.lit and not is_finite(fire.out_at) and day_night != null:
		# Built across 06:00: the dawn save runs inside add_minutes, before _on_black_ended sets out_at.
		data.fire_out_at = FireLife.out_at(day_night.clock.total_minutes)

## Whether data's camp may be rebuilt: none at all; or a 3x2 lean-to on sand listed row by row,
## top-left first, with any fire at its fire_spot. A fire without a lean-to is refused. No nodes touched.
static func camp_fits(data: SaveData) -> bool:
	var cells := data.lean_to_cells
	if cells.is_empty():
		return not data.has_fire
	if cells.size() != 6:
		return false
	var lo := cells[0]
	for c in cells:
		lo = lo.min(c)
	for i in 6:
		if cells[i] != lo + Vector2i(i % 3, i / 3) or not BuildSite.is_ground_ok(cells[i]):
			return false
	return not data.has_fire or data.fire_cell == BuildSite.fire_spot(BuildSite.anchor_of(cells))

## Rebuilds the camp from data (assumes camp_fits). Frees any lean-to or fire already standing.
func restore_camp(data: SaveData) -> void:
	if lean_to != null:
		lean_to.queue_free()
		lean_to = null
	if fire != null:
		fire.queue_free()
		fire = null
	if not data.lean_to_cells.is_empty():
		_add_lean_to(data.lean_to_cells.duplicate())
	if data.has_fire:
		var f := _add_fire(data.fire_cell)
		f.out_at = data.fire_out_at
		if not data.fire_lit:
			f.put_out()

func _on_black_ended(thing: BuildMenu.Thing) -> void:
	%BuildSound.set_audible(false)
	if day_night:
		_crossed_sunset = day_night.add_minutes(30.0)
	if thing == BuildMenu.Thing.FIRE and day_night:
		fire.out_at = FireLife.out_at(day_night.clock.total_minutes)
	_check_burn_out()

func _on_finished(thing: BuildMenu.Thing) -> void:
	fade = null
	mode = Mode.CLOSED
	_freeze_only([])
	_refresh_cover()
	if _crossed_sunset and day_night:
		day_night.sunset.start()
	if thing == BuildMenu.Thing.FIRE:
		_shelter_line_pending = true
		_update_shelter_line(0.0)

func _check_burn_out() -> void:
	if fire != null and fire.lit and day_night and FireLife.is_out(fire.out_at, day_night.clock.total_minutes):
		fire.put_out()

func _update_shelter_line(delta: float) -> void:
	shelter_line.advance(delta)
	var sunset_showing: bool = day_night != null and day_night.sunset.is_showing()
	if sunset_showing and shelter_line.is_showing():
		# The sunset line started over his: he steps aside and says it once it has gone.
		shelter_line = SunsetLine.new()
		_shelter_line_pending = true
	if _shelter_line_pending and not sunset_showing:
		_shelter_line_pending = false
		shelter_line.start()
	%ShelterLine.visible = shelter_line.is_showing()
	%ShelterLine.modulate.a = shelter_line.alpha()

func _on_row_hovered(i: int) -> void:
	if mode != Mode.LIST:
		return
	menu.hover(i as BuildMenu.Thing)
	%BuildList.show_menu(menu)

func _on_row_clicked(i: int) -> void:
	if mode != Mode.LIST:
		return
	menu.hover(i as BuildMenu.Thing)
	%BuildList.show_menu(menu)
	choose(i)
