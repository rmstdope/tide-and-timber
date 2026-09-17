# tr-hy6.7 — retrospective

## The plan put raw F-key reads in `src/debug`, which the raw-key guard forbids

**What happened.** The plan had `src/debug/debug_keys.gd` match on `KEY_F1`..`KEY_F4` and
`src/debug/debug_key_line.gd` read `physical_keycode`. `tests/input/gamepad_bindings_test.gd`
`test_no_raw_key_reads_in_src` fails any file under `src/` outside `src/input` that contains `KEY_` or
`physical_keycode`, so the first fast gate went red. The key reading moved to
`src/input/debug_shortcut.gd` (`DebugShortcut.of(event) -> Name`). The obvious enum names `Shortcut` and
`Key` both shadow native Godot classes, so that cost a parse error too.

**Why.** Planners are not told about the guard; neither the plan template nor `.cerebro/traps.md`
mentions it.

**Cost.** One extra full fast-gate run (~2.5 min) and one run lost to the native-class shadowing.

**Prevent by.** An entry in `.cerebro/traps.md`: "any `KEY_` or `physical_keycode` in `src/` must be under
`src/input` (`test_no_raw_key_reads_in_src`)", so plans put key reads there.

**Seen before.** Yes: `docs/retrospectives/tr-eg9.3.md`, *`test_no_raw_key_reads_in_src` rejects any
`KEY_` substring* — the same guard, and still not in the traps file.
