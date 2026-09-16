# tr-ae0.3

## Vendoring download blocked by the auto-mode classifier

**What happened:** The plan says to vendor gdUnit4 from its GitHub release tarball. Auto mode refused the `curl` + `tar` step as "Untrusted Code Integration", and the bead stopped until the navigator approved it.

**Why:** Downloading third-party code into the repo is a class the classifier denies by default, and nothing in the plan or the settings allows it.

**Cost:** One round trip to the navigator, mid-build.

**Prevent by:** When a plan vendors a download, say so at claim time, or add a narrow Bash permission rule for release tarballs whose checksum is pinned.

**Seen before:** No.

## No CI checks exist to gate the merge

**What happened:** PR #6 had an empty `statusCheckRollup`, because there is no `.github/workflows` until tr-ae0.5. The Four Eye Principle's "missing check" needed the navigator's approval to merge.

**Why:** The CI bead (tr-ae0.5) is ordered after the gate bead it runs.

**Cost:** One question to the navigator. Every PR will need the same question until tr-ae0.5 merges.

**Prevent by:** Land tr-ae0.5 next, or record a standing exception in CLAUDE.md's Four Eye Principle until it does.

**Seen before:** No.
