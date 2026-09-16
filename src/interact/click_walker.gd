class_name ClickWalker
extends Node
## A left click on the world: walks the man there round obstacles, and uses the usable thing clicked on arrival.

signal cant_reach                 # emitted when "Can't reach that" is shown
signal arrived                    # emitted when a click-walk ends by reaching its end (not when cancelled)

const CANT_REACH := "Can't reach that"
const ARRIVE := 2.0               # px from a waypoint that counts as at it
const STUCK_TICKS := 15           # physics ticks without moving that end the walk where he is
const CLICK_SLOP := 2.0           # px a usable's sprite rect is grown by for clicking
const WORLD_DEPTH := 1000000.0    # added to the depth of things drawn in a y-sorted parent

var player: Player
var interactor: Interactor
var grid: WalkGrid
var mark_parent: Node2D
var obstacles: Callable           # func() -> Array[Rect2]

var _waypoints := PackedVector2Array()
var _goal: Usable = null
var _short := false
var _still := 0

func _ready() -> void:
	# Before Player, so each tick's direction is used in the same tick.
	process_physics_priority = -1

func setup(p_player: Player, p_interactor: Interactor, p_grid: WalkGrid, p_mark_parent: Node2D, p_obstacles: Callable) -> void:
	player = p_player
	interactor = p_interactor
	grid = p_grid
	mark_parent = p_mark_parent
	obstacles = p_obstacles

func is_walking() -> bool:
	return not _waypoints.is_empty()

func click_at(world: Vector2) -> void:
	cancel()
	var found: Array[Rect2] = obstacles.call()
	grid.refresh(found)
	var u := _usable_at(world)
	var route: WalkGrid.Route
	if u and player.global_position.distance_to(u.global_position) <= Reach.DISTANCE:
		_face(u)
		interactor.try_use(u)
		return
	if u:
		route = grid.route_into_reach(player.global_position, u.global_position, Reach.DISTANCE - 2.0)
		_goal = u
	else:
		ClickMark.show_at(mark_parent, world.round())
		route = grid.route_to_point(player.global_position, world)
	_waypoints = route.waypoints
	_short = route.short
	if _waypoints.is_empty():
		_arrive()

func cancel() -> void:
	_waypoints = PackedVector2Array()
	_goal = null
	_short = false
	_still = 0
	if player:
		player.auto_direction = Vector2.ZERO

## The index of the rect containing `point` with the greatest depth; equal depths go to the higher index. -1 if none.
static func pick(point: Vector2, rects: Array[Rect2], depths: Array[float]) -> int:
	var best := -1
	for i in rects.size():
		if rects[i].has_point(point) and (best < 0 or depths[i] >= depths[best]):
			best = i
	return best

func _usable_at(world: Vector2) -> Usable:
	var candidates: Array[Usable] = []
	var rects: Array[Rect2] = []
	var depths: Array[float] = []
	for node in get_tree().get_nodes_in_group(Usable.GROUP):
		var u := node as Usable
		if u == null or u.is_gone() or not u.can_use(interactor.inventory):
			continue
		var owner_node := u.get_parent() as Node2D
		var s := owner_node.get_node_or_null("Sprite") as Sprite2D if owner_node else null
		var rect: Rect2
		if s:
			var r := s.get_rect()
			rect = Rect2(s.global_position + r.position, r.size).grow(CLICK_SLOP)
		else:
			rect = Rect2(u.global_position - Vector2(8, 16), Vector2(16, 16)).grow(CLICK_SLOP)
		var depth := owner_node.global_position.y if owner_node else u.global_position.y
		var above := owner_node.get_parent() as Node2D if owner_node else null
		if above and above.y_sort_enabled:
			depth += WORLD_DEPTH
		candidates.append(u)
		rects.append(rect)
		depths.append(depth)
	var i := pick(world, rects, depths)
	return null if i < 0 else candidates[i]

func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if player == null or button == null or button.button_index != MOUSE_BUTTON_LEFT or not button.pressed:
		return
	click_at(player.get_canvas_transform().affine_inverse() * button.position)
	get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if not is_walking():
		return
	for action in Player.MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			cancel()
			return
	if (_waypoints[0] - player.global_position).length() <= ARRIVE:
		_waypoints.remove_at(0)
		if _waypoints.is_empty():
			_arrive()
			return
	player.auto_direction = (_waypoints[0] - player.global_position).normalized()
	_still = 0 if player.moving else _still + 1
	if _still >= STUCK_TICKS:
		_arrive()

func _arrive() -> void:
	var goal := _goal
	var short := _short
	cancel()
	var still_there := goal != null and is_instance_valid(goal) and not goal.is_gone() \
			and goal.can_use(interactor.inventory)
	if still_there and player.global_position.distance_to(goal.global_position) <= Reach.DISTANCE:
		_face(goal)
		interactor.try_use(goal)
	elif short or still_there:
		# A thing taken or used up on the way shows nothing.
		RisingLine.show_over(player, CANT_REACH)
		cant_reach.emit()
	arrived.emit()

func _face(u: Usable) -> void:
	var d := u.global_position - player.global_position
	if d.length() >= 1.0:
		player.facing = Walk.facing_for(d.normalized(), player.facing)
