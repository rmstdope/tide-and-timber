class_name IntroStory
extends RefCounted
## The shipwreck story's rules, with no nodes: which panel shows, taps, hold to skip and pausing.

signal finished                         # emitted exactly once, when phase becomes FINISHED

enum Phase { PLAYING, PAUSED, SKIPPING, FINISHED }

const PANEL_COUNT := 4                  # three pictures, then the black beat (index 3)
const BLACK_BEAT := 3
const PANEL_SECONDS := 6.0
const PANEL_FADE_SECONDS := 0.5
const HOLD_SECONDS := 1.0               # the ring fills in this long, and drains at the same rate
const TAP_MAX_SECONDS := 0.25           # a press released sooner than this is a tap
const SKIP_FADE_SECONDS := 0.5
const TAP_MARKER_BLINK_SECONDS := 1.0   # visible for the first half of each period

var phase: Phase = Phase.PLAYING
var panel := 0
var panel_elapsed := 0.0
var skip_hint_shown := false            # set by the first press; never cleared
var hold_progress := 0.0                # 0..1
var held_count := 0                     # presses minus releases while PLAYING; never negative
var press_elapsed := 0.0                # time since held_count went from 0 to 1
var skip_elapsed := 0.0

func advance(delta: float) -> void:
	match phase:
		Phase.PLAYING:
			if held_count > 0:
				press_elapsed += delta
				hold_progress = minf(1.0, hold_progress + delta / HOLD_SECONDS)
				if hold_progress >= 1.0:
					_start_skip()
					return
			else:
				hold_progress = maxf(0.0, hold_progress - delta / HOLD_SECONDS)
			panel_elapsed += delta
			if panel_elapsed >= PANEL_SECONDS:
				_next_panel()
		Phase.SKIPPING:
			skip_elapsed += delta
			if skip_elapsed >= SKIP_FADE_SECONDS:
				_finish()

func press() -> void:
	if phase != Phase.PLAYING:
		return
	skip_hint_shown = true
	if held_count == 0:
		press_elapsed = 0.0
	held_count += 1

func release() -> void:
	if phase != Phase.PLAYING or held_count <= 0:
		return
	held_count -= 1
	if held_count == 0 and press_elapsed < TAP_MAX_SECONDS:
		_next_panel()

func toggle_pause() -> void:
	if phase == Phase.PLAYING:
		phase = Phase.PAUSED
		held_count = 0
		hold_progress = 0.0
	elif phase == Phase.PAUSED:
		phase = Phase.PLAYING

## Skip story from the pause board: what a full ring does. Ignored unless PAUSED.
func skip() -> void:
	if phase == Phase.PAUSED:
		_start_skip()

func panel_cover_alpha() -> float:
	return 1.0 - clampf(panel_elapsed / PANEL_FADE_SECONDS, 0.0, 1.0)

func skip_cover_alpha() -> float:
	match phase:
		Phase.SKIPPING:
			return clampf(skip_elapsed / SKIP_FADE_SECONDS, 0.0, 1.0)
		Phase.FINISHED:
			return 1.0
	return 0.0

func tap_marker_visible() -> bool:
	return panel != BLACK_BEAT and phase != Phase.FINISHED \
		and fmod(panel_elapsed, TAP_MARKER_BLINK_SECONDS) < TAP_MARKER_BLINK_SECONDS / 2.0

func surf_audible() -> bool:
	return panel == BLACK_BEAT and (phase == Phase.PLAYING or phase == Phase.SKIPPING)

func _next_panel() -> void:
	if panel == BLACK_BEAT:
		_finish()
	else:
		panel += 1
		panel_elapsed = 0.0

func _start_skip() -> void:
	phase = Phase.SKIPPING
	skip_elapsed = 0.0
	held_count = 0

func _finish() -> void:
	phase = Phase.FINISHED
	finished.emit()
