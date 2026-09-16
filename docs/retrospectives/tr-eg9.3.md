# tr-eg9.3 — retrospective

## gdUnit4 report paths land inside the project, even absolute ones

**What happened.** To run single suites I called `GdUnitCmdTool.gd` with `-rd /tmp/...` and later with
`-rd /private/tmp/.../scratchpad/reports`. Both times the HTML reports were written under the worktree
(`tmp/cyc-reports/`, `private/tmp/.../reports/`), not at the absolute path, and `git add -A` committed
them. The PR diff showed ~6,500 lines of report HTML.

**Why.** Not established. The tool seems to treat the `-rd` value as relative to `res://`.

**Cost.** One branch rewrite before review, about 10 minutes.

**Prevent by.** Pass only `-rd res://reports` (ignored by `.gitignore`, as `scripts/gate-fast` does)
when running suites by hand, and check `git status` before `git add -A`.

**Seen before.** No.

## `test_no_raw_key_reads_in_src` rejects any `KEY_` substring

**What happened.** The plan named a colour constant `KEY_SHADOW` in `src/hud/hint_line.gd`. The
tr-eg9.1 guard in `tests/input/gamepad_bindings_test.gd` fails any `src` file that contains `KEY_`,
so the full gate went red on a colour constant.

**Why.** The guard matches substrings, not key reads.

**Cost.** One extra gate run.

**Prevent by.** Planners avoid `KEY_` in any identifier under `src/`. Or the guard in
`gamepad_bindings_test.gd` could match `KEY_[A-Z0-9]+\b` used as a keycode.

**Seen before.** No.
