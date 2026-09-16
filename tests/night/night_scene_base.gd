extends GdUnitTestSuite
## Shared setup for the night's scene suites: the waking scene, handed control, every clock stopped.

var runner: GdUnitSceneRunner
var waking: Waking
var dn: DayNight
var night: Night
var beach: Beach
var builder: Builder
var player: Player
var inventory: Inventory
var saves: Array[SaveData] = []   # what the dawn autosave would have written; never the real slot

func before_test() -> void:
	runner = scene_runner("res://src/waking/waking.tscn")
	waking = runner.scene() as Waking
	waking.set_process(false)
	waking.tick(5.0)
	dn = waking.get_node("%DayNight") as DayNight
	dn.set_process(false)
	night = waking.get_node("%Night") as Night
	night.set_process(false)
	beach = waking.get_node("%Beach") as Beach
	builder = beach.get_node("%Builder") as Builder
	player = waking.player
	inventory = beach.inventory
	saves.clear()
	var autosave := waking.get_node("%Autosave") as Autosave
	autosave.set_process(false)
	autosave.save_game = func() -> Error:
		saves.append(beach.capture())
		return OK

func after_test() -> void:
	if is_instance_valid(waking):
		waking.get_tree().paused = false

func _n(unique: String) -> Node:
	return waking.get_node("%" + unique)

func _at(minutes: float) -> void:
	dn.clock.total_minutes = minutes

func _fire() -> void:
	var f := CampFire.new()
	f.cell = Vector2i(92, 14)
	f.position = Vector2(1480, 240)
	beach.get_node("%World").add_child(f)
	builder.fire = f

func _lean_to() -> void:
	var l := LeanTo.new()
	l.cells = BuildSite.cells_for(BuildMenu.Thing.LEAN_TO, Vector2i(92, 11), Walk.Facing.DOWN)
	l.position = BuildSite.origin_for(BuildMenu.Thing.LEAN_TO, l.cells)
	beach.get_node("%World").add_child(l)
	builder.lean_to = l

func _in_light() -> void:
	player.global_position = Vector2(1496, 232)

func _out_of_light() -> void:
	player.global_position = Vector2(1560, 232)

func _line_text() -> String:
	return (_n("NightLine").get_node("Text") as Label).text
