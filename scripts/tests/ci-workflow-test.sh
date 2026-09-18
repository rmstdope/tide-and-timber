#!/usr/bin/env bash
# Structural check of .github/workflows/gate.yml: triggers, the Linux runner, the pinned Godot setup action, the shell suites before gate-fast, and no exports. No network, no YAML parser.
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

SETUP='uses: chickensoft-games/setup-godot@c233594225991af5aec714e52457cc76d6df8fa2 # v2.4.2'

test_runs_on_a_pinned_ubuntu_runner() {
  if ! has_line 'runs-on: ubuntu-24.04'; then fail "${FUNCNAME[0]}" "not on ubuntu-24.04"
  elif ! has_line 'timeout-minutes: 20'; then fail "${FUNCNAME[0]}" "no 20-minute timeout"
  elif grep -qi 'macos' "$wf"; then fail "${FUNCNAME[0]}" "still mentions macos"
  else ok "${FUNCNAME[0]}"; fi
}

test_installs_godot_with_the_pinned_setup_action() {
  local l
  for l in "$SETUP" 'version: 4.7.2' 'use-dotnet: false' 'include-templates: false' 'cache: false'; do
    has_line "$l" || { fail "${FUNCNAME[0]}" "missing '$l'"; return; }
  done
  if grep -q 'brew' "$wf"; then fail "${FUNCNAME[0]}" "still mentions brew"
  else ok "${FUNCNAME[0]}"; fi
}

test_pins_the_godot_version_claude_md_names() {
  local v mm
  v="$(awk '{s=$0; sub(/^[ \t]+/,"",s)} s ~ /^version: / {sub(/^version: /,"",s); print s; exit}' "$wf")"
  if ! [[ $v =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "${FUNCNAME[0]}" "version '$v' is not major.minor.patch"; return
  fi
  mm="${v%.*}"
  if grep -q "Built with Godot $mm" "$root/CLAUDE.md"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "CLAUDE.md does not say 'Built with Godot $mm'"; fi
}

test_runs_shell_suites_then_gate_fast_after_install() {
  local n
  n="$(grep -c 'set -euo pipefail' "$wf" 2>/dev/null)"
  if ! increasing "$(step_line "$SETUP")" "$(step_line '- name: Shell suites')" \
       "$(step_line 'set -euo pipefail')" \
       "$(step_line 'for suite in scripts/tests/*-test.sh; do')" \
       "$(step_line 'bash "$suite"')" "$(step_line 'run: scripts/gate-fast')"; then
    fail "${FUNCNAME[0]}" "install, suites, gate-fast are missing or out of order"
  elif ! has_line 'submodules: false'; then fail "${FUNCNAME[0]}" "submodules not off"
  elif [ "${n:-0}" != 1 ]; then fail "${FUNCNAME[0]}" "set -euo pipefail appears '${n:-0}' times, want 1"
  else ok "${FUNCNAME[0]}"; fi
}

test_every_script_the_workflow_runs_exists_and_is_executable() {
  local suites=("$root"/scripts/tests/*-test.sh)
  if [ ! -x "$root/scripts/gate-fast" ]; then fail "${FUNCNAME[0]}" "gate-fast missing or not executable"
  elif [ ! -e "${suites[0]}" ]; then fail "${FUNCNAME[0]}" "no shell suites"
  else ok "${FUNCNAME[0]}"; fi
}

test_builds_no_exports() {
  local pat
  for pat in gate-full upload-artifact export_templates export-release build/ tags:; do
    if grep -qF -- "$pat" "$wf"; then fail "${FUNCNAME[0]}" "'$pat' found in gate.yml"; return; fi
  done
  ok "${FUNCNAME[0]}"
}

test_harness_catches_a_missing_line
test_triggers_on_push_and_pull_request_to_main
test_runs_on_a_pinned_ubuntu_runner
test_installs_godot_with_the_pinned_setup_action
test_pins_the_godot_version_claude_md_names
test_runs_shell_suites_then_gate_fast_after_install
test_every_script_the_workflow_runs_exists_and_is_executable
test_builds_no_exports
exit "$failed"
