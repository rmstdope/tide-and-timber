# tr-0cr

## A test asserting a project setting reddened when the gate started overriding that setting

**What happened:** The plan's file survey ended with "No other file changes". The change makes
`scripts/gate-fast` write an `override.cfg` that points `application/config/custom_user_dir_name`
at a per-checkout directory. `tests/smoke/project_setup_test.gd` asserts that key against the
**live** `ProjectSettings`, so the first real `scripts/gate-fast` run after the shell suite went
green came back with one failure — `expected Tide and Timber, got Tide and Timber/gate/tr-0cr-98882ba4`
— in a suite the bead never meant to touch.

**Why:** The plan reasoned about which *scripts* the change touches and about Godot's override
mechanism, but not about which tests read the settings the override rewrites. An `override.cfg` is
invisible to a grep for `gate-fast`; what finds it is a grep for the setting keys.

**Cost:** One full `scripts/gate-fast` cycle, about three minutes, plus the judgement call about
what the right fix was. Small, but it would have been a hand-back had the answer been less clear —
the assertion is close to the bead's acceptance criterion that a player's saves stay put.

**Prevent by:** In `skills/design-the-build`, when a plan changes a runtime setting — a
`ProjectSettings` key, an environment variable, a config override — grep `tests/` for that key and
list every suite that reads it among the files to change. Here, `grep -rn custom_user_dir tests/`
would have named `tests/smoke/project_setup_test.gd` before the first increment.

**Seen before:** No. Nothing in `docs/retrospectives/` mentions `ProjectSettings` or `override.cfg`.
