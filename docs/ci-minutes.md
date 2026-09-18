# Where the Actions minutes go

Measured for tr-ot1 on 2026-09-18, just after tr-3m2 moved the gate to Linux and dropped the
exports.

**First, what "minutes" means here.** The repository is public (`rmstdope/tide-and-timber`), and
GitHub does not bill standard GitHub-hosted runners on public repositories. The minutes here are
runner time and queue contention, not money, unless a larger runner is chosen.

## How this was measured

The window is 2026-09-11..2026-09-18. tr-3m2 merged on 2026-09-18, so a window starting at its
merge held one merge; it was widened to seven days and **straddles tr-3m2**: most of its runs are
the old macOS gate with exports (~5–6 min each), not today's Linux gate (~4 min).

```bash
scripts/ci-minutes 2026-09-11 2026-09-18
```

```
window 2026-09-11..2026-09-18
runs 312 (pull_request 204, push 108, cancelled 28)
job-minutes 1315 (pull_request 869, push 446)
merges-to-main 108
job-minutes-per-merge 12.2
```

Per-step timings of the post-tr-3m2 runs (only two existed; 35334028111 and 35334454074):

```bash
gh run view <id> --json jobs --jq '.jobs[] | .steps[] | [.name, .startedAt, .completedAt] | @tsv'
```

Docs-only share of the commits on `main`:

```bash
tot=0; d=0; for c in $(git rev-list --since=2026-09-11 origin/main); do tot=$((tot+1)); [ -z "$(git diff-tree --no-commit-id --name-only -r "$c" | grep -vE '^(docs/|README\.md$)')" ] && d=$((d+1)); done; echo "total=$tot docs_only=$d"
```

→ `total=129 docs_only=32`. Of the 108 `main` runs in the window, 25 were for docs-only commits
(the same test over each run's `headSha`).

`main` runs overlapped by a newer `main` push while still running:

```bash
gh run list --workflow gate.yml --created 2026-09-11..2026-09-18 -L 1000 --json event,headBranch,createdAt,updatedAt --jq '[.[]|select(.event=="push" and .headBranch=="main")]|sort_by(.createdAt)|. as $r|[range(0;length-1) as $i|select(($r[$i+1].createdAt|fromdateiso8601) < ($r[$i].updatedAt|fromdateiso8601))]|length'
```

→ `38`.

Draft pull requests ever opened:

```bash
gh pr list --state all -L 1000 --json isDraft --jq '[.[]|select(.isDraft)]|length'
```

→ `0`.

Ten slowest suites, after a local `scripts/gate-fast`:

```bash
python3 -c "import glob,xml.etree.ElementTree as E;f=sorted(glob.glob('reports/report_*/results.xml'))[-1];s=sorted(E.parse(f).iter('testsuite'),key=lambda s:-float(s.get('time') or 0))[:10];[print(f\"{float(x.get('time')):8.1f}  {x.get('name')}\") for x in s]"
```

## One gate run, step by step

The Linux gate after tr-3m2 (run 35334028111; 35334454074 within a second or two):

| Step | Seconds |
|---|---|
| Set up job + Check out | 2–3 |
| Install Godot (setup-godot, no cache) | 1–2 |
| Godot version | 0 |
| Shell suites | 4 |
| `gate-fast` (headless import + gdUnit4) | ~231 |
| **Whole job** | **~240, billed as 4 min** |

Almost the whole run is the gdUnit4 suites.

## Per merged bead

A merged bead costs 1–3 pull-request runs (a finding-answer or a retrospective commit each adds
one; 204 pull-request runs over 108 merges is ~1.9) plus one `main` run. At ~4 min a run that is
~12 job-minutes per merge on Linux; the 12.2 measured above is the same order only because the
window mixes in cheaper cancelled runs with the pricier macOS ones.

## The options

### Caching Godot

**Saves:** at most the `Install Godot` step: 1–2 s on the Linux gate (median well under the 30 s
threshold the plan set). The export templates were removed from CI by tr-3m2, so there is nothing
left to cache there.
**Costs:** a cache key to keep in step with the Godot version, and a cache restore that takes about
as long as the install.
**Verdict:** Ruled out.

### Docs-only changes

**Saves:** 32 of 129 commits on `main` in the window touched only `docs/` or `README.md` (mostly
`docs(<id>): mockup` merges); each ran a full pull-request run and a full `main` run. They now run
checkout plus one classifying step (~1 billed minute) and report a green check.
**Costs:** `scripts/ci-needed`'s skip list must lose an entry the day a suite starts reading
`docs/` or `README.md`. A gate check is still reported, so the Four Eye Principle never sees a
missing one.
**Verdict:** Applied in this bead.

### Draft pull requests

**Saves:** nothing: the fleet has opened 0 drafts ever (command above).
**Costs:** one more condition in the workflow.
**Verdict:** Ruled out.

### Superseded runs on main

**Saves:** 38 of 108 `main` runs were still running when a newer push to `main` landed. Those are
now cancelled; the newest tip is always gated in full, and they stop queueing behind each other.
**Costs:** an intermediate `main` commit has no conclusion of its own. Nothing in the repository or
the harness reads one.
**Verdict:** Applied in this bead.

### The second run after a merge

**Saves:** one run per merged bead — 108 runs and 446 job-minutes in the window.
**Costs:** `main` has no branch protection, so a pull request can merge while behind `main`; the
`main` run is the only proof that the combination is green. Without it, a semantic conflict between
two merges goes unseen until the next pull request's gate.
**Verdict:** Recommended — tr-piz.

### Self-hosted or larger runners

**Saves:** nothing on the bill: standard runners cost nothing on a public repository. Larger runners
would shorten the run and are billed.
**Costs:** a self-hosted runner on the navigator's machine would execute code from any fork's pull
request on that machine (GitHub advises against self-hosted runners on public repositories), and it
gates only while the machine is on.
**Verdict:** Ruled out.

### The gdUnit4 suites themselves

**Saves:** ~231 s of the ~240 s run is `gate-fast`; any second cut is saved on every run. The ten
slowest suites locally (seconds):

| Suite | s |
|---|---|
| click_walk_test | 17.4 |
| beach_scene_test | 13.5 |
| title_continue_test | 6.8 |
| story_page_test | 6.0 |
| gamepad_build_test | 5.0 |
| placing_scene_test | 4.6 |
| pause_change_slot_test | 4.5 |
| pause_controls_test | 4.5 |
| shelter_line_scene_test | 4.3 |
| beach_pause_test | 4.1 |

**Costs:** real work per suite, and a risk of weakening what a suite proves.
**Verdict:** Recommended — tr-7zs.

### The retrospective commit's extra run

**Saves:** one pull-request run per bead that writes a retrospective, if it were committed in the
same push as the last code change.
**Costs:** a change to `implement-bead`, which lives in the cerebro harness; there is no bead for it
on this board. It is for the harness to take up.
**Verdict:** Recommended for the harness.

## What was applied, and the expected effect

- **Docs-only skip.** Over the window, 25 of 108 merges were docs-only. At ~2.9 runs per merge they
  would have cost ~1 job-minute a run instead of ~4: roughly 25 × 2.9 × 3 ≈ 220 job-minutes, or
  ~2 per merge averaged over all merges.
- **Cancelling superseded `main` runs.** 38 overlapped runs; each cancelled one saves the rest of
  its ~4 minutes, roughly 1–2 minutes apiece, ~50–75 job-minutes, and shortens the queue.
- **Remaining:** at today's Linux gate, about 9–10 job-minutes per merge, almost all of it gdUnit4
  (tr-7zs) and the second run after a merge (tr-piz).

Re-measure with `scripts/ci-minutes` over three days before and three days after this lands.
