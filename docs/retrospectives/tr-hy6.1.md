# tr-hy6.1

## A gdUnit4 report landed inside the project and was committed

**What happened:** To run single suites, I called GdUnitCmdTool with `-rd` set to an absolute scratchpad path (`/private/tmp/.../reports`). gdUnit4 wrote the report under the project root at `private/tmp/.../reports/`, not at that absolute path. `git add -A` then committed 40 report files, including a `logo.png.import` that Godot would import and export. The cold-read review caught it.

**Why:** Not fully established. gdUnit4's `-rd` seems to resolve its argument against `res://`, even when the path is absolute.

**Cost:** One review round and one extra commit. Without the review it would have shipped in the exports.

**Prevent by:** For a single-suite run, keep `-rd` inside the git-ignored `reports/` directory (for example `-rd res://reports`). Alternatively, `.gitignore` could ignore everything the gate writes. Either way, check `git status` for unexpected directories before `git add -A`.

**Seen before:** Yes, in `tr-eg9.3.md` ("gdUnit4 report paths land inside the project, even absolute ones"), with the same cause and the same fix. The second time it happened, this time in a PR under review, suggests the fix belongs in a check (for example `.gitignore` or a gate step) rather than in memory.
