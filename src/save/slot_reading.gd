class_name SlotReading
extends RefCounted
## What opening one save slot finds. Reads only; never writes, moves or deletes.

enum State { NONE, READY, NEWER, BROKEN }

var state: State = State.NONE
var data: SaveData = null          # set only when READY: migrated, parsed, accepted by the beach

static func open(dir: String = SaveStore.SLOT_DIR,
		steps: Dictionary[int, Callable] = SaveMigrations.chain()) -> SlotReading:
	var reading := SlotReading.new()
	if not SaveStore.exists(dir):
		return reading
	reading.state = State.BROKEN
	var files := SaveStore.read(dir)
	var meta: Variant = files.get("meta")
	if not meta is Dictionary or not SaveMigrations.is_whole(meta.get("version")):
		return reading
	if int(meta["version"]) > SaveData.VERSION:
		reading.state = State.NEWER   # whatever meta.game_version says: the title shows no version
		return reading
	var migrated: Variant = SaveMigrations.migrate(files, steps)
	if migrated == null:
		return reading
	var loaded := SaveData.from_files(migrated)
	if loaded == null or not Beach.can_restore(loaded):
		return reading
	reading.state = State.READY
	reading.data = loaded
	return reading
