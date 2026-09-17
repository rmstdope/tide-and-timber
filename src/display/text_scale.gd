class_name TextScale
extends RefCounted
## How big the words are: UI size times Text size, in whole screen pixels, and the width a line
## takes once its words have grown — wider first, up to nearly the screen, then narrower and wrapped.

## The words' on-screen scale: UI size times Text size, rounded to whole screen pixels.
static func total(prefs: DisplayPrefs, window: Window) -> float:
	return OverlayScale.factor(
		UiScale.multiplier_for(prefs.ui_size) * UiScale.multiplier_for(prefs.text_size),
		OverlayScale.whole_scale(window))

## The scale words take inside a view that already follows UI size; exactly 1.0 at Text size Normal.
static func relative(prefs: DisplayPrefs, window: Window) -> float:
	return total(prefs, window) / UiScale.current(prefs, window)

## The wrap-b width, in the container's own units: the wider of the Normal width and the words,
## while that fits the screen at UI scale `ui`; else the screen less SpokenLine.SCREEN_MARGIN each side.
static func fit_width(normal_width: float, words_width: float, ui: float) -> float:
	var want := maxf(normal_width, words_width)
	if want * ui <= SpokenLine.SCREEN_WIDTH:
		return want
	return floorf((SpokenLine.SCREEN_WIDTH - 2.0 * SpokenLine.SCREEN_MARGIN) / ui)
