class_name HudColours
extends RefCounted
## Every colour of the in-play interface — the bar, the slots, the planks, the words drawn over the
## world, the clock, the journal icon, the morning card — and of the two colour-blind cues, taken
## from the pack sheets PackPalette reads. Only Color constants belong here:
## tests/hud/hud_colours_test.gd sweeps the whole constant map and demands every one be a pack
## colour. Values repeat under separate names so a later change can move one role without the rest.

const WOOD_DARK := Color("#58351e")      ## every plank's and slot's border
const WOOD := Color("#865932")           ## every plank's fill
const WOOD_LIGHT := Color("#b68c48")     ## a plank's 1 px top highlight, a highlighted row
const SLOT_FACE := Color("#fee0a1")      ## the face of a slot, behind the icon
const SLOT_EDGE := Color("#fff6e4")      ## the slot's 1 px top highlight
const INK := Color("#301d0e")            ## the stack count, a key cap's letter, the rising line's outline
const PALE := Color("#fff6e4")           ## every word drawn over the world, the click mark
const CREAM := Color("#fee0a1")          ## a name on a plank, a key cap's face, the morning card's heading
const DIM := Color("#c6ab9f")            ## a row he cannot afford; an ordinary empty key slot's dash
const RING := Color("#bbb1ad")           ## the outer ring of a stick picture
const CAP_SHADOW := Color("#927e65")     ## the 1 px shadow under a key cap
const ARC := Color("#fee0a1")            ## the clock dial's arc of dots
const SUN := Color("#f6cc2b")            ## the sun marker
const MOON := Color("#eff8ff")           ## the moon marker
const JOURNAL_COVER := Color("#004d83")  ## the journal's cover
const JOURNAL_SPINE := Color("#002d4d")  ## its spine
const JOURNAL_PAGE := Color("#fff6e4")   ## its page
const JOURNAL_WRITING := Color("#80776b")## the three written lines
const JOURNAL_MISSED := Color("#a70c21") ## the cross when the day was not kept
const BAD := Color("#a70c21")            ## cue: the outline of a spot he cannot build on
const CROSS := Color("#fff6e4")          ## cue: the ✕ on that outline, under Shapes cues
const WARN := Color("#f78b54")           ## cue: the "!" and the line for an action with no key
