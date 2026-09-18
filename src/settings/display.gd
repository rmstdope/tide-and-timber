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
		var root := get_tree().root
		apply_min_size(root)
		root.mode = mode_for(prefs.fullscreen)
		root.size_changed.connect(func() -> void: sync_from_window(root.mode))

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

## True for the window modes the row calls On: MODE_FULLSCREEN and MODE_EXCLUSIVE_FULLSCREEN.
static func is_fullscreen(mode: Window.Mode) -> bool:
	return mode == Window.MODE_FULLSCREEN or mode == Window.MODE_EXCLUSIVE_FULLSCREEN

## The mode the game sets for On: MODE_FULLSCREEN (borderless; a native Space on macOS). Off: MODE_WINDOWED.
static func mode_for(on: bool) -> Window.Mode:
	return Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED

## Flips the remembered setting; the window follows through _on_prefs_changed. The shortcut calls it.
func toggle_fullscreen() -> void:
	prefs.set_fullscreen(not prefs.fullscreen)

## The window's mode changed some other way (the OS's own control): the setting follows it.
## MODE_MINIMIZED is ignored, so minimising a fullscreen window forgets nothing.
func sync_from_window(mode: Window.Mode) -> void:
	if mode != Window.MODE_MINIMIZED:
		prefs.set_fullscreen(is_fullscreen(mode))

func _on_prefs_changed() -> void:
	# The comparison stops a loop: a change that came from the window already matches it.
	if DisplayServer.get_name() != "headless":
		var root := get_tree().root
		if is_fullscreen(root.mode) != prefs.fullscreen:
			root.mode = mode_for(prefs.fullscreen)
	changed.emit()
