# Instructions for the fleet

# The project

Tide and Timber is a single-player 2D pixel-art survival and life-sim game with a story that
ends, aimed at a public release to players. The player is a
member of the public who bought or downloaded it; nobody else reads its output. "Working" means the
game runs, saves and loads, and the story can be played from start to end.

It ships as native desktop executables for macOS and Windows, uploaded to Steam and/or itch.io. CI
builds every merge to main; the navigator publishes tagged releases to the store by hand. Saves and
settings are local files in the OS user-data directory, mirrored by the store's cloud sync. There is
no server of our own, so "down" means only a broken build or a corrupted save.

Keyboard+mouse and gamepad are both fully supported, menus included. The game is a 2D pixel game,
16x16 tiles, top-down 3/4 view, warm saturated palette, integer-scaled
from a 640x360 base. It follows game conventions, not OS ones: in-world pixel UI, controller glyphs,
Esc/Start pauses. Accessibility baseline: rebindable controls, scalable UI and text,
colour-blind-safe cues, no timing-critical inputs in the story. It has to feel **cozy, curious,
resilient**.

Built with Godot 4.7 (Homebrew's `godot` cask) and GDScript, tests under gdUnit4 (vendored in `addons/`). Unity, Unreal and
any custom engine are ruled out: licensing and weight, and no hand-rolled renderer or ECS.

## Four Eye Principle

*Read by `skills/implement-bead` and `skills/plan-bead` by this exact heading: the implementer's
whole standing approval to merge without asking. Delete it and nothing merges. The block between
the markers is synced from `templates/four-eye-principle.md` by `scripts/four-eye-sync`.*

<!-- four-eye:begin -->

Nothing merges unreviewed and nothing merges red.

An agent's change is reviewed by a **review sub-agent the implementer spawns for itself**, given the
diff and the bead, never the implementer's reasoning. It counts when: the review **chain** covers
the implementation merged, a cold read of the whole change then each delta since the round before;
every round posted in full on the pull request, naming its kind; every usable round's finding
answered by a change or posted reply explaining why; every check green. Failed or unusable attempts
may be retried; three unusable for one head require the navigator. That is the whole standing
approval, for a planned bead only.

Documentation (`docs/`, `README.md` and the like) needs no review. **`agents/` and `skills/` are
never documentation.** `scripts/app-paths --classify` settles doubt; anything it calls
`application` needs review.

**A commit that only answers findings does not restart the review.** A delta round gets the two
shas, takes the delta itself, and treats answers to its findings as **claims to check against the
code**: were the findings addressed; does the delta introduce anything new? Nothing blocking ends
the review.

What a commit does, not its size, decides its round:

- **answers findings, or only greens a red check** — delta round;
- **rebase, conflict resolution or `update-branch`** — none;
- **documentation only** — none;
- **anything else** (new behaviour, another approach, unseen work), and the first round after a
  hand-back — a fresh cold read.

<!-- four-eye:end -->

No review is asked of the code-hosting platform, and none is waited for. A review a person or a bot
leaves on the pull request anyway is read and answered like any other comment; it is not what the
approval rests on.

Everything else needs a person — a change nobody planned, a red or missing check, a finding about
approach, scope or what the audience sees, a finding answered by neither a change nor a reply, and a
review sub-agent that could not be spawned or returned nothing usable.

## Work tracking

*Read by every role through `skills/beads-workflow`, which carries the commands; this section is
where a project says anything that differs.*

Planned work is tracked in beads. An external issue tracker, if there is one, is the inbox for
outside requests and bug reports only. Every bead is created unranked and ranked later with a human;
a bead is planned in one session and implemented in another.

## Development practices

*Read by planners and implementers when deciding how much to build at once and how to test it.*

- Work is delivered in small increments that stand on their own.
- Code is written test-first.
- Prefer the simple design; say so when you decline a more general one.
- The gate is `scripts/gate-fast` (headless import + gdUnit4) before every pull request; `scripts/gate-full`
  adds the macOS and Windows release exports.
