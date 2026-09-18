class_name ColourSight
extends RefCounted
## How a colour looks to eyes that see it differently, and how far apart two colours are.
##
## The simulation is Viénot, Brettel and Mollon (1999): linear RGB into LMS cone response, one cone
## axis collapsed onto the other two, back again. The distance is CIE76 ΔE in L*a*b* under D65 —
## small enough to write out, and good enough to say "these two are told apart".
##
## Test-only, so nothing of it ships in the executable. gdUnit4 collects only GdUnitTestSuite
## subclasses, so this file contributes no suite of its own.

enum Sight { NORMAL, PROTAN, DEUTAN, TRITAN }

const _RGB_TO_LMS := [
	[17.8824, 43.5161, 4.11935],
	[3.45565, 27.1554, 3.86714],
	[0.0299566, 0.184309, 1.46709],
]
const _LMS_TO_RGB := [
	[0.0809444479, -0.130504409, 0.116721066],
	[-0.0102485335, 0.0540193266, -0.113614708],
	[-0.000365296938, -0.00412161469, 0.693511405],
]
const _PROTAN := [[0.0, 2.02344, -2.52581], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]
const _DEUTAN := [[1.0, 0.0, 0.0], [0.494207, 0.0, 1.24827], [0.0, 0.0, 1.0]]
const _TRITAN := [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [-0.395913, 0.801109, 0.0]]

static func _apply(m: Array, v: Array) -> Array:
	var out: Array = []
	for row: Array in m:
		out.append(row[0] * v[0] + row[1] * v[1] + row[2] * v[2])
	return out

## `colour` as eyes of that kind see it. NORMAL returns it unchanged.
static func seen(colour: Color, sight: Sight) -> Color:
	if sight == Sight.NORMAL:
		return colour
	var m: Array = _PROTAN if sight == Sight.PROTAN else (_DEUTAN if sight == Sight.DEUTAN else _TRITAN)
	var lin := colour.srgb_to_linear()
	var lms := _apply(_RGB_TO_LMS, [lin.r, lin.g, lin.b])
	var rgb := _apply(_LMS_TO_RGB, _apply(m, lms))
	var back := Color(clampf(rgb[0], 0.0, 1.0), clampf(rgb[1], 0.0, 1.0), clampf(rgb[2], 0.0, 1.0))
	var srgb := back.linear_to_srgb()
	return Color(clampf(srgb.r, 0.0, 1.0), clampf(srgb.g, 0.0, 1.0), clampf(srgb.b, 0.0, 1.0), colour.a)

static func _lab(colour: Color) -> Array:
	var lin := colour.srgb_to_linear()
	var x := (0.4124564 * lin.r + 0.3575761 * lin.g + 0.1804375 * lin.b) / 0.95047
	var y := 0.2126729 * lin.r + 0.7151522 * lin.g + 0.0721750 * lin.b
	var z := (0.0193339 * lin.r + 0.1191920 * lin.g + 0.9503041 * lin.b) / 1.08883
	var f := func(t: float) -> float:
		return pow(t, 1.0 / 3.0) if t > 0.008856 else (7.787 * t + 16.0 / 116.0)
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return [116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz)]

## CIE76 ΔE between the two colours as eyes of that kind see them.
static func distance(a: Color, b: Color, sight: Sight) -> float:
	var la := _lab(seen(a, sight))
	var lb := _lab(seen(b, sight))
	return sqrt(pow(la[0] - lb[0], 2.0) + pow(la[1] - lb[1], 2.0) + pow(la[2] - lb[2], 2.0))

## The smallest distance over normal, protanopic, deuteranopic and tritanopic sight.
static func worst_distance(a: Color, b: Color) -> float:
	var worst := INF
	for sight: Sight in [Sight.NORMAL, Sight.PROTAN, Sight.DEUTAN, Sight.TRITAN]:
		worst = minf(worst, distance(a, b, sight))
	return worst

static func _luminance(c: Color) -> float:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)

## The WCAG contrast ratio between two colours, lighter first: (L + 0.05) / (L + 0.05).
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

## `top` laid over `bottom` at that alpha.
static func over(top: Color, bottom: Color, alpha: float) -> Color:
	return Color(
		lerpf(bottom.r, top.r, alpha),
		lerpf(bottom.g, top.g, alpha),
		lerpf(bottom.b, top.b, alpha),
		1.0,
	)
