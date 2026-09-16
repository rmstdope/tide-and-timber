class_name TitleMenu
extends RefCounted
## The title menu's selection rules, with no nodes.

enum Choice { NEW_GAME, QUIT }
const CHOICE_COUNT := 2

var highlighted: Choice = Choice.NEW_GAME   # the one highlighted plank
var locked := false                         # true once New Game is picked; never cleared

func move(step: int) -> void:
	if locked:
		return
	highlighted = posmod(highlighted + step, CHOICE_COUNT) as Choice

func hover(choice: Choice) -> void:
	if locked:
		return
	highlighted = choice

func pick(choice: Choice) -> bool:
	if locked:
		return false
	highlighted = choice
	locked = choice == Choice.NEW_GAME
	return true
