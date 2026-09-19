# Authoring the beach

The beach's ground and props live in one place: `src/beach/beach.tscn`. Open it in the Godot
editor, change it, save, and the next run of the game uses it. There is no second copy of the
layout in code; `BeachLayout` (and `BeachMap` under it) read the scene once per run.

## Ground

`Ground` is a TileMapLayer painted with `src/beach/beach_tiles.tres`, one tile per kind of ground
(jungle, sand, wet sand, foam, shallows, deep water, cliff). What a cell *is* comes from the tile's
`kind` custom data, not its place in the atlas. Jungle, deep water and cliff are solid; shallows are
waded. A cell with no tile counts as deep water. A tile added to the TileSet must have its `kind` set;
an untagged tile reads as 0, jungle, which is solid. The map starts at cell (0, 0) and its size is the
painted area.

## Props

Each prop is an instance of a scene in `src/beach/props/`, named `<Kind><nn>` (`Palm01`,
`Driftwood24`...).

- Under `Decor` (flat, drawn under the man): bush, tuft, driftwood, shellfish.
- Under `World` (y-sorted with the man): palm, rock, boulder, spring.

A prop's cell is worked out from its position: its origin is the bottom centre of its cell. To snap
props, set the 2D editor's grid step to 16x16 with offset (8, 0).

## What to be careful with

- **Driftwood and shellfish are in saves.** A save lists the pieces the player took by cell.
  Moving or deleting one makes existing saves that took it fail to load (`Beach.can_restore`), so
  do that only together with a save migration. Adding new pieces is safe for saves; add their cells to the literal lists in
  `test_takeable_props_stay_where_saves_expect_them` too.
- **The layout tests pin rules a layout must keep**: `tests/beach/beach_layout_test.gd` checks
  that props stand on walkable ground, both headlands can be reached, shellfish lie on wet sand, and
  so on; `test_takeable_props_stay_where_saves_expect_them` pins every driftwood and shellfish cell,
  and `test_painted_map_starts_at_the_origin` fails if anything is painted left of or above (0, 0).
  A deliberate terrain change may need their sample cells updated.

## Reading a layout change in review

`tile_map_data` is not readable in a diff. Dump the layout as text before and after, and diff:

```bash
godot --headless --path . res://tools/beach_layout/dump_beach_layout.tscn | grep -E '^(size|row|prop) ' > tmp/beach_before.txt
# ... change the scene ...
godot --headless --path . res://tools/beach_layout/dump_beach_layout.tscn | grep -E '^(size|row|prop) ' > tmp/beach_after.txt
diff tmp/beach_before.txt tmp/beach_after.txt
```

Each `row` line gives every cell's tile as its atlas column (`.` for none); each `prop` line gives a
prop's parent, scene and position.
