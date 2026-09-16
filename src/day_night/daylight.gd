class_name Daylight
extends RefCounted
## The colour of the scene's light at a minute of the day, with no nodes.

# [minute of day, colour] in ascending minute order; the first and last colours are equal so the day wraps
const KEYS := [
	[0,    Color8(110, 125, 190)],   # night
	[300,  Color8(110, 125, 190)],   # 05:00 the sky starts to lighten
	[360,  Color8(205, 175, 185)],   # 06:00 dawn
	[420,  Color8(255, 255, 255)],   # 07:00 full daylight
	[780,  Color8(255, 255, 255)],   # 13:00 full daylight (start of play)
	[990,  Color8(255, 238, 208)],   # 16:30 warmer gold
	[1110, Color8(255, 190, 140)],   # 18:30 sunset orange
	[1200, Color8(170, 140, 195)],   # 20:00 purple dusk
	[1260, Color8(110, 125, 190)],   # 21:00 deep blue night
	[1440, Color8(110, 125, 190)],
]


static func color_at(minute_of_day: float) -> Color:
	var m := fposmod(minute_of_day, 1440.0)
	for i in range(1, KEYS.size()):
		var b_minute: float = KEYS[i][0]
		if m <= b_minute:
			var a_minute: float = KEYS[i - 1][0]
			var a: Color = KEYS[i - 1][1]
			var b: Color = KEYS[i][1]
			return a.lerp(b, (m - a_minute) / (b_minute - a_minute))
	return KEYS[KEYS.size() - 1][1]
