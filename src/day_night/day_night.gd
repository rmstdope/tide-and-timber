class_name DayNight
extends Node
## The day/night clock: owns the time, tints the world, shows the dial and the 18:30 line.
## Instance day_night.tscn and call start() when the player gets control.

## Emitted once each time the clock crosses 06:00 in tick() or add_minutes(), after the light and
## labels show it. A collapse applies its loss before add_minutes(), so the loss is what gets saved.
signal dawn

## Emitted by set_minutes(): the clock was set by hand, not run.
signal moved

var clock := GameClock.new()
var sunset := SunsetLine.new()
var running := false
var time_scale := 1.0   # multiplies game time only; 1.0 in the game; the preview raises it

const PLANK_WIDTH := 64.0     # the plank's Normal width in day_night.tscn
const PLANK_HEIGHT := 54.0
const LABEL_HEIGHT := 8.0
const DAY_TOP := 5.0
const DIAL_TOP := 14.0
const TIME_TOP := 43.0
const PLANK_PAD := 4.0        # units of padding each side of the wider of day and time

var _fitted_day := ""
var _fitted_time := ""


func _ready() -> void:
	Display.changed.connect(fit_clock)
	get_tree().root.size_changed.connect(fit_clock)
	_refresh()


func start() -> void:
	running = true
	%Hud.visible = true
	_refresh()


func _process(delta: float) -> void:
	if running:
		tick(delta)


func tick(real_seconds: float) -> void:
	var before := clock.sunsets_passed()
	var dawns_before := clock.dawns_passed()
	clock.advance(real_seconds * time_scale)
	sunset.advance(real_seconds)
	if clock.sunsets_passed() > before:
		sunset.start()
	_refresh()
	if clock.dawns_passed() > dawns_before:
		dawn.emit()


func _refresh() -> void:
	%Light.color = Daylight.color_at(clock.minute_of_day())
	%DayLabel.text = clock.day_text()
	%TimeLabel.text = clock.time_text()
	%Dial.fraction = clock.dial_fraction()
	%Dial.is_day = clock.is_day()
	%Dial.queue_redraw()
	%Sunset.visible = sunset.is_showing()
	%Sunset.modulate.a = sunset.alpha()
	if %DayLabel.text != _fitted_day or %TimeLabel.text != _fitted_time:
		fit_clock()


## Moves the clock on at once and refreshes. True if an 18:30 was crossed. Does not start the line.
## Emits dawn when a 06:00 was crossed, like tick().
func add_minutes(minutes: float) -> bool:
	var before := clock.sunsets_passed()
	var dawns_before := clock.dawns_passed()
	clock.total_minutes += minutes
	_refresh()
	if clock.dawns_passed() > dawns_before:
		dawn.emit()
	return clock.sunsets_passed() > before


## Sets the clock at once and repaints light, labels and dial. Emits moved; never dawn, never starts the 18:30 line.
func set_minutes(total: float) -> void:
	clock.total_minutes = total
	_refresh()
	moved.emit()


## Widens and heightens the plank to fit the day and time at the current Text size, growing right and
## down from its top-left; the dial keeps its size and stays centred in the wider plank.
func fit_clock() -> void:
	var rel := TextScale.relative(Display.prefs, get_tree().root) if is_inside_tree() else 1.0
	%DayLabel.scale = Vector2.ONE
	%TimeLabel.scale = Vector2.ONE
	var words := maxf(%DayLabel.get_minimum_size().x, %TimeLabel.get_minimum_size().x)
	var w := maxf(PLANK_WIDTH, ceilf(words * rel) + 2.0 * PLANK_PAD)
	var d := TextScale.extra(LABEL_HEIGHT, rel)
	%Plank.size = Vector2(w, PLANK_HEIGHT + 2.0 * d)
	%DayLabel.scale = Vector2.ONE * rel
	%DayLabel.position = Vector2(0, DAY_TOP)
	%DayLabel.size = Vector2(w / rel, (LABEL_HEIGHT + d) / rel)
	%Dial.position = Vector2(roundf((w - PLANK_WIDTH) / 2.0), DIAL_TOP + d)
	%TimeLabel.scale = Vector2.ONE * rel
	%TimeLabel.position = Vector2(0, TIME_TOP + d)
	%TimeLabel.size = Vector2(w / rel, (LABEL_HEIGHT + d) / rel)
	_fitted_day = %DayLabel.text
	_fitted_time = %TimeLabel.text
