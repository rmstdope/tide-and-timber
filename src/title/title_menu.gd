class_name TitleMenu
extends RefCounted
## The title menu's rules, with no nodes: which planks, the one highlight, the two boxes, and what a pick leads to.

enum Choice { NEW_GAME, QUIT, CONTINUE }            # CONTINUE appended so existing values keep their numbers
enum Box { NONE, START_OVER, CANNOT_OPEN }
enum BoxButton { KEEP_MY_ISLAND, START_OVER, OK }
enum Action { NONE, QUIT, NEW_GAME, CONTINUE }      # what the view must do after a pick or press

var choices: Array[Choice] = []                     # top to bottom
var highlighted: Choice = Choice.NEW_GAME           # the one highlighted plank
var locked := false                                 # true once a fade starts; never cleared
var box: Box = Box.NONE
var box_selected: BoxButton = BoxButton.KEEP_MY_ISLAND
var save_exists := false
var save_opens := false                             # the save loads and the beach accepts it

func _init(has_save := false, opens := false) -> void:
	save_exists = has_save
	save_opens = has_save and opens
	if has_save:
		choices = [Choice.CONTINUE, Choice.NEW_GAME, Choice.QUIT]
		highlighted = Choice.CONTINUE
	else:
		choices = [Choice.NEW_GAME, Choice.QUIT]

func move(step: int) -> void:
	if locked or box != Box.NONE:
		return
	highlighted = choices[posmod(choices.find(highlighted) + step, choices.size())]

func hover(choice: Choice) -> void:
	if locked or box != Box.NONE or not choice in choices:
		return
	highlighted = choice

func pick(choice: Choice) -> Action:
	if locked or box != Box.NONE or not choice in choices:
		return Action.NONE
	highlighted = choice
	match choice:
		Choice.QUIT:
			return Action.QUIT
		Choice.NEW_GAME:
			if save_exists:
				_open(Box.START_OVER, BoxButton.KEEP_MY_ISLAND)
				return Action.NONE
			locked = true
			return Action.NEW_GAME
	if save_opens:
		locked = true
		return Action.CONTINUE
	_open(Box.CANNOT_OPEN, BoxButton.OK)
	return Action.NONE

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
		Box.CANNOT_OPEN:
			return press_box(BoxButton.OK)
	return Action.NONE

func _open(which: Box, selected: BoxButton) -> void:
	box = which
	box_selected = selected

func _in_box(button: BoxButton) -> bool:
	match box:
		Box.START_OVER:
			return button == BoxButton.KEEP_MY_ISLAND or button == BoxButton.START_OVER
		Box.CANNOT_OPEN:
			return button == BoxButton.OK
	return false
