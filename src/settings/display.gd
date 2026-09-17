extends Node
## The live display settings. Every view the settings affect reads Display.prefs and redraws on Display.changed.

signal changed

var prefs: DisplayPrefs

# Under the gdUnit command-line run the SceneTree carries a script: tests start at the defaults
# and never read or write the player's real file.
func _ready() -> void:
	use_prefs(DisplayPrefs.load_from("" if get_tree().get_script() != null else DisplayPrefs.PATH))

## Makes p the live settings and tells every view. Tests pass DisplayPrefs.new().
func use_prefs(p: DisplayPrefs) -> void:
	if prefs and prefs.changed.is_connected(_on_prefs_changed):
		prefs.changed.disconnect(_on_prefs_changed)
	prefs = p
	p.changed.connect(_on_prefs_changed)
	changed.emit()

func _on_prefs_changed() -> void:
	changed.emit()
