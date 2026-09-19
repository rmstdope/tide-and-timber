# tr-hln — resaving beach.tscn from a `--script` SceneTree silently dropped node scripts

## What happened

The plan's throwaway generator (step B) loaded `src/beach/beach.tscn` in a
`godot --headless --script` SceneTree, added the props, `PackedScene.pack`ed the root and saved it.
Godot exited 0 and `pack`/`save` both returned OK. The saved scene had lost the `script =` lines of
`Prompt`, `Interactor`, `Builder`, the HUD controls and others. It had also expanded the `Player`
instance into typed overrides, renumbered every `ext_resource` id and added `unique_id`s everywhere.

## Why

Not fully established. The script errored at load (a stack line pointed at the `load` of the scene).
The likely cause is that scripts depending on autoloads fail to compile in `--script` mode, where
the project's autoloads do not exist, and a node whose script failed to compile is packed without it.

## Cost

About ten minutes, and it could have been far worse. Only a skim of `git diff` caught it: the gate
might not have, because the missing scripts were HUD and builder pieces.

## Prevent by

A plan that regenerates a hand-written `.tscn` should splice text into it (the generated
`tile_map_data` line plus the `[node]` blocks), or run the generator as a scene so autoloads exist.
It should not pack and save the whole scene from `--script`. After any programmatic resave, diff the
file and count its `script =` lines against the original. A resave that writes the base64
`tile_map_data` also needs `format=4` in the header.

## Seen before

No.
