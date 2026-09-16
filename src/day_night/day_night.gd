class_name DayNight
extends Node
## The day/night clock: owns the time, tints the world, shows the dial and the 18:30 line.
## Instance day_night.tscn and call start() when the player gets control.

var clock := GameClock.new()
var sunset := SunsetLine.new()
var running := false
var time_scale := 1.0   # multiplies game time only; 1.0 in the game; the preview raises it


func _ready() -> void:
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
	clock.advance(real_seconds * time_scale)
	sunset.advance(real_seconds)
	if clock.sunsets_passed() > before:
		sunset.start()
	_refresh()


func _refresh() -> void:
	%Light.color = Daylight.color_at(clock.minute_of_day())
	%DayLabel.text = clock.day_text()
	%TimeLabel.text = clock.time_text()
	%Dial.fraction = clock.dial_fraction()
	%Dial.is_day = clock.is_day()
	%Dial.queue_redraw()
	%Sunset.visible = sunset.is_showing()
	%Sunset.modulate.a = sunset.alpha()
