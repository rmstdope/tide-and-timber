class_name DawnSave
extends RefCounted
## What happens at dawn: save, then the dawn line or the failure box. No nodes, no disk.

enum Choice { TRY_AGAIN, KEEP_PLAYING }
const LINE_HOLD_SECONDS := 3.0

var line := SunsetLine.new(LINE_HOLD_SECONDS)
var box_open := false
var selected: Choice = Choice.TRY_AGAIN
var failed_retries := 0          # +1 on every Try again that fails; the view shakes the first line on each rise
var _save: Callable              # () -> Error

func _init(save: Callable) -> void:
	_save = save

## Saves now. OK: the line starts. Not OK: the box opens with Try again selected.
func dawn() -> void:
	if box_open:
		return
	if _save.call() == OK:
		line.start()
	else:
		box_open = true
		selected = Choice.TRY_AGAIN

## Real seconds; only the line moves.
func advance(real_seconds: float) -> void:
	line.advance(real_seconds)

## Ignored unless box_open.
func select(button: Choice) -> void:
	if box_open:
		selected = button

## Ignored unless box_open.
func press(button: Choice) -> void:
	if not box_open:
		return
	if button == Choice.KEEP_PLAYING:
		box_open = false
		return
	selected = Choice.TRY_AGAIN
	if _save.call() == OK:
		box_open = false
		line.start()
	else:
		failed_retries += 1

## Esc / B.
func cancel() -> void:
	press(Choice.KEEP_PLAYING)
