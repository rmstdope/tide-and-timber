# tr-bbl.3 — retrospective

- **Implementer:** Storm
- **Date:** 2026-09-18
- **PR:** #103

## The plan's measured colour-blind scores did not reproduce, and its chosen red was the worst one

**What happened.** The plan said the new unbuildable-spot red, `#e40b29`, scored "8.5 at worst, over
CLIFF under tritan sight", and that the worst pair of cue marks scored 24.1. It set the test floors
at 8.0 and 20.0. Once `tests/camp/cue_sight_test.gd` measured every `BeachLayout.Kind` under all four
sights, `#e40b29` scored **0.2** over JUNGLE under deuteranopia, where ghost and ground both come out
as `#5e5e0d`. That is far worse than the `#e0503a` it replaced (6.8). The `WARN`/`DIM` pair scored
7.9, not 24.1. No red can clear 8.0 over the jungle, and no pack orange can clear 20 against `DIM`.
The maths was checked first: white↔black is ΔE 100.0, and pure red maps to dark yellow under
protan/deutan sight.

**Why.** Not established. The plan's figures match no ground-by-sight combination I could produce.
The likeliest cause is that the plan measured some grounds or sights and not the full grid, because
JUNGLE under deuteranopia is the obvious worst case for any red.

**Cost.** One question to the navigator mid-increment (`asking`), one follow-up bead (tr-e2w), and
about 20 minutes of measuring the pack's reds and oranges to have options ready.

**Prevent by.** When `skills/plan-bead` states a measured number that a test will then assert as a
floor, the plan should give the command or snippet that produced the number, and it should cover
every case the test will loop over. An implementer could then rerun it before the increment starts,
under the "current-source claim is checked before its increment begins" rule in
`skills/implement-bead`, *When the plan is wrong*.

**Seen before.** tr-bbl.2.1, "A planned art rule broke on the one animation it was not measured
against": a planned threshold checked against a subset of what the test covers.
