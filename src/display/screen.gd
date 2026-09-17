class_name Screen
extends RefCounted
## How big the drawn picture is, in the game's own pixels. This is the only place that says so:
## every screen-space position in the project is an expression of these, and project.godot's
## viewport_width / viewport_height must agree (tests/display/screen_test.gd pins that).
##
## Every screen-space site in the project is one of exactly four kinds, and this is the rule the
## next change to the picture's size follows:
##
## 1. A measurement — a width, a height, a gap, a step, a font size. It keeps its value in the
##    game's own pixels, and so halves on screen when the picture doubles.
## 2. Top- or left-referenced — a distance from the top or left edge. Unchanged, for the same
##    reason: the gaps to those window edges keep their numbers.
## 3. Bottom- or right-referenced — a distance `d` from the far edge. Written `HEIGHT - d` /
##    `WIDTH - d`.
## 4. Centre-referenced — derived from the middle, or from `(WIDTH - w) / 2`. Written as an
##    expression of `CENTRE`, `WIDTH` or `HEIGHT`.
##
## The title screen and the intro's story pictures are the one exception: their whole composition
## is proportional to the picture, so their y positions scale with it rather than following 1-4.
##
## Never instantiated.

const WIDTH := 320.0
const HEIGHT := 180.0
const SIZE := Vector2(WIDTH, HEIGHT)
const CENTRE := Vector2(WIDTH / 2.0, HEIGHT / 2.0)
const MIN_WINDOW := Vector2i(int(WIDTH), int(HEIGHT))   # never smaller than one times the picture
