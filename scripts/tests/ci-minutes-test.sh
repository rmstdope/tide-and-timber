#!/usr/bin/env bash
# Tests for scripts/ci-minutes against a fake gh: job-minutes rounded up per job, per-merge average.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0
ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

S="$(mktemp -d)"
trap 'rm -rf "$S"' EXIT
cat >"$S/gh" <<'GH'
#!/usr/bin/env bash
echo "$*" >>"$S/calls"
if [ "${FAKE_GH_EXIT:-0}" != 0 ]; then exit "$FAKE_GH_EXIT"; fi
case "$1" in
  run) cat "$S/runs.json" ;;
  api) for a in "$@"; do case "$a" in */runs/*/jobs) id="${a%/jobs}"; id="${id##*/}";; esac; done
       cat "$S/jobs-$id.json" ;;
esac
GH
chmod +x "$S/gh"
export S CI_MINUTES_GH="$S/gh"

# job <seconds> [conclusion] -> one job object starting 10:00:00
job() {
  local secs="$1" concl="${2:-success}"
  printf '{"started_at":"2026-09-01T10:00:00Z","completed_at":"%s","conclusion":"%s"}' \
    "$(date -u -r $((1788256800 + secs)) +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$((1788256800 + secs))" +%Y-%m-%dT%H:%M:%SZ)" "$concl"
}
jobs() { local id="$1"; shift; local IFS=,; echo "{\"jobs\":[$*]}" >"$S/jobs-$id.json"; }
run() { printf '{"databaseId":%s,"event":"%s","headBranch":"%s","conclusion":"%s"}' "$1" "$2" "$3" "$4"; }
runs() { local IFS=,; echo "[$*]" >"$S/runs.json"; }

go() { rm -f "$S/calls"; bash "$root/scripts/ci-minutes" "$@" >"$S/out" 2>"$S/err"; code=$?; }

test_wrong_argument_count_exits_2() {
  local args
  for args in "" "2026-09-01" "2026-09-01 2026-09-02 x"; do
    # shellcheck disable=SC2086
    go $args
    if [ "$code" != 2 ] || [[ "$(cat "$S/err")" != "ci-minutes: usage:"* ]]; then
      fail "${FUNCNAME[0]}" "args '$args' code=$code err='$(cat "$S/err")'"; return
    fi
  done
  ok "${FUNCNAME[0]}"
}

test_passes_the_window_and_workflow_to_gh() {
  runs; go 2026-09-01 2026-09-03
  local l; l="$(grep '^run list' "$S/calls")"
  if [[ $l == *"--workflow gate.yml"* && $l == *"--created 2026-09-01..2026-09-03"* ]]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "calls: $(cat "$S/calls" 2>/dev/null)"; fi
}

test_sums_job_minutes_rounded_up_per_job() {
  runs "$(run 1 pull_request feat success)" "$(run 2 pull_request feat cancelled)" "$(run 3 push main success)"
  jobs 1 "$(job 61)"; jobs 2 "$(job 59)"; jobs 3 "$(job 300)" "$(job 30 skipped)"
  go 2026-09-01 2026-09-03
  local want
  want=$'window 2026-09-01..2026-09-03\nruns 3 (pull_request 2, push 1, cancelled 1)\njob-minutes 8 (pull_request 3, push 5)\nmerges-to-main 1\njob-minutes-per-merge 8.0'
  if [ "$(cat "$S/out")" = "$want" ] && [ "$code" = 0 ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "code=$code out='$(cat "$S/out")' err='$(cat "$S/err")'"; fi
}

test_per_merge_has_one_decimal() {
  jobs 1 "$(job 61)"; jobs 2 "$(job 300)"; jobs 3 "$(job 1)"; jobs 4 "$(job 1)"; jobs 5 "$(job 1)"
  runs "$(run 1 push main success)" "$(run 2 push main success)" "$(run 3 pull_request f success)"
  go 2026-09-01 2026-09-03
  if ! grep -qx 'job-minutes 8 (pull_request 1, push 7)' "$S/out" || ! grep -qx 'merges-to-main 2' "$S/out" \
     || ! grep -qx 'job-minutes-per-merge 4.0' "$S/out"; then
    fail "${FUNCNAME[0]}" "two merges: $(cat "$S/out")"; return; fi
  runs "$(run 1 push main success)" "$(run 2 push main success)" "$(run 3 pull_request f success)" "$(run 4 push main success)"
  go 2026-09-01 2026-09-03
  grep -qx 'job-minutes-per-merge 3.0' "$S/out" || { fail "${FUNCNAME[0]}" "three merges: $(cat "$S/out")"; return; }
  runs "$(run 1 push main success)" "$(run 2 push main success)" "$(run 3 pull_request f success)" \
       "$(run 4 push main success)" "$(run 5 push main success)"
  go 2026-09-01 2026-09-03
  if grep -qx 'job-minutes-per-merge 2.5' "$S/out"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "four merges: $(cat "$S/out")"; fi
}

test_a_push_to_another_branch_is_not_a_merge() {
  runs "$(run 1 push other success)"; jobs 1 "$(job 61)"
  go 2026-09-01 2026-09-03
  if grep -qx 'runs 1 (pull_request 0, push 1, cancelled 0)' "$S/out" && grep -qx 'merges-to-main 0' "$S/out" \
     && grep -qx 'job-minutes-per-merge n/a' "$S/out"; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "$(cat "$S/out")"; fi
}

test_gh_failure_exits_1() {
  runs; FAKE_GH_EXIT=1 go 2026-09-01 2026-09-03
  if [ "$code" = 1 ] && [ "$(cat "$S/err")" = "ci-minutes: gh run list failed" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "code=$code err='$(cat "$S/err")'"; fi
}

test_wrong_argument_count_exits_2
test_passes_the_window_and_workflow_to_gh
test_sums_job_minutes_rounded_up_per_job
test_per_merge_has_one_decimal
test_a_push_to_another_branch_is_not_a_merge
test_gh_failure_exits_1
exit "$failed"
