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
  # The text goes through the environment: awk -v would expand escapes such as \n in it.
  T="$text" awk '{s=$0; sub(/^[ \t]+/,"",s)} s==ENVIRON["T"] {print NR; exit}' "$file"
}
has_line() { [ -n "$(step_line "$@")" ]; }

# The 1-based number of the first line equal to <text> (whitespace-stripped) after line <after>.
step_line_after() {
  local after="$1" text="$2"
  [ -n "$after" ] || return 0
  T="$text" awk -v a="$after" 'NR>a {s=$0; sub(/^[ \t]+/,"",s)} NR>a && s==ENVIRON["T"] {print NR; exit}' "$wf"
}

# Every line number given is non-empty and strictly greater than the one before.
increasing() {
  local prev=0 n
  for n in "$@"; do
    [ -n "$n" ] && [ "$n" -gt "$prev" ] || return 1
    prev="$n"
  done
}

test_cancels_superseded_runs_on_every_ref() {
  if ! has_line 'cancel-in-progress: true'; then fail "${FUNCNAME[0]}" "no cancel-in-progress: true"
  elif grep -qF 'cancel-in-progress: ${{' "$wf"; then fail "${FUNCNAME[0]}" "cancel-in-progress still conditional"
  else ok "${FUNCNAME[0]}"; fi
}

test_checkout_fetches_two_commits() {
  if increasing "$(step_line 'fetch-depth: 2')" "$(step_line 'id: changes')"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "fetch-depth: 2 missing or not before id: changes"; fi
}

test_changed_paths_step_feeds_ci_needed() {
  if increasing "$(step_line 'id: changes')" "$(step_line 'BEFORE: ${{ github.event.before }}')" \
       "$(step_line 'base=HEAD^1')" \
       "$(step_line 'git fetch --no-tags --depth=1 origin "$base" || base=""')" \
       "$(step_line 'printf '"'"'%s\n'"'"' "$paths" | scripts/ci-needed >> "$GITHUB_OUTPUT"')"; then
    ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "changed-paths step lines missing or out of order"; fi
}

test_every_step_after_changed_paths_is_conditional() {
  local c steps ifs before
  c="$(step_line 'id: changes')"
  [ -n "$c" ] || { fail "${FUNCNAME[0]}" "no id: changes"; return; }
  steps="$(awk -v c="$c" 'NR>c && /^[ \t]*- (name|uses):/' "$wf" | wc -l | tr -d ' ')"
  ifs="$(awk -v c="$c" -v t="if: steps.changes.outputs.run == 'true'" 'NR>c {s=$0; sub(/^[ \t]+/,"",s); if (s==t) n++} END {print n+0}' "$wf")"
  before="$(awk -v c="$c" 'NR<c && /steps\.changes\.outputs\.run/' "$wf")"
  if [ "$steps" -lt 2 ]; then fail "${FUNCNAME[0]}" "only $steps steps after changed paths"
  elif [ "$steps" != "$ifs" ]; then fail "${FUNCNAME[0]}" "$steps steps after changed paths, $ifs conditional"
  elif [ -n "$before" ]; then fail "${FUNCNAME[0]}" "a step before changed paths is conditional"
  else ok "${FUNCNAME[0]}"; fi
}

test_ci_needed_is_executable() {
  if [ -x "$root/scripts/ci-needed" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "scripts/ci-needed missing or not executable"; fi
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
           'cancel-in-progress: true'; do
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
  local n suites
  n="$(grep -c 'set -euo pipefail' "$wf" 2>/dev/null)"
  suites="$(step_line '- name: Shell suites')"
  if ! increasing "$(step_line "$SETUP")" "$suites" \
       "$(step_line_after "$suites" 'set -euo pipefail')" \
       "$(step_line 'for suite in scripts/tests/*-test.sh; do')" \
       "$(step_line 'bash "$suite"')" "$(step_line 'run: scripts/gate-fast')"; then
    fail "${FUNCNAME[0]}" "install, suites, gate-fast are missing or out of order"
  elif ! has_line 'submodules: false'; then fail "${FUNCNAME[0]}" "submodules not off"
  elif [ "${n:-0}" != 2 ]; then fail "${FUNCNAME[0]}" "set -euo pipefail appears '${n:-0}' times, want 2 (changed paths, shell suites)"
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
  for pat in gate-full export_templates export-release build/ tags:; do
    if grep -qF -- "$pat" "$wf"; then fail "${FUNCNAME[0]}" "'$pat' found in gate.yml"; return; fi
  done
  local n
  n="$(grep -c '^[[:space:]]*uses: actions/upload-artifact@' "$wf")"
  if [ "$n" != 1 ]; then fail "${FUNCNAME[0]}" "$n upload-artifact steps, want exactly 1"; return; fi
  ok "${FUNCNAME[0]}"
}

test_push_skips_a_tree_already_gated() {
  local c
  c="$(step_line 'id: changes')"
  if increasing "$c" \
       "$(step_line_after "$c" 'GH_TOKEN: ${{ github.token }}')" \
       "$(step_line_after "$c" 'tree="$(git rev-parse '"'"'HEAD^{tree}'"'"')"')" \
       "$(step_line_after "$c" 'echo "tree=$tree" >> "$GITHUB_OUTPUT"')" \
       "$(step_line_after "$c" 'printf '"'"'%s\n'"'"' "$tree" > "$RUNNER_TEMP/gated-tree"')" \
       "$(step_line_after "$c" 'if [ "$GITHUB_EVENT_NAME" = push ] && [ "$(scripts/ci-gated "$tree")" = run=false ]; then')" \
       "$(step_line_after "$c" 'echo run=false >> "$GITHUB_OUTPUT"')" \
       "$(step_line_after "$c" 'base=HEAD^1')"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "the tree lookup is missing or out of order in Changed paths"; fi
}

test_records_the_gated_tree_after_gate_fast() {
  local g
  g="$(step_line 'run: scripts/gate-fast')"
  if increasing "$g" \
       "$(step_line_after "$g" '- name: Record the gated tree')" \
       "$(step_line_after "$g" 'uses: actions/upload-artifact@v7')" \
       "$(step_line_after "$g" 'name: gated-tree-${{ steps.changes.outputs.tree }}')" \
       "$(step_line_after "$g" 'path: ${{ runner.temp }}/gated-tree')" \
       "$(step_line_after "$g" 'retention-days: 7')" \
       "$(step_line_after "$g" 'if-no-files-found: error')"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "no Record the gated tree step after gate-fast"; fi
}

test_reads_artifacts() {
  if has_line 'actions: read' && has_line 'contents: read'; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "permissions lack actions: read or contents: read"; fi
}

test_ci_gated_is_executable() {
  if [ -x "$root/scripts/ci-gated" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "scripts/ci-gated missing or not executable"; fi
}

test_harness_catches_a_missing_line
test_triggers_on_push_and_pull_request_to_main
test_runs_on_a_pinned_ubuntu_runner
test_installs_godot_with_the_pinned_setup_action
test_pins_the_godot_version_claude_md_names
test_runs_shell_suites_then_gate_fast_after_install
test_every_script_the_workflow_runs_exists_and_is_executable
test_builds_no_exports
test_cancels_superseded_runs_on_every_ref
test_checkout_fetches_two_commits
test_changed_paths_step_feeds_ci_needed
test_every_step_after_changed_paths_is_conditional
test_ci_needed_is_executable
test_push_skips_a_tree_already_gated
test_records_the_gated_tree_after_gate_fast
test_reads_artifacts
test_ci_gated_is_executable
exit "$failed"
