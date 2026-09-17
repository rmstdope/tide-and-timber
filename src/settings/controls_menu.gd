class_name ControlsMenu
extends RefCounted
## The Controls page's rules, with no nodes: the tab, the highlighted row and slot, the open box,
## the no-key line, and what each press leads to. Changes go through a Controls model, which saves.

enum Box { NONE, RESET, LEAVING, WAITING, NO_PAD }
enum BoxButton { SAFE, OTHER }                 # SAFE: Keep mine / Set a key (left); OTHER: Reset / Leave (right)
enum Outcome { NONE, CLOSED, RESUME_PLAY, CHANGE_SLOT }

const ROWS := 9                                # the eight Controls.Action rows, then the Reset row
const RESET_ROW := 8
const LEAVE_QUESTION := "Leave anyway?"
const SOME_ACTIONS := "Some actions have no key."
const RESET_KEYBOARD := "Put every keyboard key back as it was?"
const RESET_CONTROLLER := "Put every controller button back as it was?"
const PRESS_KEY := "Press a new key"
const PRESS_BUTTON := "Press a new button"
const NO_PAD_LINE := "Connect a controller to change its buttons."

var controls: Controls
var is_open := false
var from_pause := false
var device: Controls.Device = Controls.Device.KEYBOARD   # the tab showing
var row := 0                                   # 0..RESET_ROW
var slot := 0                                  # 0..slot_count(device) - 1; kept but unused on RESET_ROW
var box: Box = Box.NONE
var box_selected: BoxButton = BoxButton.SAFE
var leaving_by_start := false                  # the LEAVING box was opened by Start, not Back
var no_key_line := ""                          # "<Action> has no key", or ""

func _init(p_controls: Controls) -> void:
	controls = p_controls

## Opens on this tab, on row 0 slot 0, with no box and no line.
func open(p_device: Controls.Device, p_from_pause: bool) -> void:
	is_open = true
	from_pause = p_from_pause
	device = p_device
	row = 0
	slot = 0
	box = Box.NONE
	box_selected = BoxButton.SAFE
	leaving_by_start = false
	no_key_line = ""

## The highlighted action, or -1 on the Reset row.
func action() -> int:
	return -1 if row == RESET_ROW else row

## Up/down: wraps round the ROWS rows.
func move(step: int) -> void:
	if not _page_takes_input():
		return
	row = posmod(row + step, ROWS)

## Left/right: -1 or +1 slot, stopping at 0 and slot_count(device) - 1. Nothing on the Reset row.
func side(step: int) -> void:
	if not _page_takes_input() or row == RESET_ROW:
		return
	slot = clampi(slot + step, 0, Controls.slot_count(device) - 1)

## Q / E / LB / RB: the other tab, keeping the row; slot clamps to the new tab's last slot.
func switch_tab() -> void:
	if not _page_takes_input():
		return
	_set_tab(Controls.Device.CONTROLLER if device == Controls.Device.KEYBOARD else Controls.Device.KEYBOARD)

## A click on a tab.
func set_tab(p_device: Controls.Device) -> void:
	if not _page_takes_input():
		return
	_set_tab(p_device)

## The pointer moved over a slot (p_slot >= 0) or the Reset row (p_row == RESET_ROW, p_slot ignored). Does not clear the line.
func hover(p_row: int, p_slot: int) -> void:
	if not is_open or box != Box.NONE:
		return
	row = p_row
	if p_row != RESET_ROW:
		slot = clampi(p_slot, 0, Controls.slot_count(device) - 1)

## Enter / A / a click on the highlight: CHANGE_SLOT on a slot; opens the RESET box on the Reset row.
func pick() -> Outcome:
	if not _page_takes_input():
		return Outcome.NONE
	if row == RESET_ROW:
		box = Box.RESET
		box_selected = BoxButton.SAFE
		return Outcome.NONE
	return Outcome.CHANGE_SLOT

## Delete / Backspace / X: empties the highlighted slot; sets the line if the action is left with no key on this tab.
func clear() -> void:
	if not _page_takes_input():
		return
	if row == RESET_ROW or controls.slot(row as Controls.Action, device, slot) == null:
		return
	controls.clear_slot(row as Controls.Action, device, slot)
	if controls.has_no_key(row as Controls.Action, device):
		no_key_line = "%s has no key" % Controls.NAMES[row]

## Esc / B: CLOSED, or opens the LEAVING box when any action has no key on either tab.
func back() -> Outcome:
	if not _page_takes_input():
		return Outcome.NONE
	if empty_actions().is_empty():
		is_open = false
		return Outcome.CLOSED
	_open_leaving(false)
	return Outcome.NONE

## The player's Pause input. From the title: NONE, changing nothing. From the pause board: RESUME_PLAY, or the LEAVING box.
func start() -> Outcome:
	if not is_open or not from_pause:
		return Outcome.NONE
	no_key_line = ""
	if box != Box.NONE:
		return Outcome.NONE
	if empty_actions().is_empty():
		is_open = false
		return Outcome.RESUME_PLAY
	_open_leaving(true)
	return Outcome.NONE

## After pick() gave CHANGE_SLOT: the WAITING box, or NO_PAD on the Controller tab with no pad connected.
func begin_change(pad_connected: bool) -> void:
	if not is_open or box != Box.NONE or row == RESET_ROW:
		return
	box = Box.NO_PAD if device == Controls.Device.CONTROLLER and not pad_connected else Box.WAITING
	box_selected = BoxButton.SAFE

## The waiting box is done. event: what was taken, into the highlighted slot; null: cancelled, nothing changes.
func finish_change(event: InputEvent) -> void:
	if box != Box.WAITING:
		return
	box = Box.NONE
	if event == null:
		return
	var other := controls.set_slot(row as Controls.Action, device, slot, event)
	if other != Controls.NO_ACTION and controls.has_no_key(other as Controls.Action, device):
		note_no_key(other as Controls.Action)

## A pad unplugged: closes a Controller-tab WAITING box with nothing changed.
func pad_disconnected() -> void:
	if box == Box.WAITING and device == Controls.Device.CONTROLLER:
		box = Box.NONE

## A box button highlighted by left/right or the pointer. OK is the only button in WAITING and NO_PAD.
func box_select(button: BoxButton) -> void:
	if box == Box.WAITING or box == Box.NO_PAD:
		return
	if not is_open:
		return
	no_key_line = ""
	if box != Box.NONE:
		box_selected = button

## A box button chosen.
func box_press(button: BoxButton) -> Outcome:
	if box == Box.WAITING:
		return Outcome.NONE
	if not is_open:
		return Outcome.NONE
	no_key_line = ""
	if box == Box.NONE:
		return Outcome.NONE
	box_selected = button
	var was := box
	box = Box.NONE
	match [was, button]:
		[Box.RESET, BoxButton.OTHER]:
			controls.reset(device)
		[Box.LEAVING, BoxButton.SAFE]:
			var empty := controls.actions_without_key(device)
			if empty.is_empty():
				_set_tab(Controls.Device.CONTROLLER if device == Controls.Device.KEYBOARD else Controls.Device.KEYBOARD)
				empty = controls.actions_without_key(device)
			if not empty.is_empty():
				row = empty[0]
			slot = 0
		[Box.LEAVING, BoxButton.OTHER]:
			is_open = false
			return Outcome.RESUME_PLAY if leaving_by_start else Outcome.CLOSED
	return Outcome.NONE

## Esc / B in a box: box_press(SAFE).
func box_cancel() -> Outcome:
	return box_press(BoxButton.SAFE)

## A clash: shows "<Action> has no key" for this action.
func note_no_key(p_action: Controls.Action) -> void:
	if not is_open:
		return
	no_key_line = "%s has no key" % Controls.NAMES[p_action]

## Every action with no key on either tab, in Action order, each once.
func empty_actions() -> Array[Controls.Action]:
	var result: Array[Controls.Action] = []
	for a: Controls.Action in Controls.Action.values():
		if controls.has_no_key(a, Controls.Device.KEYBOARD) or controls.has_no_key(a, Controls.Device.CONTROLLER):
			result.append(a)
	return result

## The open box's lines: LEAVING [first, LEAVE_QUESTION]; RESET [the question for `device`];
## WAITING [action, press line]; NO_PAD [NO_PAD_LINE]; NONE [].
func box_lines() -> PackedStringArray:
	match box:
		Box.LEAVING:
			var e := empty_actions()
			var first: String = "%s has no key." % Controls.NAMES[e[0]] if e.size() == 1 else SOME_ACTIONS
			return PackedStringArray([first, LEAVE_QUESTION])
		Box.RESET:
			return PackedStringArray([RESET_KEYBOARD if device == Controls.Device.KEYBOARD else RESET_CONTROLLER])
		Box.WAITING:
			return PackedStringArray([Controls.NAMES[row], PRESS_KEY if device == Controls.Device.KEYBOARD else PRESS_BUTTON])
		Box.NO_PAD:
			return PackedStringArray([NO_PAD_LINE])
	return PackedStringArray()

## True when this row's action has no key on the showing tab: its empty slots draw orange.
func is_orange(p_row: int) -> bool:
	return p_row != RESET_ROW and controls.has_no_key(p_row as Controls.Action, device)

# Every press but hover and start clears the line; then only an open page with no box acts.
func _page_takes_input() -> bool:
	if not is_open:
		return false
	no_key_line = ""
	return box == Box.NONE

func _set_tab(p_device: Controls.Device) -> void:
	device = p_device
	slot = mini(slot, Controls.slot_count(p_device) - 1)

func _open_leaving(by_start: bool) -> void:
	box = Box.LEAVING
	box_selected = BoxButton.SAFE
	leaving_by_start = by_start
