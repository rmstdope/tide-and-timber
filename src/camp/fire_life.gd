class_name FireLife
extends RefCounted
## When a lit camp fire goes out: the first 07:00 strictly after it was lit.

const OUT_MINUTE_OF_DAY := 420   # 07:00

## Total game minutes at which a fire lit at lit_at goes out.
static func out_at(lit_at: float) -> float:
	var day_start := floorf(lit_at / GameClock.MINUTES_PER_DAY) * GameClock.MINUTES_PER_DAY
	var candidate := day_start + OUT_MINUTE_OF_DAY
	if candidate <= lit_at:
		candidate += GameClock.MINUTES_PER_DAY
	return candidate

## True once the clock has reached the burn-out time.
static func is_out(p_out_at: float, now: float) -> bool:
	return now >= p_out_at
