class_name DisplayPrefs
extends RefCounted
## The three display settings, with no nodes: UI size, Text size, Colour cues. Saved apart from the island.

signal changed                      # after a mutation that changed a value, once it is saved

enum Size { NORMAL, LARGE, LARGEST }
enum Cues { STANDARD, SHAPES }
enum Setting { UI_SIZE, TEXT_SIZE, CUES }

const PATH := "user://display.json"
const VERSION := 1
const KEYS := {Setting.UI_SIZE: "ui_size", Setting.TEXT_SIZE: "text_size", Setting.CUES: "cues"}
const FILE_WORDS := {
	Setting.UI_SIZE: ["normal", "large", "largest"],
	Setting.TEXT_SIZE: ["normal", "large", "largest"],
	Setting.CUES: ["standard", "shapes"],
}

var ui_size: Size = Size.NORMAL
var text_size: Size = Size.NORMAL
var cues: Cues = Cues.STANDARD
var path: String                    # "" = never written (tests, and the gdUnit command-line run)

## Normal / Normal / Standard; writes nothing.
func _init(p_path: String = "") -> void:
	path = p_path

## Reads p_path all or nothing: anything missing or unreadable gives the defaults. Never fails, never writes.
static func load_from(p_path: String) -> DisplayPrefs:
	var p := DisplayPrefs.new(p_path)
	if p_path == "" or not FileAccess.file_exists(p_path):
		return p
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(p_path)) != OK or not json.data is Dictionary:
		return p
	var d: Dictionary = json.data
	var version: Variant = d.get("version")
	if typeof(version) != TYPE_FLOAT or version != 1.0:
		return p
	var found := {}
	for s: Setting in KEYS:
		var word: Variant = d.get(KEYS[s])
		if typeof(word) != TYPE_STRING or not (word as String) in FILE_WORDS[s]:
			return p
		found[s] = FILE_WORDS[s].find(word)
	p.ui_size = found[Setting.UI_SIZE]
	p.text_size = found[Setting.TEXT_SIZE]
	p.cues = found[Setting.CUES]
	return p

## How many values the setting has.
static func count(s: Setting) -> int:
	return FILE_WORDS[s].size()

## The enum value of that setting.
func value(s: Setting) -> int:
	match s:
		Setting.UI_SIZE:
			return ui_size
		Setting.TEXT_SIZE:
			return text_size
		Setting.CUES:
			return cues
	assert(false, "no value for setting %d" % s)
	return 0

## Moves the setting by delta, stopping at its ends. True, saved and announced, if the value changed.
func step(s: Setting, delta: int) -> bool:
	var v := clampi(value(s) + delta, 0, count(s) - 1)
	if v == value(s):
		return false
	match s:
		Setting.UI_SIZE:
			ui_size = v as Size
		Setting.TEXT_SIZE:
			text_size = v as Size
		Setting.CUES:
			cues = v as Cues
	save()   # nothing is agreed for a failed write; the next change tries again
	changed.emit()
	return true

func to_dict() -> Dictionary:
	var d := {"version": VERSION}
	for s: Setting in KEYS:
		d[KEYS[s]] = FILE_WORDS[s][value(s)]
	return d

## Writes the file directly, with no .tmp swap. OK at once when path is "".
func save() -> Error:
	if path == "":
		return OK
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("display settings not saved: %s" % path)
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return OK
