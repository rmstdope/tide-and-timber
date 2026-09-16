extends Node2D
## Developer preview of the day/night clock over a flat beach backdrop. Not reachable from the game.
## godot --path . res://src/day_night/day_night_preview.tscn -- --clock-speed=60 --clock-start=18:20
## Esc toggles pause.

const DAY_NIGHT := preload("res://src/day_night/day_night.tscn")


static func parse_args(args: PackedStringArray) -> Dictionary:
	var opts := {"speed": 1.0, "start": GameClock.START_MINUTES}
	var hhmm := RegEx.create_from_string("^(\\d\\d):(\\d\\d)$")
	for arg in args:
		if arg.begins_with("--clock-speed="):
			var value := arg.trim_prefix("--clock-speed=")
			if value.is_valid_float() and value.to_float() > 0.0:
				opts.speed = value.to_float()
		elif arg.begins_with("--clock-start="):
			var found := hhmm.search(arg.trim_prefix("--clock-start="))
			if found:
				var hours := found.get_string(1).to_int()
				var minutes := found.get_string(2).to_int()
				if hours < 24 and minutes < 60:
					opts.start = hours * 60 + minutes
	return opts


## A start at or after 13:00 is on DAY 1; an earlier one is the next morning, on DAY 2.
static func start_total_minutes(minute_of_day: int) -> float:
	if minute_of_day >= GameClock.START_MINUTES:
		return minute_of_day
	return minute_of_day + GameClock.MINUTES_PER_DAY


func _ready() -> void:
	var opts := parse_args(OS.get_cmdline_user_args())
	var dn: DayNight = DAY_NIGHT.instantiate()
	dn.clock.total_minutes = start_total_minutes(opts.start)
	dn.time_scale = opts.speed
	add_child(dn)
	dn.start()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()
