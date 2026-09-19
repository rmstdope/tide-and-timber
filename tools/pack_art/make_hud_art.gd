extends SceneTree
## Recolours Retro Inventory's knobbed frame and slot to HudColours for the in-play interface.
## Run: godot --headless --path . --script res://tools/pack_art/make_hud_art.gd

const FRAME_SOURCE := "res://assets/retro_inventory/Inventory_9Slices.png"
const SLOT_SOURCE := "res://assets/retro_inventory/Inventory_Slot_1.png"
const FRAME_PATH := "res://assets/hud/frame.png"   # 32 x 32, the pack's frame, centre filled WOOD
const SLOT_PATH := "res://assets/hud/slot.png"     # 22 x 22, the pack's slot cropped to its outline
const FRAME_MARGIN := 6                            # the nine-slice margin on every side
const SLOT_REGION := Rect2i(5, 5, 22, 22)          # the slot's outline inside the 32 x 32 source

## Pack colour (Color.to_html(false)) -> the HudColours colour it becomes. The same table for both pieces.
const SWAP := {
	"000000": HudColours.INK,         # outline
	"995700": HudColours.WOOD_DARK,   # the frame's corner shade
	"ca8611": HudColours.WOOD,        # rim
	"febf4c": HudColours.WOOD_LIGHT,  # rim highlight
	"382f35": HudColours.WOOD_LIGHT,  # the inner shade under the top edge: the set-in line
	"4c4449": HudColours.SLOT_FACE,   # the inner face
}

func _init() -> void:
	var frame := frame_image()
	var slot := slot_image()
	if frame == null or slot == null:
		push_error("unmapped colour in %s" % (FRAME_SOURCE if frame == null else SLOT_SOURCE))
		quit(1)
		return
	_save(frame, FRAME_PATH)
	_save(slot, SLOT_PATH)
	quit()

## Every opaque pixel of `source` swapped through SWAP; transparent pixels stay transparent.
## Returns null for an opaque colour SWAP lacks or a partly transparent pixel; it never push_errors (tests call it).
static func recolour(source: Image) -> Image:
	var out := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var c := source.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var key := c.to_html(false)
			if c.a != 1.0 or not SWAP.has(key):
				return null
			out.set_pixel(x, y, SWAP[key])
	return out

## recolour() of FRAME_SOURCE with Rect2i(FRAME_MARGIN, FRAME_MARGIN, 20, 20) filled HudColours.WOOD.
static func frame_image() -> Image:
	var image := recolour(_read(FRAME_SOURCE))
	if image != null:
		image.fill_rect(Rect2i(FRAME_MARGIN, FRAME_MARGIN, 20, 20), HudColours.WOOD)
	return image

## recolour() of SLOT_SOURCE, cropped to SLOT_REGION.
static func slot_image() -> Image:
	var image := recolour(_read(SLOT_SOURCE))
	return image.get_region(SLOT_REGION) if image != null else null

static func _read(path: String) -> Image:
	var image := (load(path) as Texture2D).get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image

func _save(image: Image, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var err := image.save_png(path)
	if err != OK:
		push_error("could not save %s: %s" % [path, error_string(err)])
