# tr-eg9.6.5.5

## One suite run under `-d` without `--remote-debug` hung on a script error, a third time

**What happened.** While iterating, I ran single suites with `godot --headless -d --script …GdUnitCmdTool.gd`
and left out `--remote-debug tcp://127.0.0.1:0`. An existing test (`tests/pause/beach_pause_test.gd:69`)
reached a `Nil` once the box buttons' `Label` became a `GrownWords` holder. The engine stopped at
`Debugger Break` and waited for input until the tool call timed out.
**Why.** `-d` with no remote debugger enters the local debugger on a script error, exactly as
`tr-hy6.5.md` recorded.
**Cost.** About ten minutes, and one more background run that had to be killed.
**Prevent by.** Give `scripts/gate-fast` an optional suite argument (suggested in `tr-hy6.5.md` and
`tr-zwq.md`, not yet done), so nobody hand-types the raw invocation.
**Seen before.** `docs/retrospectives/tr-hy6.5.md`, `docs/retrospectives/tr-zwq.md`.
