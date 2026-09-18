#!/usr/bin/env bash
# Tests for scripts/ci-gated: a push to main skips the gate only when a live, same-repository
# artifact already records its exact tree as gated green (tr-piz).
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

S="$(mktemp -d)"
trap 'rm -rf "$S"' EXIT
mkdir -p "$S/bin"
cat > "$S/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >> "$S/gh-args"
[ -f "$S/gh-out" ] && cat "$S/gh-out"
exit "$(cat "$S/gh-code" 2>/dev/null || echo 0)"
GH
chmod +x "$S/bin/gh"
export S

T=0123456789abcdef0123456789abcdef01234567
LIVE='{"artifacts":[{"expired":false,"workflow_run":{"repository_id":1,"head_repository_id":1}}]}'

reset() { rm -f "$S/gh-args" "$S/gh-out" "$S/gh-code"; }

# run_it [args...] -> $S/out, $S/err, $code; GITHUB_REPOSITORY=o/r unless NOREPO=1
run_it() {
  if [ "${NOREPO:-}" = 1 ]; then
    env -u GITHUB_REPOSITORY PATH="$S/bin:$PATH" bash "$root/scripts/ci-gated" "$@" >"$S/out" 2>"$S/err"
  else
    GITHUB_REPOSITORY=o/r PATH="$S/bin:$PATH" bash "$root/scripts/ci-gated" "$@" >"$S/out" 2>"$S/err"
  fi
  code=$?
}

expect() { # <name> <stdout> <stderr>
  if [ "$(cat "$S/out")" = "$2" ] && [ "$code" = 0 ] && [ "$(cat "$S/err")" = "$3" ]; then ok "$1"
  else fail "$1" "out='$(cat "$S/out")' code=$code err='$(cat "$S/err")'"; fi
}

test_a_live_same_repo_artifact_answers_run_false() {
  reset; printf '%s' "$LIVE" > "$S/gh-out"
  run_it "$T"
  expect "${FUNCNAME[0]}" run=false "ci-gated: tree $T already gated green"
}

test_no_artifacts_answers_run_true() {
  reset; printf '%s' '{"artifacts":[]}' > "$S/gh-out"
  run_it "$T"
  expect "${FUNCNAME[0]}" run=true "ci-gated: tree $T not gated yet"
}

test_expired_and_fork_artifacts_do_not_count() {
  reset
  printf '%s' '{"artifacts":[{"expired":true,"workflow_run":{"repository_id":1,"head_repository_id":1}},{"expired":false,"workflow_run":{"repository_id":1,"head_repository_id":2}}]}' > "$S/gh-out"
  run_it "$T"
  expect "${FUNCNAME[0]}" run=true "ci-gated: tree $T not gated yet"
}

test_queries_the_artifact_named_for_the_tree() {
  reset; printf '%s' "$LIVE" > "$S/gh-out"
  run_it "$T"
  if [ "$(cat "$S/gh-args" 2>/dev/null)" = "api repos/o/r/actions/artifacts?name=gated-tree-$T&per_page=100" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "args='$(cat "$S/gh-args" 2>/dev/null)'"; fi
}

test_gh_failure_answers_run_true() {
  reset; printf '%s' "$LIVE" > "$S/gh-out"; echo 1 > "$S/gh-code"
  run_it "$T"
  expect "${FUNCNAME[0]}" run=true "ci-gated: could not ask GitHub, running everything"
}

test_unparseable_answer_answers_run_true() {
  reset; printf '%s' 'not json' > "$S/gh-out"
  run_it "$T"
  expect "${FUNCNAME[0]}" run=true "ci-gated: could not ask GitHub, running everything"
}

test_missing_repository_answers_run_true_without_asking() {
  reset; printf '%s' "$LIVE" > "$S/gh-out"
  NOREPO=1 run_it "$T"
  if [ -e "$S/gh-args" ]; then fail "${FUNCNAME[0]}" "gh was called"; return; fi
  expect "${FUNCNAME[0]}" run=true "ci-gated: could not ask GitHub, running everything"
}

test_bad_arguments_exit_2_with_nothing_on_stdout() {
  local args
  for args in "" "$T $T" "abc" "0123456789ABCDEF0123456789ABCDEF01234567"; do
    reset
    # shellcheck disable=SC2086
    run_it $args
    if [ "$code" != 2 ] || [ -s "$S/out" ] || [ "$(cat "$S/err")" != "usage: ci-gated <tree-sha>" ]; then
      fail "${FUNCNAME[0]}" "'$args' gave code=$code out='$(cat "$S/out")' err='$(cat "$S/err")'"; return
    fi
  done
  ok "${FUNCNAME[0]}"
}

test_stdout_is_exactly_one_line() {
  reset; printf '%s' "$LIVE" > "$S/gh-out"
  run_it "$T"; local a; a="$(wc -l < "$S/out" | tr -d ' ')"
  reset; echo 1 > "$S/gh-code"
  run_it "$T"; local b; b="$(wc -l < "$S/out" | tr -d ' ')"
  if [ "$a" = 1 ] && [ "$b" = 1 ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "lines: $a, $b"; fi
}

test_a_live_same_repo_artifact_answers_run_false
test_no_artifacts_answers_run_true
test_expired_and_fork_artifacts_do_not_count
test_queries_the_artifact_named_for_the_tree
test_gh_failure_answers_run_true
test_unparseable_answer_answers_run_true
test_missing_repository_answers_run_true_without_asking
test_bad_arguments_exit_2_with_nothing_on_stdout
test_stdout_is_exactly_one_line
exit "$failed"
