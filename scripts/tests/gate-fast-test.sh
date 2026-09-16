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
case "$*" in
  *--import*) exit "${FAKE_IMPORT_EXIT:-0}" ;;
  *GdUnitCmdTool.gd*) exit "${FAKE_SUITE_EXIT:-0}" ;;
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

test_missing_godot_exits_1
test_default_godot_comes_from_path
test_arguments_exit_2
test_import_failure_stops_before_suite
test_green_run_exits_0_with_exact_invocations
test_suite_failure_exits_1
test_orphan_warning_exits_1
exit "$failed"
