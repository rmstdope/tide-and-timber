class_name SaveStore
extends RefCounted
## Where saves live on disk and how a slot's files are written and read. Knows nothing of the game.

const SLOT_DIR := "user://saves/slot_1"   # the one slot this game has; a slots UI is out of scope
const STEMS: Array[String] = ["player", "inventory", "world", "meta"]   # write order: meta last

## Whether `dir` holds a save: its meta.json exists.
static func exists(dir: String = SLOT_DIR) -> bool:
	return FileAccess.file_exists(_path(dir, "meta"))

## Writes each entry of `files` as `<dir>/<stem>.json`. Returns OK, or the first error met.
## Every file goes to a .tmp first and replaces its final name only once all are written, meta last,
## so a crash mid-write never leaves a new meta.json beside half-written data.
static func write(files: Dictionary, dir: String = SLOT_DIR) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir)
	if err != OK:
		return err
	var stems := STEMS.filter(func(stem: String) -> bool: return files.has(stem))
	for stem: String in stems:
		var f := FileAccess.open(_path(dir, stem) + ".tmp", FileAccess.WRITE)
		if f == null:
			return FileAccess.get_open_error()
		var stored := f.store_string(JSON.stringify(files[stem], "\t"))
		f.close()
		if not stored:
			return ERR_FILE_CANT_WRITE
	for stem: String in stems:
		var final := _path(dir, stem)
		if FileAccess.file_exists(final):
			err = DirAccess.remove_absolute(final)
			if err != OK:
				return err
		err = DirAccess.rename_absolute(final + ".tmp", final)
		if err != OK:
			return err
	return OK

## Every `<stem>.json` in STEMS that exists and parses, as {stem: parsed value}. Missing or unparsable files are left out.
static func read(dir: String = SLOT_DIR) -> Dictionary:
	var out := {}
	for stem in STEMS:
		var path := _path(dir, stem)
		if not FileAccess.file_exists(path):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK:
			out[stem] = json.data
	return out

static func save_slot(data: SaveData, dir: String = SLOT_DIR) -> Error:
	return write(data.to_files(), dir)

static func load_slot(dir: String = SLOT_DIR) -> SaveData:
	return SaveData.from_files(read(dir))

static func _path(dir: String, stem: String) -> String:
	return dir.path_join(stem + ".json")
