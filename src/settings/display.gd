extends Node
## The live display settings. Every view the settings affect reads Display.prefs and redraws on Display.changed.

signal changed

var prefs: DisplayPrefs

# Under the gdUnit command-line run the SceneTree carries a script: tests start at the defaults
# and never read or write the player's real file.
func _ready() -> void:
	use_prefs(DisplayPrefs.load_from(startup_path(get_tree())))
	# Headless (the gate) has no real window, and suites resize the root below one times the picture.
	if DisplayServer.get_name() != "headless":
		apply_min_size(get_tree().root)

## The smallest window the game allows: one times the picture. Godot 4.7 has no project setting for
## it (display/window/size/ has no min key), so it is set on the root window at launch.
static func apply_min_size(window: Window) -> void:
	window.min_size = Screen.MIN_WINDOW

## The file read at launch: "" (never read, never written) when the tree carries a script, as the gdUnit run does.
static func startup_path(tree: SceneTree) -> String:
	return "" if tree.get_script() != null else DisplayPrefs.PATH

## Makes p the live settings and tells every view. Tests pass DisplayPrefs.new().
func use_prefs(p: DisplayPrefs) -> void:
	if prefs and prefs.changed.is_connected(_on_prefs_changed):
		prefs.changed.disconnect(_on_prefs_changed)
	prefs = p
	p.changed.connect(_on_prefs_changed)
	changed.emit()

func _on_prefs_changed() -> void:
	changed.emit()
