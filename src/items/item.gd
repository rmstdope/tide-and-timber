class_name Item
extends RefCounted
## The kinds of thing the man can carry, their names and icons.

enum Kind { DRIFTWOOD, SHELLFISH, COCONUT, EMPTY_SHELL, FRESH_WATER }
const NAMES: Array[String] = ["Driftwood", "Shellfish", "Coconut", "Empty shell", "Fresh water"]
const IDS: Array[String] = ["driftwood", "shellfish", "coconut", "empty_shell", "fresh_water"]   # Kind order; written into save files, never renamed
const ICONS: Array[Texture2D] = [
	preload("res://assets/items/driftwood.png"), preload("res://assets/items/shellfish.png"),
	preload("res://assets/items/coconut.png"), preload("res://assets/items/empty_shell.png"),
	preload("res://assets/items/fresh_water.png")]

static func name_of(kind: Kind) -> String:
	return NAMES[kind]

static func id_of(kind: Kind) -> String:
	return IDS[kind]

## The Kind a save file's id names, or -1 when unknown.
static func kind_for_id(id: String) -> int:
	return IDS.find(id)

static func icon_of(kind: Kind) -> Texture2D:
	return ICONS[kind]

static func gain_line(kind: Kind, amount: int) -> String:
	return "+%d %s" % [amount, name_of(kind)]
