class_name SettingsMenu
extends RefCounted
## The Settings board's rules, with no nodes: its planks and value rows, the one highlight, where it was opened from, and what a pick leads to.

enum Plank { CONTROLS, UI_SIZE, TEXT_SIZE, COLOUR_CUES, FULLSCREEN }
enum Outcome { NONE, OPEN_CONTROLS, CLOSED, RESUME_PLAY }

const SETTING_OF := {
	Plank.UI_SIZE: DisplayPrefs.Setting.UI_SIZE,
	Plank.TEXT_SIZE: DisplayPrefs.Setting.TEXT_SIZE,
	Plank.COLOUR_CUES: DisplayPrefs.Setting.CUES,
	Plank.FULLSCREEN: DisplayPrefs.Setting.FULLSCREEN,
}

var items: Array[Plank] = [Plank.UI_SIZE, Plank.TEXT_SIZE, Plank.COLOUR_CUES, Plank.FULLSCREEN, Plank.CONTROLS]   # top to bottom
var is_open := false
var from_pause := false                                  # opened from the Paused board, not the title
var highlighted: Plank = Plank.UI_SIZE
var controls_open := false                               # the Controls page is over the board; the board takes no input

## Opens on UI_SIZE. False, changing nothing, if already open.
func open(p_from_pause: bool) -> bool:
	if is_open:
		return false
	is_open = true
	from_pause = p_from_pause
	highlighted = Plank.UI_SIZE
	controls_open = false
	return true

## Ignored unless the board takes input. Wraps round `items`.
func move(step: int) -> void:
	if not _board_takes_input():
		return
	highlighted = items[posmod(items.find(highlighted) + step, items.size())]

## Ignored unless the board takes input, or item is not in `items`.
func hover(item: Plank) -> void:
	if _board_takes_input() and item in items:
		highlighted = item

## CONTROLS: highlights it and returns OPEN_CONTROLS. Changes no other state; the Controls page calls show_controls().
## A value row: highlights it only, and returns NONE.
func pick(item: Plank) -> Outcome:
	if not _board_takes_input() or item not in items:
		return Outcome.NONE
	highlighted = item
	if SETTING_OF.has(item):
		return Outcome.NONE
	return Outcome.OPEN_CONTROLS

## Left / right or an arrow click on a value row: highlights item and steps its value by delta.
## True if the value changed. False, changing nothing, unless the board takes input and item is a value row.
func change(item: Plank, delta: int, prefs: DisplayPrefs) -> bool:
	if not _board_takes_input() or not SETTING_OF.has(item):
		return false
	highlighted = item
	return prefs.step(SETTING_OF[item], delta)

## Esc / B: closes the board. CLOSED, or NONE unless the board takes input.
func back() -> Outcome:
	if not _board_takes_input():
		return Outcome.NONE
	is_open = false
	return Outcome.CLOSED

## The Pause input: closes the board and returns RESUME_PLAY when opened from the pause board.
## NONE, changing nothing, from the title or unless the board takes input.
func start() -> Outcome:
	if not _board_takes_input() or not from_pause:
		return Outcome.NONE
	is_open = false
	return Outcome.RESUME_PLAY

## The Controls page opened over the board.
func show_controls() -> void:
	if is_open:
		controls_open = true

## The Controls page closed: the board takes input again, CONTROLS highlighted.
func close_controls() -> void:
	controls_open = false
	highlighted = Plank.CONTROLS

## The Controls page's Start or Leave: closes the board as start() would, whatever controls_open is.
## RESUME_PLAY, or NONE when not open or not from_pause.
func resume_from_controls() -> Outcome:
	if not is_open or not from_pause:
		return Outcome.NONE
	controls_open = false
	is_open = false
	return Outcome.RESUME_PLAY

func _board_takes_input() -> bool:
	return is_open and not controls_open
