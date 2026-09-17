# tr-zwq — the one-suite command needs an import a fresh worktree has not had

**What happened.** The plan's *Validation* section offers a command for running one suite while
iterating on an increment (`godot --headless --path . -d --remote-debug tcp://127.0.0.1:0 --script
res://addons/gdUnit4/bin/GdUnitCmdTool.gd … -a res://tests/menu`). Run as the first test command in a
freshly prepared worktree it does not work, and fails twice over:

1. I first ran it without `--remote-debug`, and it hung until the tool call timed out — exactly
   `docs/retrospectives/tr-hy6.5.md`, whose *Prevent by* has not been acted on.
2. With the correct flags it still failed, on `Parse Error: Could not find type "GdUnitTestCIRunner"`
   and `Cannot open file 'res://.godot/imported/PressStart2P-Regular.ttf-….fontdata'`. The worktree
   had never been imported, so `res://.godot/` did not exist and gdUnit4's own addon could not
   resolve. Only `scripts/gate-fast` runs `godot --import`, and
   `.claude/cerebro/scripts/project-conf prewarm` prints `prewarm unset, and no default`, so nothing
   in the worktree setup or the plan says an import must come first.

**Why.** `scripts/gate-fast` owns the import step, and the one-suite command documented beside it in
plans does not. In a checkout that has already been gated once the difference is invisible, which is
why the command reads as standalone. A fresh worktree per bead is the normal case for this fleet, so
the first test run of every bead hits it.

**Cost.** About twelve minutes across two failed runs and one `pkill`, before the first RED was seen.

**Prevent by.** Give `scripts/gate-fast` an optional suite argument — `scripts/gate-fast res://tests/menu`
— so one command carries the import, the private user dir and the right flags, and plans can cite it
instead of a raw `GdUnitCmdTool` line. That is also `tr-hy6.5`'s *Prevent by*, now owed twice. Failing
that, the *Validation* section of a plan offering the raw command should say `scripts/gate-fast` must
have run once in the worktree first.

**Seen before.** `docs/retrospectives/tr-hy6.5.md` — same command, the missing-`--remote-debug` hang,
same suggested fix, not yet done. `docs/retrospectives/tr-eg9.3.md` and `docs/retrospectives/tr-hy6.1.md`
are the same command's `-rd` trap. Three retrospectives now point at this one raw invocation.
