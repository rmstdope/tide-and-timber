class_name Item
extends RefCounted
## The kinds of thing the man can carry, their names and icons.

enum Kind { DRIFTWOOD, SHELLFISH, COCONUT, EMPTY_SHELL, FRESH_WATER }
const NAMES: Array[String] = ["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water"]
const ICONS: Array[Texture2D] = [
	preload("res://assets/items/driftwood.png"), preload("res://assets/items/shellfish.png"),
	preload("res://assets/items/coconut.png"), preload("res://assets/items/empty_shell.png"),
	preload("res://assets/items/fresh_water.png")]

static func name_of(kind: Kind) -> String:
	return NAMES[kind]

static func icon_of(kind: Kind) -> Texture2D:
	return ICONS[kind]

static func gain_line(kind: Kind, amount: int) -> String:
	return "+%d %s" % [amount, name_of(kind)]
