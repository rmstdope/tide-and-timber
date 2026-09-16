#!/usr/bin/env bash
# Checks scripts/run against a fake Godot: it refuses arguments and a missing Godot, imports before
# launching, launches its own checkout wherever it is run from, and passes Godot's exit code through.
# Never runs a real Godot: every run sets RUN_GODOT.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; return 1; }

# Sets up the sandbox $S with a copy of scripts/run; exports the fake's environment.
sandbox() {
  unset FAKE_IMPORT_EXIT FAKE_GAME_EXIT
  S="$(cd "$(mktemp -d)" && pwd)"
  trap 'rm -rf "$S"' EXIT
  mkdir -p "$S/repo/scripts" "$S/bin"
  cp "$root/scripts/run" "$S/repo/scripts/run"
  chmod +x "$S/repo/scripts/run"
  export RUN_GODOT="$S/bin/godot" FAKE_CALLS="$S/calls"
}

make_fake_godot() {
  cat > "$S/bin/godot" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_CALLS"
case "$*" in
  *--import*) exit "${FAKE_IMPORT_EXIT:-0}" ;;
esac
exit "${FAKE_GAME_EXIT:-0}"
EOF
  chmod +x "$S/bin/godot"
}

test_missing_godot_exits_1() ( n="${FUNCNAME[0]}"
  sandbox; export RUN_GODOT="$S/nope"
  code=0; "$S/repo/scripts/run" 2>"$S/err" || code=$?
  [ "$code" = 1 ] || fail "$n" "exit $code, want 1" || return 1
  grep -qF "run: no Godot at $S/nope; run brew install --cask godot" "$S/err" \
    || fail "$n" "stderr: $(cat "$S/err")" || return 1
  [ ! -e "$S/calls" ] || fail "$n" "godot was called" || return 1
  ok "$n"
)

test_arguments_exit_2() ( n="${FUNCNAME[0]}"
  sandbox; make_fake_godot
  code=0; "$S/repo/scripts/run" --editor 2>"$S/err" || code=$?
  [ "$code" = 2 ] || fail "$n" "exit $code, want 2" || return 1
  grep -qF "run: usage: scripts/run (takes no arguments)" "$S/err" \
    || fail "$n" "stderr: $(cat "$S/err")" || return 1
  [ ! -e "$S/calls" ] || fail "$n" "godot was called" || return 1
  ok "$n"
)

test_import_failure_stops_before_launch() ( n="${FUNCNAME[0]}"
  sandbox; make_fake_godot; export FAKE_IMPORT_EXIT=3
  code=0; "$S/repo/scripts/run" 2>"$S/err" || code=$?
  [ "$code" = 1 ] || fail "$n" "exit $code, want 1" || return 1
  grep -qF "run: import failed (exit 3)" "$S/err" || fail "$n" "stderr: $(cat "$S/err")" || return 1
  ! grep -qF "run: launching" "$S/err" || fail "$n" "launched after failed import" || return 1
  lines="$(wc -l < "$S/calls" 2>/dev/null | tr -d ' ')"
  [ "$lines" = 1 ] || fail "$n" "godot called ${lines:-0} times, want 1" || return 1
  ok "$n"
)

test_launch_runs_import_then_game_from_script_checkout() ( n="${FUNCNAME[0]}"
  sandbox; make_fake_godot
  mkdir "$S/elsewhere" && cd "$S/elsewhere"
  code=0; "$S/repo/scripts/run" 2>"$S/err" || code=$?
  [ "$code" = 0 ] || fail "$n" "exit $code, want 0; stderr: $(cat "$S/err")" || return 1
  grep -qF "run: importing" "$S/err" || fail "$n" "no importing line" || return 1
  [ "$(tail -n 1 "$S/err")" = "run: launching $S/repo" ] \
    || fail "$n" "last stderr line: $(tail -n 1 "$S/err")" || return 1
  expected="$(printf '%s\n%s' "--headless --path $S/repo --import" "--path $S/repo")"
  [ "$(cat "$S/calls" 2>/dev/null)" = "$expected" ] \
    || fail "$n" "calls: $(cat "$S/calls" 2>/dev/null)" || return 1
  ok "$n"
)

test_game_exit_code_is_passed_through() ( n="${FUNCNAME[0]}"
  sandbox; make_fake_godot; export FAKE_GAME_EXIT=7
  code=0; "$S/repo/scripts/run" 2>"$S/err" || code=$?
  [ "$code" = 7 ] || fail "$n" "exit $code, want 7" || return 1
  ok "$n"
)

test_missing_godot_exits_1 || failed=1
test_arguments_exit_2 || failed=1
test_import_failure_stops_before_launch || failed=1
test_launch_runs_import_then_game_from_script_checkout || failed=1
test_game_exit_code_is_passed_through || failed=1
exit "$failed"
