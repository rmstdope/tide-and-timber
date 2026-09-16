class_name GameClock
extends RefCounted
## The in-game time, with no nodes. Continuous minutes since DAY 1 00:00.

const MINUTES_PER_DAY := 1440
const START_MINUTES := 780                 # DAY 1, 13:00
const REAL_SECONDS_PER_GAME_HOUR := 90.0   # 1½ real minutes
const STEP_MINUTES := 10                   # the shown time moves in 10-minute steps
const DAY_START_MINUTE := 360              # 06:00: the sun starts
const NIGHT_START_MINUTE := 1200           # 20:00: the moon starts
const SUNSET_LINE_MINUTE := 1110           # 18:30

var total_minutes: float = START_MINUTES


func advance(real_seconds: float) -> void:
	total_minutes += real_seconds * 60.0 / REAL_SECONDS_PER_GAME_HOUR


func minute_of_day() -> float:
	return fposmod(total_minutes, MINUTES_PER_DAY)


func shown_minute_of_day() -> int:
	return int(floor(minute_of_day() / STEP_MINUTES)) * STEP_MINUTES


func day() -> int:
	return 1 + int(floor(total_minutes / MINUTES_PER_DAY))


func day_text() -> String:
	return "DAY %d" % day()


func time_text() -> String:
	var shown := shown_minute_of_day()
	return "%02d:%02d" % [shown / 60, shown % 60]


func is_day() -> bool:
	var shown := shown_minute_of_day()
	return DAY_START_MINUTE <= shown and shown < NIGHT_START_MINUTE


func dial_fraction() -> float:
	var shown := shown_minute_of_day()
	if is_day():
		return (shown - DAY_START_MINUTE) / 840.0
	return posmod(shown - NIGHT_START_MINUTE, MINUTES_PER_DAY) / 600.0


func sunsets_passed() -> int:
	return int(floor((total_minutes - SUNSET_LINE_MINUTE) / MINUTES_PER_DAY))
