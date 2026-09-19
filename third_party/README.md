# Third-party development material

Everything under this directory is someone else's work, kept for development only. It is never part
of the game, its build, or anything given to players. Godot ignores this directory (`.gdignore`).

## gd-agentic-skills

- Upstream: `https://github.com/thedivergentai/gd-agentic-skills`
- Licence: GNU LGPL-3.0; the licence text is the `LICENSE` file in the upstream checkout.
- How it is stored: a git submodule. This repository records only the upstream URL and a commit sha
  and copies none of its files. The pinned revision is whatever
  `git submodule status third_party/gd-agentic-skills` prints.
- Fetching it (optional; nothing needs it):
  `git submodule update --init --checkout third_party/gd-agentic-skills` (plain
  `git submodule update --init` skips it on purpose: `update = none`).
- What is used from it: the five skills listed in `.claude/skills/godot-reference/SKILL.md`, read as
  advice through that skill, and nothing else.

## Rules

- Nothing from this directory is copied, adapted, translated or moved into the game's code, scenes,
  resources, tests, tools or build.
- Nothing in the game or its build refers to a path in this directory. The game builds, runs, saves
  and loads with it absent.
- Files here are never edited. A new revision is a pull request that changes the submodule's sha, and
  it is reviewed like code.
- Adding a skill to the selection is a reviewed change to `.claude/skills/godot-reference/SKILL.md`.
- Keeping this material in a separate directory, labelling it development-only, or having an AI write
  the code does not by itself settle a licensing question. Any use whose effect on the game's licence
  is unclear stops until it has been settled.
