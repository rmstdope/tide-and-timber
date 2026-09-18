#!/usr/bin/env bash
# Tests for scripts/ci-needed: docs-only changes answer run=false, everything else run=true.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

S="$(mktemp -d)"
trap 'rm -rf "$S"' EXIT

# run_it <stdin text> [args...] -> $S/out, $S/err, $code
run_it() {
  local input="$1"; shift
  printf '%s' "$input" | bash "$root/scripts/ci-needed" "$@" >"$S/out" 2>"$S/err"
  code=$?
}

test_docs_only_answers_run_false() {
  run_it $'docs/ui/a/b.html\ndocs/retrospectives/x.md\n'
  if [ "$(cat "$S/out")" = run=false ] && [ "$code" = 0 ] \
     && [ "$(cat "$S/err")" = "ci-needed: none of 2 paths reaches the gate" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "out='$(cat "$S/out")' code=$code err='$(cat "$S/err")'"; fi
}

test_readme_only_answers_run_false() {
  run_it $'README.md\n'
  if [ "$(cat "$S/out")" = run=false ] && [ "$code" = 0 ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "out='$(cat "$S/out")' code=$code"; fi
}

test_every_other_path_answers_run_true() {
  local p
  for p in src/a.gd tests/a.gd assets/a.png addons/x/y.gd project.godot export_presets.cfg \
           scripts/gate-fast .github/workflows/gate.yml src/docs/a.md docsx/a.md docs sub/README.md; do
    run_it "$p"$'\n'
    if [ "$(cat "$S/out")" != run=true ] || [ "$code" != 0 ]; then
      fail "${FUNCNAME[0]}" "$p gave '$(cat "$S/out")' code=$code"; return
    fi
  done
  ok "${FUNCNAME[0]}"
}

test_mixed_answers_run_true_naming_the_first_gate_path() {
  run_it $'docs/a.md\nsrc/b.gd\nsrc/c.gd\n'
  if [ "$(cat "$S/out")" = run=true ] && [ "$(cat "$S/err")" = "ci-needed: src/b.gd" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "out='$(cat "$S/out")' err='$(cat "$S/err")'"; fi
}

test_no_paths_answers_run_true() {
  run_it ''
  if [ "$(cat "$S/out")" = run=true ] && [ "$code" = 0 ] \
     && [ "$(cat "$S/err")" = "ci-needed: no paths given, running everything" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "out='$(cat "$S/out")' err='$(cat "$S/err")'"; fi
}

test_blank_lines_only_answer_run_true() {
  run_it $'\n\n'
  if [ "$(cat "$S/out")" = run=true ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "out='$(cat "$S/out")'"; fi
}

test_any_argument_exits_2_with_nothing_on_stdout() {
  run_it $'src/a.gd\n' --x
  if [ "$code" = 2 ] && [ ! -s "$S/out" ] && [ "$(cat "$S/err")" = "usage: ci-needed < paths" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "code=$code out='$(cat "$S/out")' err='$(cat "$S/err")'"; fi
}

test_stdout_is_exactly_one_line() {
  local input n
  for input in $'docs/a.md\n' $'src/a.gd\n'; do
    run_it "$input"
    n="$(wc -l <"$S/out" | tr -d ' ')"
    [ "$n" = 1 ] || { fail "${FUNCNAME[0]}" "stdout has $n lines for '$input'"; return; }
  done
  ok "${FUNCNAME[0]}"
}

test_docs_only_answers_run_false
test_readme_only_answers_run_false
test_every_other_path_answers_run_true
test_mixed_answers_run_true_naming_the_first_gate_path
test_no_paths_answers_run_true
test_blank_lines_only_answer_run_true
test_any_argument_exits_2_with_nothing_on_stdout
test_stdout_is_exactly_one_line
exit "$failed"
