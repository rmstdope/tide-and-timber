#!/usr/bin/env bash
# Checks scripts/gate-fast against a fake Godot: refusals, import, suite and exit codes.
# No network and no real Godot.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

SUITE_ARGS="-d --remote-debug tcp://127.0.0.1:0 --script res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests -rd res://reports -rc 1"

sandbox() {
  S="$(cd "$(mktemp -d)" && pwd)"
  mkdir -p "$S/repo/scripts" "$S/elsewhere" "$S/bin"
  cp "$root/scripts/gate-fast" "$S/repo/scripts/gate-fast" 2>/dev/null
  export FAKE_CALLS="$S/calls"
}

make_fake_godot() {
  cat > "$S/bin/godot" <<'FAKE'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_CALLS"
proj=""; prev=""
for a in "$@"; do
  if [ "$prev" = "--path" ]; then proj="$a"; fi
  prev="$a"
done
if [ -n "${FAKE_OVERRIDE_SNAPSHOT:-}" ] && [ -n "$proj" ] && [ -f "$proj/override.cfg" ]; then
  cat "$proj/override.cfg" >> "$FAKE_OVERRIDE_SNAPSHOT"
fi
case "$*" in
  *--import*) exit "${FAKE_IMPORT_EXIT:-0}" ;;
  *GdUnitCmdTool.gd*)
    if [ -n "${FAKE_SUITE_KILL:-}" ]; then kill -TERM "$PPID"; exit 143; fi
    exit "${FAKE_SUITE_EXIT:-0}" ;;
esac
exit 99
FAKE
  chmod +x "$S/bin/godot"
}

# run_gate [args...]: runs the gate from $S/elsewhere; sets code, and stderr in $S/err.
run_gate() {
  (cd "$S/elsewhere" && GATE_GODOT="${GATE_GODOT_VALUE-$S/bin/godot}" \
    bash "$S/repo/scripts/gate-fast" "$@" >/dev/null 2>"$S/err")
  code=$?
}

lines() { if [ -f "$1" ]; then wc -l < "$1" | tr -d ' '; else echo 0; fi; }

test_missing_godot_exits_1() {
  local name="${FUNCNAME[0]}"; sandbox
  GATE_GODOT_VALUE="$S/nope" run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: no godot at $S/nope; run brew install --cask godot" "$S/err"; then
    fail "$name" "stderr: $(cat "$S/err")"
  elif [ -e "$S/calls" ]; then fail "$name" "godot was called"
  else ok "$name"; fi
  rm -rf "$S"
}

test_default_godot_comes_from_path() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  (cd "$S/elsewhere" && unset GATE_GODOT && PATH="$S/bin:/usr/bin:/bin" \
    bash "$S/repo/scripts/gate-fast" >/dev/null 2>"$S/err")
  code=$?
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif [ "$(lines "$S/calls")" != 2 ]; then fail "$name" "calls: $(lines "$S/calls")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_arguments_exit_2() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  run_gate --all
  if [ "$code" != 2 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: usage:" "$S/err"; then fail "$name" "stderr: $(cat "$S/err")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_import_failure_stops_before_suite() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_IMPORT_EXIT=3 run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: import failed (exit 3)" "$S/err"; then fail "$name" "stderr: $(cat "$S/err")"
  elif [ "$(lines "$S/calls")" != 1 ]; then fail "$name" "calls: $(lines "$S/calls")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_green_run_exits_0_with_exact_invocations() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  run_gate
  local expected
  expected="$(printf '%s\n%s' "--headless --path $S/repo --import" "--headless --path $S/repo $SUITE_ARGS")"
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif [ "$(tail -n 1 "$S/err")" != "gate-fast: green" ]; then fail "$name" "last line: $(tail -n 1 "$S/err")"
  elif [ "$(cat "$S/calls" 2>/dev/null)" != "$expected" ]; then fail "$name" "calls: $(cat "$S/calls" 2>/dev/null)"
  else ok "$name"; fi
  rm -rf "$S"
}

test_suite_failure_exits_1() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_EXIT=100 run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: gdUnit4 suites failed (exit 100)" "$S/err"; then fail "$name" "stderr: $(cat "$S/err")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_orphan_warning_exits_1() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_EXIT=101 run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "(exit 101)" "$S/err"; then fail "$name" "stderr: $(cat "$S/err")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_writes_override_cfg_naming_a_per_checkout_user_dir() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_OVERRIDE_SNAPSHOT="$S/snap" run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif [ ! -f "$S/snap" ]; then fail "$name" "no override.cfg seen while godot ran"
  elif [ "$(head -n 1 "$S/snap")" != "; temporary: written by scripts/gate-fast, removed when it exits" ]; then
    fail "$name" "first line: $(head -n 1 "$S/snap")"
  elif ! grep -qF 'config/use_custom_user_dir=true' "$S/snap"; then
    fail "$name" "no use_custom_user_dir: $(cat "$S/snap")"
  elif ! grep -qF 'config/custom_user_dir_name="Tide and Timber/gate/' "$S/snap"; then
    fail "$name" "no per-checkout dir name: $(cat "$S/snap")"
  else ok "$name"; fi
  rm -rf "$S"
}

test_override_cfg_removed_after_green_run() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif [ -e "$S/repo/override.cfg" ]; then fail "$name" "override.cfg left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_override_cfg_removed_after_suite_failure() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_EXIT=100 run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif [ -e "$S/repo/override.cfg" ]; then fail "$name" "override.cfg left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_override_cfg_removed_when_the_run_is_signalled() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_KILL=1 run_gate
  if [ "$code" = 0 ]; then fail "$name" "exit 0 after a signal"
  elif [ -e "$S/repo/override.cfg" ]; then fail "$name" "override.cfg left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_user_dir_name_is_stable_per_checkout_and_distinct_between_them() {
  local name="${FUNCNAME[0]}"; local a1 a2 b1 b2 ta tb
  sandbox; make_fake_godot; ta="$S"
  FAKE_OVERRIDE_SNAPSHOT="$S/snap1" run_gate
  a1="$(grep -F 'config/custom_user_dir_name=' "$S/snap1" 2>/dev/null)"
  FAKE_OVERRIDE_SNAPSHOT="$S/snap2" run_gate
  a2="$(grep -F 'config/custom_user_dir_name=' "$S/snap2" 2>/dev/null)"
  sandbox; make_fake_godot; tb="$S"
  FAKE_OVERRIDE_SNAPSHOT="$S/snap1" run_gate
  b1="$(grep -F 'config/custom_user_dir_name=' "$S/snap1" 2>/dev/null)"
  FAKE_OVERRIDE_SNAPSHOT="$S/snap2" run_gate
  b2="$(grep -F 'config/custom_user_dir_name=' "$S/snap2" 2>/dev/null)"
  if [ -z "$a1" ] || [ -z "$b1" ]; then fail "$name" "no dir name captured"
  elif [ "$a1" != "$a2" ]; then fail "$name" "checkout A varied: $a1 vs $a2"
  elif [ "$b1" != "$b2" ]; then fail "$name" "checkout B varied: $b1 vs $b2"
  elif [ "$a1" = "$b1" ]; then fail "$name" "two checkouts share a dir: $a1"
  else ok "$name"; fi
  rm -rf "$ta" "$tb"
}

test_foreign_override_cfg_refuses() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  printf '[application]\n' > "$S/repo/override.cfg"
  run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: override.cfg already exists in $S/repo and was not written by gate-fast; move it aside and rerun" "$S/err"; then
    fail "$name" "stderr: $(cat "$S/err")"
  elif [ -e "$S/calls" ]; then fail "$name" "godot was called"
  elif [ "$(cat "$S/repo/override.cfg")" != "[application]" ]; then
    fail "$name" "the person's override.cfg was altered"
  else ok "$name"; fi
  rm -rf "$S"
}

test_stale_own_override_cfg_is_overwritten() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  printf '%s\n\n[application]\n\nconfig/custom_user_dir_name="Tide and Timber/gate/stale-00000000"\n' \
    "; temporary: written by scripts/gate-fast, removed when it exits" > "$S/repo/override.cfg"
  FAKE_OVERRIDE_SNAPSHOT="$S/snap" run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif grep -qF 'stale-00000000' "$S/snap" 2>/dev/null; then fail "$name" "stale name survived"
  elif ! grep -qF 'config/custom_user_dir_name="Tide and Timber/gate/' "$S/snap" 2>/dev/null; then
    fail "$name" "no dir name: $(cat "$S/snap" 2>/dev/null)"
  elif [ -e "$S/repo/override.cfg" ]; then fail "$name" "override.cfg left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_refuses_while_another_run_holds_the_lock() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  mkdir "$S/repo/gate-fast.gate.lock"
  printf '%s\n' "$$" > "$S/repo/gate-fast.gate.lock/pid"
  run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif ! grep -qF "gate-fast: another gate-fast is already running in $S/repo (pid $$); wait for it to finish" "$S/err"; then
    fail "$name" "stderr: $(cat "$S/err")"
  elif [ -e "$S/calls" ]; then fail "$name" "godot was called"
  elif [ -e "$S/repo/override.cfg" ]; then fail "$name" "override.cfg written"
  elif [ ! -d "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "the holder's lock was removed"
  else ok "$name"; fi
  rm -rf "$S"
}

test_lock_is_released_after_a_green_run() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif [ -e "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "lock left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_lock_is_released_after_a_suite_failure() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_EXIT=100 run_gate
  if [ "$code" != 1 ]; then fail "$name" "exit $code"
  elif [ -e "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "lock left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_lock_is_released_when_the_run_is_signalled() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  FAKE_SUITE_KILL=1 run_gate
  if [ "$code" = 0 ]; then fail "$name" "exit 0 after a signal"
  elif [ -e "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "lock left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_stale_lock_from_a_dead_holder_is_reclaimed() {
  local name="${FUNCNAME[0]}"; local dead
  sandbox; make_fake_godot
  sh -c 'exit 0' & dead=$!
  wait "$dead" 2>/dev/null
  mkdir "$S/repo/gate-fast.gate.lock"
  printf '%s\n' "$dead" > "$S/repo/gate-fast.gate.lock/pid"
  run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif ! grep -qF "gate-fast: reclaiming a stale lock in $S/repo" "$S/err"; then
    fail "$name" "stderr: $(cat "$S/err")"
  elif [ "$(lines "$S/calls")" != 2 ]; then fail "$name" "calls: $(lines "$S/calls")"
  elif [ -e "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "lock left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_lock_dir_with_no_pid_file_is_reclaimed() {
  local name="${FUNCNAME[0]}"; sandbox; make_fake_godot
  mkdir "$S/repo/gate-fast.gate.lock"
  run_gate
  if [ "$code" != 0 ]; then fail "$name" "exit $code: $(cat "$S/err")"
  elif ! grep -qF "gate-fast: reclaiming a stale lock in $S/repo" "$S/err"; then
    fail "$name" "stderr: $(cat "$S/err")"
  elif [ -e "$S/repo/gate-fast.gate.lock" ]; then fail "$name" "lock left behind"
  else ok "$name"; fi
  rm -rf "$S"
}

test_missing_godot_exits_1
test_default_godot_comes_from_path
test_arguments_exit_2
test_import_failure_stops_before_suite
test_green_run_exits_0_with_exact_invocations
test_suite_failure_exits_1
test_orphan_warning_exits_1
test_writes_override_cfg_naming_a_per_checkout_user_dir
test_override_cfg_removed_after_green_run
test_override_cfg_removed_after_suite_failure
test_override_cfg_removed_when_the_run_is_signalled
test_user_dir_name_is_stable_per_checkout_and_distinct_between_them
test_foreign_override_cfg_refuses
test_stale_own_override_cfg_is_overwritten
test_refuses_while_another_run_holds_the_lock
test_lock_is_released_after_a_green_run
test_lock_is_released_after_a_suite_failure
test_lock_is_released_when_the_run_is_signalled
test_stale_lock_from_a_dead_holder_is_reclaimed
test_lock_dir_with_no_pid_file_is_reclaimed
exit "$failed"
