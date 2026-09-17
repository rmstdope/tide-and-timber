class_name Night
extends Node
## Joins the clock, the camp's firelight and the man for the night: lines, frost, collapse, morning.
## Lives in waking.tscn; reaches %Beach, %DayNight and its own overlay nodes by unique name.
## Not the scene root, so gdUnit4 delivers its input once.

const WARN_TEXT := "Getting cold. I need that fire."
const OUT_TEXT := "I can't stay out here."
const BLACK_TEXT := "So cold... just... rest a moment..."

var watch := NightWatch.new()
var line := SunsetLine.new()        # the fade of his current night line
var card := MorningCard.new()
var collapse: Collapse               # non-null from the fall until he is up
var taken: Array[Vector2i] = []      # the last collapse's losses
var day_night: DayNight
var beach: Beach
var builder: Builder
var player: Player
var autosave: Autosave
var _pending := ""                   # a line waiting for another line to go
var _begun := false
var _interactor_mode := Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	day_night = %DayNight
	beach = %Beach
	autosave = %Autosave
	builder = beach.get_node("%Builder")
	player = beach.get_node("%Player")
	watch.warned.connect(_say.bind(WARN_TEXT))
	watch.stepped_out.connect(_say.bind(OUT_TEXT))
	watch.collapsed.connect(_start_collapse)
	%BlackLine.text = BLACK_TEXT
	_refresh()

func _process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	card.advance(delta)
	if collapse:
		_advance_collapse(delta)
		_refresh()
		return
	if not day_night.running or not day_night.can_process():
		_refresh()
		return
	if not _begun:
		watch.reset(day_night.clock.total_minutes)
		_begun = true
	watch.advance(delta, day_night.clock.total_minutes, builder.in_firelight(player.global_position))
	if collapse == null:
		_advance_line(delta)
	_refresh()

func _input(_event: InputEvent) -> void:
	if collapse:
		get_viewport().set_input_as_handled()

func _say(text: String) -> void:
	_pending = text

func _others_showing() -> bool:
	return day_night.sunset.is_showing() or builder.shelter_line.is_showing()

func _advance_line(delta: float) -> void:
	line.advance(delta)
	if line.is_showing() and builder.shelter_line.is_showing():
		line = SunsetLine.new()
	if _pending != "" and not _others_showing():
		%NightLine.get_node("Text").text = _pending
		_pending = ""
		line = SunsetLine.new()
		line.start()

func _start_collapse() -> void:
	if builder.mode == Builder.Mode.PLACING:
		builder.abandon_placing()
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	player.moving = false
	player.play_pose(Walk.animation_for(player.facing, false))
	var interactor := beach.get_node("%Interactor")
	_interactor_mode = interactor.process_mode
	interactor.process_mode = PROCESS_MODE_DISABLED
	beach.get_node("%Prompt").hide()
	(beach.get_node("%ClickWalker") as ClickWalker).cancel()
	_pending = ""
	line = SunsetLine.new()
	collapse = Collapse.new()
	collapse.went_black.connect(_on_went_black)
	collapse.morning.connect(_on_morning)
	collapse.got_up.connect(_on_got_up)

func _advance_collapse(delta: float) -> void:
	collapse.advance(delta)
	if collapse:
		var p := collapse.pose()
		if p != &"":
			player.play_pose(p)
		player.get_node("%Sprite").offset.x = collapse.sway_x()

func _on_went_black() -> void:
	var t := day_night.clock.total_minutes
	taken = NightLoss.losses(beach.inventory)
	NightLoss.apply(beach.inventory, taken)
	autosave.hold_line()   # saved now, at 06:00 with the loss; his dawn line waits until he is up
	day_night.add_minutes(NightWatch.next_morning(t) - t)
	var cell := WakeSpot.beside_lean_to(builder.lean_to.anchor(), Waking.WAKE_CELL) if builder.lean_to else Waking.WAKE_CELL
	player.global_position = BeachLayout.cell_centre(cell)
	player.facing = Walk.Facing.DOWN
	(beach.get_node("%Camera") as LooseCamera).snap_to_target()
	watch.reset(day_night.clock.total_minutes)

func _on_morning() -> void:
	%Card.show_lines(NightLoss.card_lines(day_night.clock.day(), taken))
	card.start()

func _on_got_up() -> void:
	player.get_node("%Sprite").offset.x = 0.0
	player.give_control()
	beach.get_node("%Interactor").process_mode = _interactor_mode
	collapse = null
	autosave.release_line()

func _refresh() -> void:
	%Frost.set_amount(watch.frost)
	%NightLine.visible = line.is_showing()
	%NightLine.modulate.a = line.alpha()
	var a := collapse.cover_alpha() if collapse else 0.0
	%CollapseCover.modulate.a = a
	%CollapseCover.visible = a > 0.0
	var la := collapse.line_alpha() if collapse else 0.0
	%BlackLine.modulate.a = la
	%BlackLine.visible = la > 0.0
	%Card.visible = card.is_showing()
	%Card.modulate.a = card.alpha()
