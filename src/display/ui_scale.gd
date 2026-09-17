class_name UiScale
extends OverlayScale
## An OverlayScale whose multiplier follows the player's UI size, at once when it changes.

## NORMAL -> 1.0, LARGE -> 1.5, LARGEST -> 2.0.
static func multiplier_for(size: DisplayPrefs.Size) -> float:
	match size:
		DisplayPrefs.Size.LARGE:
			return OverlayScale.LARGE
		DisplayPrefs.Size.LARGEST:
			return OverlayScale.LARGEST
	return OverlayScale.NORMAL

## The scale an overlay has right now, with whole screen pixels.
static func current(prefs: DisplayPrefs, window: Window) -> float:
	return OverlayScale.factor(multiplier_for(prefs.ui_size), OverlayScale.whole_scale(window))

func _ready() -> void:
	Display.changed.connect(_follow)
	_follow()
	super()

func _follow() -> void:
	multiplier = multiplier_for(Display.prefs.ui_size)
