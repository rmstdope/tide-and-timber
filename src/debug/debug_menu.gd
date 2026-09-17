class_name DebugMenu
extends RefCounted
## The Debug panel's rules, with no nodes: six pages of rows, the one highlight, scrolling, and what a push leads to.

enum Page { TIME, ITEMS, PLACE, STORY, SURVIVAL, SHOW }
enum Outcome { NONE, SHAKE, CLOSED, RESUME_PLAY }

const TAB_NAMES := ["Time", "Items", "Place", "Story", "Surv.", "Show"]   # index = Page
const WORKS_IN_STORY: Array[Page] = [Page.STORY, Page.SHOW]
const VISIBLE_ROWS := 9

var is_open := false
var in_story := false          # opened from the shipwreck story's pause board
var page: Page = Page.TIME
var highlighted := 0           # row index on `page`
var scroll := 0                # index of the first row drawn

var _rows := {}                # Page -> Array[DebugRow]

## Appends a row to a page. Rows keep their order. Callable at any time, open or not.
func add_row(p: Page, row: DebugRow) -> void:
	if not _rows.has(p):
		var list: Array[DebugRow] = []
		_rows[p] = list
	_rows[p].append(row)

## The page's rows, top to bottom (empty array when none).
func rows_of(p: Page) -> Array[DebugRow]:
	if _rows.has(p):
		return _rows[p]
	var none: Array[DebugRow] = []
	return none

## Opens on TIME, highlighted 0, scroll 0, remembering in_story. False, changing nothing, if already open.
func open(p_in_story: bool) -> bool:
	if is_open:
		return false
	is_open = true
	in_story = p_in_story
	_show(Page.TIME)
	return true

## Q/E, LB/RB: the page `step` (-1 or 1) away, wrapping round the six. Ignored unless open.
func flip(step: int) -> void:
	if is_open:
		_show(posmod(page + step, TAB_NAMES.size()) as Page)

## A click on a tab: that page. Ignored unless open.
func set_page(p: Page) -> void:
	if is_open:
		_show(p)

## Up/Down: wraps round the page's rows and keeps the highlight in view. Works on dimmed pages too.
func move(step: int) -> void:
	var n := rows_of(page).size()
	if not is_open or n == 0:
		return
	highlighted = posmod(highlighted + step, n)
	if highlighted < scroll:
		scroll = highlighted
	if highlighted >= scroll + VISIBLE_ROWS:
		scroll = highlighted - VISIBLE_ROWS + 1

## Pointer over a row: highlights it (scroll unchanged). Ignored unless open or index out of range.
func hover(index: int) -> void:
	if is_open and index >= 0 and index < rows_of(page).size():
		highlighted = index

## True when the page's rows do something: not in_story, or p in WORKS_IN_STORY.
func page_works(p: Page) -> bool:
	return not in_story or p in WORKS_IN_STORY

## Left/Right: calls the highlighted row's step(delta). True if called.
func change(delta: int) -> bool:
	var row := _acting_row()
	if row == null or not row.step.is_valid():
		return false
	row.step.call(delta)
	return true

## True when Left/Right on the highlighted row would call a step that repeats while held.
func highlighted_repeats() -> bool:
	var row := _acting_row()
	return row != null and row.step.is_valid() and row.repeats

## Select: calls the highlighted row's select(); REFUSED shakes, RESUME closes and resumes play.
func pick() -> Outcome:
	var row := _acting_row()
	if row == null or not row.select.is_valid():
		return Outcome.NONE
	match row.select.call():
		DebugRow.Result.REFUSED:
			return Outcome.SHAKE
		DebugRow.Result.RESUME:
			is_open = false
			return Outcome.RESUME_PLAY
	return Outcome.NONE

## Esc / B: closes. CLOSED, or NONE unless open.
func back() -> Outcome:
	if not is_open:
		return Outcome.NONE
	is_open = false
	return Outcome.CLOSED

## The pause action (Start): closes. RESUME_PLAY, or NONE unless open.
func start() -> Outcome:
	if not is_open:
		return Outcome.NONE
	is_open = false
	return Outcome.RESUME_PLAY

func _show(p: Page) -> void:
	page = p
	highlighted = 0
	scroll = 0

func _acting_row() -> DebugRow:
	var rows := rows_of(page)
	if not is_open or not page_works(page) or highlighted >= rows.size():
		return null
	return rows[highlighted]
