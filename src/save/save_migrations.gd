class_name SaveMigrations
extends RefCounted
## Brings an older slot's parsed files up to SaveData.VERSION, in memory. Never touches disk.

## The real chain: key n is the step from version n to n+1.
## A bead that bumps SaveData.VERSION from n to n+1 adds `n: _from_n` here, and a test for it.
## A step is func(files: Dictionary) -> Variant: it returns the files at n+1 (changed in place or new),
## or null to refuse. It need not set meta.version. GDScript cannot catch a runtime error, so a step
## must never raise one: check what it reads and refuse instead.
static func chain() -> Dictionary[int, Callable]:
	var steps: Dictionary[int, Callable] = {}
	return steps

## `files` is what SaveStore.read returns. Returns a deep copy brought up to `target`, or null when
## the save is older than `target` and a step on the way is missing or refuses.
## A copy is returned unchanged (no step runs) when meta or its version is absent or not a whole
## number, or the version is already `target` or newer: from_files and SlotReading judge those.
static func migrate(files: Dictionary, steps: Dictionary[int, Callable] = chain(),
		target: int = SaveData.VERSION) -> Variant:
	var out := files.duplicate(true)
	if not out.get("meta") is Dictionary or not is_whole(out["meta"].get("version")):
		return out
	var v := int(out["meta"]["version"])
	while v < target:
		if not steps.has(v):
			return null
		var next: Variant = steps[v].call(out)
		if not next is Dictionary or not next.get("meta") is Dictionary:
			return null
		out = next
		out["meta"]["version"] = v + 1
		v += 1
	return out

## An int, or a float with no fractional part (JSON numbers always arrive as floats).
static func is_whole(value: Variant) -> bool:
	var number := typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
	return number and float(value) == floorf(float(value))
