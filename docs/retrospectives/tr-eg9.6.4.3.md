# tr-eg9.6.4.3 — retrospective

## `title_continue_test` went red in the fast gate for the third recorded time, and this run proves it is not the bead's

### What happened
`scripts/gate-fast` on this branch reported 5 failures and 1 error, all in
`tests/title/title_continue_test.gd`, in code the bead never touched. The
symptoms are the ones already recorded: a save read back as
`{"game_version":"0.4","version":2}` that does not compare equal, and
`ERROR: Couldn't open directory at path "user://test_saves/reading"`, after
which three or four more cases in the same suite fail in a cascade.

The new fact this run adds: I cloned `origin/main` at `0f4fe12` into a
throwaway directory with no changes of mine and ran the same gate there. It
failed too, in the same suite (`test_start_over_replaces_by_starting_a_new_game`).
Run in isolation, `title_continue_test.gd` is green on main. Afterwards this
branch ran the full gate green twice in a row. So the suite is flaky
independently of any change, and which cases fail varies per run.

### Why
Not established, and unchanged from the two earlier records: every worktree in
this checkout shares one Godot `user://` directory, so parallel implementers'
gates write each other's `user://test_saves` files. Five implementer worktrees
were live while this ran.

### Cost
About twenty minutes: one full gate run to see the red, one clone-and-gate of
pristine `main` to establish it was not mine, one isolated run of the suite,
and two confirming full gate runs. It also costs the reader of any PR the
question "is this failure mine?", which is the expensive part.

### Prevent by
The fix named in `tr-eg9.6.6.md` and again in `tr-hy6.2.md` is still not done:
give each gate run its own `user://`. `scripts/gate-fast` could set
`--user-data-dir` per run, or override the app name, so the suites cannot
share save files. This is the third bead to pay for it; recording, not fixing,
as the rules say.

### Seen before
Yes, twice: `docs/retrospectives/tr-eg9.6.6.md` and the second section of
`docs/retrospectives/tr-hy6.2.md`.

## `timeout` does not exist on macOS, and wrapping the suite runner in it looked like a hang

### What happened
To bound a gdUnit4 run I wrote `timeout 380 godot --headless ...`. macOS ships
no `timeout` (it is `gtimeout`, from coreutils), so the shell returned 127
immediately with no output. Because the grep that consumed the output matched
nothing, the run looked like a silent failure of the suite rather than of the
wrapper. An earlier variant of the same command, with a GDScript parse error in
a test file, genuinely did hang until the tool's own timeout, which made the
two look like the same problem.

### Why
`timeout` is a GNU coreutils program. This is a macOS fleet, and nothing in the
project's own scripts uses it, so nothing had exposed the gap before.

### Cost
One 400-second tool call spent on a hang, and two wasted runs chasing a
failure that was the wrapper's.

### Prevent by
Do not wrap project commands in `timeout` here; the Bash tool's own `timeout`
argument does the same job and reports properly. When a command produces no
output at all, echo its exit code before filtering it — `rc=127` names the
problem instantly, and a grep that matches nothing hides it.

### Seen before
Nothing like it in `docs/retrospectives/`.
