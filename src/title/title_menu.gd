class_name TitleMenu
extends RefCounted
## The title menu's rules, with no nodes: which planks, the one highlight, the two boxes, and what a pick leads to.

enum Choice { NEW_GAME, QUIT, CONTINUE }            # CONTINUE appended so existing values keep their numbers
enum Box { NONE, START_OVER, REPLACE }             # REPLACE: New Game over a save that cannot be read
enum BoxButton { KEEP_MY_ISLAND, START_OVER, CANCEL }
enum Action { NONE, QUIT, NEW_GAME, CONTINUE }      # what the view must do after a pick or press

var choices: Array[Choice] = []                     # top to bottom
var highlighted: Choice = Choice.NEW_GAME           # the one highlighted plank
var locked := false                                 # true once a fade starts; never cleared
var box: Box = Box.NONE
var box_selected: BoxButton = BoxButton.KEEP_MY_ISLAND
var save_exists := false
var save_opens := false                             # the save loads and the beach accepts it
var continue_dimmed := false                        # a save exists but cannot be read: Continue drawn, never selectable

func _init(has_save := false, opens := false) -> void:
	save_exists = has_save
	save_opens = has_save and opens
	continue_dimmed = has_save and not opens
	if has_save:
		choices = [Choice.CONTINUE, Choice.NEW_GAME, Choice.QUIT]
		highlighted = Choice.NEW_GAME if continue_dimmed else Choice.CONTINUE
	else:
		choices = [Choice.NEW_GAME, Choice.QUIT]

func move(step: int) -> void:
	if locked or box != Box.NONE:
		return
	var s := selectable()
	highlighted = s[posmod(s.find(highlighted) + step, s.size())]

## The choices the highlight may land on: all but a dimmed Continue.
func selectable() -> Array[Choice]:
	if not continue_dimmed:
		return choices
	var s: Array[Choice] = choices.filter(func(c: Choice) -> bool: return c != Choice.CONTINUE)
	return s

func hover(choice: Choice) -> void:
	if locked or box != Box.NONE or not choice in selectable():
		return
	highlighted = choice

func pick(choice: Choice) -> Action:
	if locked or box != Box.NONE or not choice in selectable():
		return Action.NONE
	highlighted = choice
	match choice:
		Choice.QUIT:
			return Action.QUIT
		Choice.NEW_GAME:
			if continue_dimmed:
				_open(Box.REPLACE, BoxButton.CANCEL)
				return Action.NONE
			if save_exists:
				_open(Box.START_OVER, BoxButton.KEEP_MY_ISLAND)
				return Action.NONE
			locked = true
			return Action.NEW_GAME
	locked = true   # CONTINUE is selectable only when the save opens
	return Action.CONTINUE

func select_box(button: BoxButton) -> void:
	if _in_box(button):
		box_selected = button

func press_box(button: BoxButton) -> Action:
	if locked or not _in_box(button):
		return Action.NONE
	box_selected = button
	box = Box.NONE
	if button == BoxButton.START_OVER:
		locked = true
		return Action.NEW_GAME
	highlighted = Choice.NEW_GAME
	return Action.NONE

## Esc / B: the box's safe button.
func cancel_box() -> Action:
	match box:
		Box.START_OVER:
			return press_box(BoxButton.KEEP_MY_ISLAND)
		Box.REPLACE:
			return press_box(BoxButton.CANCEL)
	return Action.NONE

func _open(which: Box, selected: BoxButton) -> void:
	box = which
	box_selected = selected

func _in_box(button: BoxButton) -> bool:
	match box:
		Box.START_OVER:
			return button == BoxButton.KEEP_MY_ISLAND or button == BoxButton.START_OVER
		Box.REPLACE:
			return button == BoxButton.CANCEL or button == BoxButton.START_OVER
	return false
