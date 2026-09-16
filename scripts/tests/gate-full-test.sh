#!/usr/bin/env bash
# Checks scripts/gate-full against stub gate-fast and installer scripts and a fake Godot.
# No network and no real Godot.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

MAC="build/macos/tide-and-timber.zip"
WIN="build/windows/tide-and-timber.exe"

sandbox() {
  S="$(cd "$(mktemp -d)" && pwd)"
  mkdir -p "$S/repo/scripts" "$S/elsewhere" "$S/bin"
  cp "$root/scripts/gate-full" "$S/repo/scripts/" 2>/dev/null
  printf '#!/bin/sh\necho gate-fast >> %s/calls; exit ${FAKE_GATE_FAST_EXIT:-0}\n' "$S" > "$S/repo/scripts/gate-fast"
  printf '#!/bin/sh\necho templates >> %s/calls; exit ${FAKE_TEMPLATES_EXIT:-0}\n' "$S" > "$S/repo/scripts/install-export-templates"
  cat > "$S/bin/godot" <<FAKE
#!/bin/sh
echo "\$*" >> $S/calls
for out in "\$@"; do :; done
[ "\${FAKE_GODOT_NO_FILE:-}" = 1 ] || echo x > "\$out"
exit \${FAKE_GODOT_EXIT:-0}
FAKE
  chmod +x "$S/repo/scripts/gate-fast" "$S/repo/scripts/install-export-templates" "$S/bin/godot"
}

# run_gate [args...]: runs from $S/elsewhere; sets code; stderr in $S/err.
run_gate() {
  (cd "$S/elsewhere" && GATE_GODOT="$S/bin/godot" bash "$S/repo/scripts/gate-full" "$@" >/dev/null 2>"$S/err")
  code=$?
}

done_sb() { rm -rf "$S"; }

test_runs_gate_fast_templates_then_both_exports_in_order() {
  local t="${FUNCNAME[0]}"; sandbox
  run_gate
  local want
  want="$(printf '%s\n' gate-fast templates \
    "--headless --path $S/repo --export-release macOS $S/repo/$MAC" \
    "--headless --path $S/repo --export-release Windows $S/repo/$WIN")"
  if [ "$code" -eq 0 ] && [ "$(cat "$S/calls")" = "$want" ] \
    && [ -f "$S/repo/$MAC" ] && [ -f "$S/repo/$WIN" ] \
    && grep -qF "gate-full: exporting macOS -> $MAC" "$S/err" \
    && grep -qF "gate-full: exporting Windows -> $WIN" "$S/err" \
    && [ "$(tail -n 1 "$S/err")" = "gate-full: ok" ] && [ ! -e "$S/elsewhere/build" ]; then ok "$t"
  else fail "$t" "code=$code calls=$(cat "$S/calls" 2>/dev/null) err=$(cat "$S/err")"; fi
  done_sb
}

test_gate_fast_failure_stops_everything() {
  local t="${FUNCNAME[0]}"; sandbox
  FAKE_GATE_FAST_EXIT=3 run_gate
  if [ "$code" -eq 1 ] && grep -qF 'gate-full: gate-fast failed (exit 3)' "$S/err" \
    && [ "$(cat "$S/calls")" = gate-fast ] && [ ! -e "$S/repo/build" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_template_failure_stops_exports() {
  local t="${FUNCNAME[0]}"; sandbox
  FAKE_TEMPLATES_EXIT=1 run_gate
  if [ "$code" -eq 1 ] && grep -qF 'gate-full: export templates unavailable (exit 1)' "$S/err" \
    && [ "$(cat "$S/calls")" = "$(printf 'gate-fast\ntemplates')" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_godot_nonzero_exit_names_target() {
  local t="${FUNCNAME[0]}"; sandbox
  FAKE_GODOT_EXIT=1 run_gate
  if [ "$code" -eq 1 ] && grep -qF 'gate-full: export failed: macOS (godot exit 1)' "$S/err" \
    && ! grep -q Windows "$S/calls"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_export_without_file_fails() {
  local t="${FUNCNAME[0]}"; sandbox
  FAKE_GODOT_NO_FILE=1 run_gate
  if [ "$code" -eq 1 ] && grep -qF "gate-full: export produced no file: $MAC" "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_arguments_exit_2() {
  local t="${FUNCNAME[0]}"; sandbox
  run_gate --skip
  if [ "$code" -eq 2 ] && grep -qF 'gate-full: usage:' "$S/err" && [ ! -e "$S/calls" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_stale_build_is_removed() {
  local t="${FUNCNAME[0]}"; sandbox
  mkdir -p "$S/repo/build/macos" "$S/repo/build/windows"
  touch "$S/repo/build/macos/stale.txt" "$S/repo/build/windows/stale.txt"
  run_gate
  if [ "$code" -eq 0 ] && [ ! -e "$S/repo/build/macos/stale.txt" ] && [ ! -e "$S/repo/build/windows/stale.txt" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_runs_gate_fast_templates_then_both_exports_in_order
test_gate_fast_failure_stops_everything
test_template_failure_stops_exports
test_godot_nonzero_exit_names_target
test_export_without_file_fails
test_arguments_exit_2
test_stale_build_is_removed
exit "$failed"
