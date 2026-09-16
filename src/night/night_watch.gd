class_name NightWatch
extends RefCounted
## The night's danger: the 20:30 warning, the 5 seconds outside the firelight, the frost, the collapse.

signal warned          ## 20:30 passed while he was outside the firelight
signal stepped_out     ## he is outside the firelight at night, and was not a moment ago
signal collapsed       ## 5 seconds outside; emitted once, then the watch stops until reset

const WARN_MINUTE := 1230          # 20:30
const NIGHT_START_MINUTE := 1260   # 21:00
const NIGHT_END_MINUTE := 300      # 05:00
const WAKE_MINUTE := 360           # 06:00
const GRACE_SECONDS := 5.0
const MELT_SECONDS := 1.0          # full frost melts away in this long

var outside := false               # in danger now
var outside_seconds := 0.0         # real seconds since he last stepped out
var frost := 0.0                   # 0..1
var has_collapsed := false
var _warnings_passed := 0

static func is_night(minute_of_day: float) -> bool:
	return minute_of_day >= NIGHT_START_MINUTE or minute_of_day < NIGHT_END_MINUTE

static func warnings_passed(total_minutes: float) -> int:
	return int(floor((total_minutes - WARN_MINUTE) / GameClock.MINUTES_PER_DAY))

## The first 06:00 strictly after total_minutes.
static func next_morning(total_minutes: float) -> float:
	var c := floorf(total_minutes / GameClock.MINUTES_PER_DAY) * GameClock.MINUTES_PER_DAY + WAKE_MINUTE
	if c <= total_minutes:
		c += GameClock.MINUTES_PER_DAY
	return c

func reset(total_minutes: float) -> void:
	outside = false
	outside_seconds = 0.0
	frost = 0.0
	has_collapsed = false
	_warnings_passed = warnings_passed(total_minutes)

func advance(real_seconds: float, total_minutes: float, in_light: bool) -> void:
	if has_collapsed:
		return
	var w := warnings_passed(total_minutes)
	if w > _warnings_passed:
		_warnings_passed = w
		if not in_light:
			warned.emit()
	var danger := is_night(fposmod(total_minutes, GameClock.MINUTES_PER_DAY)) and not in_light
	if danger and not outside:
		outside = true
		outside_seconds = 0.0
		stepped_out.emit()
	elif danger:
		outside_seconds += real_seconds
	else:
		outside = false
		outside_seconds = 0.0
	if outside:
		frost = maxf(frost, clampf(outside_seconds / GRACE_SECONDS, 0.0, 1.0))
	else:
		frost = maxf(0.0, frost - real_seconds / MELT_SECONDS)
	if outside and outside_seconds >= GRACE_SECONDS:
		has_collapsed = true
		collapsed.emit()
