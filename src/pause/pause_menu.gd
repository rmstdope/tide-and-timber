class_name PauseMenu
extends RefCounted
## The pause board's rules, with no nodes: which planks, the one highlight, the quit box, and what a pick leads to.

enum Plank { RESUME, SKIP_STORY, SETTINGS, QUIT_TO_TITLE }
enum Choice { STAY, QUIT }
enum Outcome { NONE, RESUMED, SKIP_STORY, OPEN_SETTINGS, QUITTING }

const SAVED_LINE := "Anything since this morning will be lost."
const UNSAVED_LINE := "Nothing has been saved yet."

var items: Array[Plank] = []         # [RESUME, SETTINGS, QUIT_TO_TITLE], with SKIP_STORY second when with_skip_story
var is_open := false
var highlighted: Plank = Plank.RESUME
var box_open := false
var box_selected: Choice = Choice.STAY
var quitting := false               # set by pressing QUIT; never cleared

func _init(with_skip_story := false) -> void:
	items.append(Plank.RESUME)
	if with_skip_story:
		items.append(Plank.SKIP_STORY)
	items.append(Plank.SETTINGS)
	items.append(Plank.QUIT_TO_TITLE)

## Opens the board on RESUME with the box closed. False, changing nothing, if already open or quitting.
func open() -> bool:
	if is_open or quitting:
		return false
	is_open = true
	highlighted = Plank.RESUME
	box_open = false
	box_selected = Choice.STAY
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

func pick(item: Plank) -> Outcome:
	if not _board_takes_input() or item not in items:
		return Outcome.NONE
	highlighted = item
	match item:
		Plank.RESUME:
			is_open = false
			return Outcome.RESUMED
		Plank.SKIP_STORY:
			is_open = false
			return Outcome.SKIP_STORY
		Plank.SETTINGS:
			return Outcome.OPEN_SETTINGS
	box_open = true
	box_selected = Choice.STAY
	return Outcome.NONE

## Esc / Start / B on the board: pick(RESUME).
func back() -> Outcome:
	return pick(Plank.RESUME)

## Ignored unless box_open and not quitting.
func box_select(choice: Choice) -> void:
	if box_open and not quitting:
		box_selected = choice

func box_press(choice: Choice) -> Outcome:
	if not box_open or quitting:
		return Outcome.NONE
	box_selected = choice
	if choice == Choice.QUIT:
		quitting = true
		return Outcome.QUITTING
	box_open = false
	highlighted = Plank.QUIT_TO_TITLE
	return Outcome.NONE

## Esc / B in the box: box_press(STAY).
func box_cancel() -> Outcome:
	return box_press(Choice.STAY)

## The quit box's second line.
static func quit_warning(saved: bool) -> String:
	return SAVED_LINE if saved else UNSAVED_LINE

func _board_takes_input() -> bool:
	return is_open and not box_open and not quitting
