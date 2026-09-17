# tr-1o0.1 — a `#` comment in a `.tscn` silently eats the node after it

## A `#` line in a scene file is not a comment

**What happened.** I added `# temporary: removed and repainted by tr-1o0.2` as the first line of a
node's body in `src/intro/intro.tscn` and `src/title/title_screen.tscn`. The import printed no
error. At run time `%Picture` and the whole `Art` subtree were simply absent:
`Node not found: "%Picture" (relative to "/root/Intro")`, 235 errored assertions across
`intro_test`, `gamepad_intro_test` and `story_debug_keys_test`, and nothing pointing at the comment.

**Why.** A `.tscn` is Godot's ConfigFile format, whose comment character is `;`, not `#`. A `#`
line is parsed as a malformed property assignment and the parser abandons the rest of that node's
properties — including `unique_name_in_owner`, which is what made the node findable by `%Name`.

**Cost.** About fifteen minutes, and a gate run whose 270 "errors" read as a geometry bug in a
change that was all geometry.

**Prevent by.** Writing `;` for a comment in any `.tscn` or `.tres`. The symptom to recognise:
`Node not found: "%X"` for a node that is plainly still in the file, right after the file was
hand-edited.

**Seen before.** No. `docs/retrospectives/tr-b4o.6.1.md` is the nearest neighbour in that it is
also about a scene file edited by hand, but not about the comment character.

## The plan's "double every window size" does not preserve a stacking threshold

**What happened.** The plan held that the ~30 suites which resize the root window need only their
window sizes doubled, because `k` is window ÷ base and both double. That is true of `k`, and false
of every threshold measured against the picture: a board keeps its unit width while the picture
doubles, so the boards stop crossing the stacking and scrolling thresholds altogether. About 15
suites and 400+ assertions test behaviour that no UI size can now produce, which is what the bead
was handed back on.

**Why.** Two different ratios were treated as one. `k` is window ÷ picture and is unchanged.
Stacking and scrolling compare a board's own units against the picture's units, and that ratio
halves.

**Cost.** Increment 3 could not be finished; the bead went back to the navigator with a scope
question.

**Prevent by.** When a plan changes the picture's size, listing every threshold expressed as
"board units versus picture units" — `BoxLayout.stacks_at`, `SettingsBoard.stacks`,
`ControlsPage.stacks_at`, and every `frame(0, Screen.HEIGHT)` caller — and saying for each whether
it is still reachable afterwards.

**Seen before.** No.
