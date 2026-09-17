class_name DebugTime
extends RefCounted
## The Debug panel's Time page: Day, Time and Speed over a DayNight.

const SPEEDS: Array[float] = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0]
const FIRST_DAY := 1
const LAST_DAY := 99
const STEP_MINUTES := 30
const DAY_LABEL := "Day"
const TIME_LABEL := "Time"
const SPEED_LABEL := "Speed"

## total moved `delta` (-1 or 1) days, same time of day; total unchanged when the day would leave FIRST_DAY..LAST_DAY.
static func day_after(total: float, delta: int) -> float:
	var m := float(GameClock.MINUTES_PER_DAY)
	var d := int(floor(total / m)) + 1 + delta
	if d < FIRST_DAY or d > LAST_DAY:
		return total
	return total + delta * m

## The next half-hour strictly after total (delta 1) or strictly before it (delta -1), across midnight;
## total unchanged when the result is below 0 or at or past LAST_DAY * MINUTES_PER_DAY.
static func time_after(total: float, delta: int) -> float:
	var s := float(STEP_MINUTES)
	var t: float = (floor(total / s) + 1.0) * s if delta > 0 else (ceil(total / s) - 1.0) * s
	if t < 0.0 or t >= LAST_DAY * GameClock.MINUTES_PER_DAY:
		return total
	return t

## The nearest SPEEDS entry strictly above scale (delta 1) or strictly below (delta -1); scale unchanged when none.
static func speed_after(scale: float, delta: int) -> float:
	if delta > 0:
		for s in SPEEDS:
			if s > scale:
				return s
	else:
		for i in range(SPEEDS.size() - 1, -1, -1):
			if SPEEDS[i] < scale:
				return SPEEDS[i]
	return scale

## "x0.25", "x0.5", "x1", "x32"; "x60" for a --clock-speed outside SPEEDS.
static func speed_text(scale: float) -> String:
	var whole := roundf(scale) == scale   # String.num(1.0) is "1.0" in Godot 4.7
	return "x" + (str(int(scale)) if whole else String.num(scale))
