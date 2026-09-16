#!/usr/bin/env bash
# Structural check of .github/workflows/gate.yml: triggers, the brewed Godot install, the shell
# suites before gate-full, the export-templates cache and both uploads. No network, no YAML parser.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
wf="$root/.github/workflows/gate.yml"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

# The 1-based number of the first line equal to <text> once leading whitespace is stripped.
step_line() {
  local text="$1" file="${2:-$wf}"
  [ -f "$file" ] || return 0
  awk -v t="$text" '{s=$0; sub(/^[ \t]+/,"",s)} s==t {print NR; exit}' "$file"
}
has_line() { [ -n "$(step_line "$@")" ]; }

# Every line number given is non-empty and strictly greater than the one before.
increasing() {
  local prev=0 n
  for n in "$@"; do
    [ -n "$n" ] && [ "$n" -gt "$prev" ] || return 1
    prev="$n"
  done
}

test_harness_catches_a_missing_line() {
  local S; S="$(mktemp -d)"
  echo 'name: gate' > "$S/gate.yml"
  if [ -z "$(step_line 'push:' "$S/gate.yml")" ] && ! has_line 'push:' "$S/gate.yml" \
     && has_line 'name: gate' "$S/gate.yml"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "step_line/has_line misreport"; fi
  rm -rf "$S"
}

test_triggers_on_push_and_pull_request_to_main() {
  local l
  for l in 'push:' 'pull_request:' 'contents: read' \
           "cancel-in-progress: \${{ github.event_name == 'pull_request' }}"; do
    has_line "$l" || { fail "${FUNCNAME[0]}" "missing '$l'"; return; }
  done
  local n; n="$(grep -c '^    branches: \[main\]$' "$wf" 2>/dev/null)"
  if [ "$n" = 2 ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "branches: [main] appears '$n' times, want 2"; fi
}

test_installs_godot_with_the_declared_brew_cask() {
  local declared
  declared="$(awk '$1=="install"{sub(/#.*/,""); $1=""; sub(/^[ \t]+/,""); sub(/[ \t]+$/,""); print; exit}' \
    "$root/.cerebro/project.conf")"
  if ! has_line 'runs-on: macos-26'; then fail "${FUNCNAME[0]}" "not on macos-26"
  elif ! has_line "run: $declared"; then fail "${FUNCNAME[0]}" "no 'run: $declared' step"
  elif [ "$declared" != "brew install --cask godot" ]; then fail "${FUNCNAME[0]}" "declared install is '$declared'"
  else ok "${FUNCNAME[0]}"; fi
}

test_runs_shell_suites_then_gate_full_after_install() {
  local n
  n="$(grep -c 'set -euo pipefail' "$wf" 2>/dev/null)"
  if ! increasing "$(step_line 'run: brew install --cask godot')" \
       "$(step_line 'for suite in scripts/tests/*-test.sh; do')" \
       "$(step_line 'bash "$suite"')" "$(step_line 'run: scripts/gate-full')"; then
    fail "${FUNCNAME[0]}" "install, suites, gate-full are missing or out of order"
  elif ! has_line 'submodules: false'; then fail "${FUNCNAME[0]}" "submodules not off"
  elif [ "${n:-0}" -lt 1 ]; then fail "${FUNCNAME[0]}" "no set -euo pipefail"
  else ok "${FUNCNAME[0]}"; fi
}

test_every_script_the_workflow_runs_exists_and_is_executable() {
  local suites=("$root"/scripts/tests/*-test.sh)
  if [ ! -x "$root/scripts/gate-full" ] || [ ! -x "$root/scripts/install-export-templates" ]; then
    fail "${FUNCNAME[0]}" "gate-full or install-export-templates missing or not executable"
  elif [ ! -e "${suites[0]}" ]; then fail "${FUNCNAME[0]}" "no shell suites"
  else ok "${FUNCNAME[0]}"; fi
}

test_caches_export_templates_keyed_on_godot_version() {
  local l
  for l in 'id: godot' 'uses: actions/cache@v6' \
           'path: ~/Library/Application Support/Godot/export_templates/${{ steps.godot.outputs.templates }}' \
           'key: godot-export-templates-${{ steps.godot.outputs.templates }}-${{ runner.os }}' \
           'echo "templates=${BASH_REMATCH[1]}" >> "$GITHUB_OUTPUT"'; do
    has_line "$l" || { fail "${FUNCNAME[0]}" "missing '$l'"; return; }
  done
  increasing "$(step_line 'run: brew install --cask godot')" "$(step_line 'id: godot')" \
    "$(step_line 'uses: actions/cache@v6')" "$(step_line 'run: scripts/gate-full')" \
    || { fail "${FUNCNAME[0]}" "version, cache and gate-full out of order"; return; }
  local re tre raw want got tgot
  re="$(grep -o '\^(\[0-9\].*stable)' "$wf" | head -n 1)"
  tre="$(grep -o '\^(\[0-9\].*\$)' "$root/scripts/install-export-templates" | head -n 1)"
  [ -n "$re" ] && [ -n "$tre" ] || { fail "${FUNCNAME[0]}" "cannot find the version regexes"; return; }
  for raw in '4.7.2.stable.official.ed1daf0bf:4.7.2.stable' '4.8.stable.official.abc:4.8.stable'; do
    want="${raw##*:}"; raw="${raw%:*}"
    got=""; tgot=""
    [[ $raw =~ $re ]] && got="${BASH_REMATCH[1]}"
    [[ $raw =~ $tre ]] && tgot="${BASH_REMATCH[1]}.stable"
    if [ "$got" != "$want" ] || [ "$tgot" != "$want" ]; then
      fail "${FUNCNAME[0]}" "'$raw' gives '$got' (workflow), '$tgot' (install-export-templates), want '$want'"
      return
    fi
  done
  ok "${FUNCNAME[0]}"
}

test_uploads_both_exports_and_fails_when_missing() {
  local g; g="$(step_line 'run: scripts/gate-full')"
  if ! increasing "$g" "$(step_line 'path: build/macos/tide-and-timber.zip')" \
     || ! increasing "$g" "$(step_line 'path: build/windows/')"; then
    fail "${FUNCNAME[0]}" "uploads missing or before gate-full"
  elif ! has_line 'name: tide-and-timber-macos' || ! has_line 'name: tide-and-timber-windows'; then
    fail "${FUNCNAME[0]}" "artifact names missing"
  elif [ "$(grep -c 'if-no-files-found: error' "$wf")" != 2 ] \
       || [ "$(grep -c 'uses: actions/upload-artifact@v7' "$wf")" != 2 ]; then
    fail "${FUNCNAME[0]}" "want two uploads, each failing when missing"
  else ok "${FUNCNAME[0]}"; fi
}

test_harness_catches_a_missing_line
test_triggers_on_push_and_pull_request_to_main
test_installs_godot_with_the_declared_brew_cask
test_runs_shell_suites_then_gate_full_after_install
test_every_script_the_workflow_runs_exists_and_is_executable
test_caches_export_templates_keyed_on_godot_version
test_uploads_both_exports_and_fails_when_missing
exit "$failed"
