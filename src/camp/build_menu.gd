class_name BuildMenu
extends RefCounted
## What the build list shows and which line is highlighted.

enum Thing { LEAN_TO, FIRE }            # also the line order
const LINE_COUNT := 2
const COSTS: Array[int] = [8, 4]
const NAMES: Array[String] = ["Lean-to", "Fire"]

var driftwood := 0
var lean_to_built := false
var fire_lit := false
var highlighted := -1                   # a Thing, or -1 for none

func set_state(p_driftwood: int, p_lean_to_built: bool, p_fire_lit: bool) -> void:
	driftwood = p_driftwood
	lean_to_built = p_lean_to_built
	fire_lit = p_fire_lit

func open() -> void:
	highlighted = -1
	for i in LINE_COUNT:
		if can_build(i as Thing):
			highlighted = i
			return

func can_build(thing: Thing) -> bool:
	if thing == Thing.LEAN_TO:
		return not lean_to_built and driftwood >= COSTS[thing]
	return lean_to_built and not fire_lit and driftwood >= COSTS[thing]

func cost_text(thing: Thing) -> String:
	var have := "%d/%d driftwood" % [driftwood, COSTS[thing]]
	if thing == Thing.LEAN_TO:
		return "Already built" if lean_to_built else have
	if not lean_to_built:
		return "Needs a lean-to"
	return "Already lit" if fire_lit else have

func move(step: int) -> void:
	if highlighted == -1:
		highlighted = 0 if step > 0 else LINE_COUNT - 1
	else:
		highlighted = posmod(highlighted + step, LINE_COUNT)

func hover(thing: Thing) -> void:
	highlighted = thing
