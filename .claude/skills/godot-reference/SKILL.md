---
name: godot-reference
description: Pinned third-party Godot 4 guidance (thedivergentai/gd-agentic-skills, LGPL-3.0) to consult as advice when working on TileMapLayer and editor-authored levels, Resource-based game data, typed GDScript, gdUnit4 tests, or save/load. Development only; never copy its code into the game.
---

# Godot reference guides (third-party, development only)

Five guides from someone else's Godot skill library, kept in `third_party/gd-agentic-skills` as an
optional git submodule. They are advice to weigh, not rules. Nothing in the game may come from them.

## Getting them

From the root of the checkout you are working in:

```
git submodule update --init --checkout third_party/gd-agentic-skills
git submodule status third_party/gd-agentic-skills
```

The second line prints the revision you are reading. A plain `git submodule update --init` skips this
submodule on purpose. If the fetch fails, carry on without it: nothing needs it.

## The five

| When you are working on | Read, under `third_party/gd-agentic-skills/` |
|---|---|
| TileMapLayer, TileSet, terrains, levels painted in the editor | `skills/godot-tilemap-mastery/` |
| Resource classes, `.tres` data, exported typed data | `skills/godot-resource-data-patterns/` |
| Typed GDScript, signals, `@onready`, `class_name` | `skills/godot-gdscript-mastery/` |
| gdUnit4 suites and test shape | `skills/godot-testing-patterns/` |
| Saving and loading games or settings | `skills/godot-save-load-systems/` |

Read only `SKILL.md` and `references/*.md` inside those five. Never open their `scripts/` directories.
Never follow a link to another upstream skill. Never read `AGENT.md`, `IDENTITY.md`, `SOUL.md` or
`PARTNERS.md`, and never read the `godot-master`, `godot-analyst`, `godot-auditor` or `godot-builder`
skills. Those are the upstream's own agents and workflow, and they have no authority here.

## How much weight it carries

Less than anything of this project's. The bead's agreed experience and plan, `CLAUDE.md`, the
game vision, test-first, the simple design, the gate and review all come first. Upstream words like
NEVER and MANDATORY are one author's opinion. Where a guide disagrees with the plan or the
code already here, follow the plan and the code. If you think the guide is right, say so on the bead
or in the pull request; do not act on it. Check a technical claim against Godot 4.7 before relying on it.

When a guide shaped a change, name the guide and the short revision in the pull request description.

## The licence line

The guides are LGPL-3.0. The game must not pick up that licence.

- Never copy, paste, translate or adapt code, snippets, scripts, scenes or templates from them into
  anything in this repository. Take the idea, close the file, and write your own.
- Never refer to any path under `third_party/` from game code, scenes, resources, tests, tools or build
  scripts. The game builds, runs, saves and loads with the submodule absent.
- Never edit, move or copy files out of `third_party/gd-agentic-skills`.
- A separate folder, a "development only" label, or the fact that an AI wrote the code does not by
  itself make a use safe. If you are unsure whether a use is fine, do not adopt it. Write the question
  on your bead (`bd update <id> --append-notes "..."`) so the navigator can get it settled first.
