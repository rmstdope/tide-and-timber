class_name DebugRow
extends RefCounted
## One row on a Debug panel page: a label, an optional value, and what Left/Right and Select do.

enum Result { DONE, REFUSED, RESUME }   # REFUSED: the row shakes; RESUME: the panel and pause close and play resumes

var label: String
var value: Callable    # () -> String; not valid when the row shows no value
var step: Callable     # (delta: int) -> void, delta -1 or 1; not valid when Left/Right do nothing
var select: Callable   # () -> Result; not valid when Select does nothing
var repeats := false   # holding Left/Right keeps stepping

func _init(p_label: String, p_value := Callable(), p_step := Callable(), p_select := Callable()) -> void:
	label = p_label
	value = p_value
	step = p_step
	select = p_select

## value.call() when valid, else "".
func value_text() -> String:
	return str(value.call()) if value.is_valid() else ""
