#!/usr/bin/env bash
# Checks the tracked boundary around third_party/gd-agentic-skills: an optional, pinned submodule
# that Godot ignores and the game never names. No Godot and no network.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

SUB="third_party/gd-agentic-skills"
SKILL=".claude/skills/godot-reference/SKILL.md"

test_submodule_is_declared_optional() {
  local t="${FUNCNAME[0]}" url update
  url="$(git -C "$root" config -f .gitmodules --get "submodule.$SUB.url")"
  update="$(git -C "$root" config -f .gitmodules --get "submodule.$SUB.update")"
  if [ "$url" != "https://github.com/thedivergentai/gd-agentic-skills.git" ]; then
    fail "$t" "url is '$url'"
  elif [ "$update" != "none" ]; then
    fail "$t" "update is '$update'"
  else ok "$t"; fi
}

test_submodule_is_pinned_by_gitlink() {
  local t="${FUNCNAME[0]}" entry
  entry="$(git -C "$root" ls-files -s "$SUB")"
  case "$entry" in
    "160000 "*) ok "$t" ;;
    *) fail "$t" "not a gitlink: '$entry'" ;;
  esac
}

test_third_party_is_gdignored() {
  local t="${FUNCNAME[0]}"
  if git -C "$root" ls-files --error-unmatch third_party/.gdignore >/dev/null 2>&1; then ok "$t"
  else fail "$t" "third_party/.gdignore is not tracked"; fi
}

test_nothing_in_the_game_names_the_upstream() {
  local t="${FUNCNAME[0]}" out code hits
  out="$(git -C "$root" grep -l -I -e gd-agentic-skills -e third_party/ -- \
    src assets tests tools addons project.godot export_presets.cfg 2>&1)"
  code=$?
  if [ "$code" -gt 1 ]; then fail "$t" "git grep failed ($code): $out"; return; fi
  hits="$(printf '%s\n' "$out" | grep -v -x -e 'tests/assets/third_party_not_imported_test.gd' -e '')"
  if [ -n "$hits" ]; then fail "$t" "game paths name the upstream: $hits"
  else ok "$t"; fi
}

test_skill_is_mirrored_for_copilot() {
  local t="${FUNCNAME[0]}" link
  if [ ! -f "$root/$SKILL" ]; then fail "$t" "$SKILL missing"; return; fi
  if [ "$(sed -n 2p "$root/$SKILL")" != "name: godot-reference" ]; then
    fail "$t" "second line is not 'name: godot-reference'"; return
  fi
  link="$(readlink "$root/.github/skills/godot-reference")"
  if [ "$link" != "../../.claude/skills/godot-reference" ]; then fail "$t" "mirror link is '$link'"
  else ok "$t"; fi
}

test_skill_selects_exactly_five() {
  local t="${FUNCNAME[0]}" names want
  if [ ! -f "$root/$SKILL" ]; then fail "$t" "$SKILL missing"; return; fi
  names="$(grep -E '^\| .*\| `skills/godot-[a-z0-9-]*/` \|$' "$root/$SKILL" |
    sed -E 's/.*`skills\/(godot-[a-z0-9-]*)\/` \|$/\1/' | sort | tr '\n' ' ')"
  want="godot-gdscript-mastery godot-resource-data-patterns godot-save-load-systems godot-testing-patterns godot-tilemap-mastery "
  if [ "$names" != "$want" ]; then fail "$t" "selection is '$names'"
  else ok "$t"; fi
}

test_submodule_is_declared_optional
test_submodule_is_pinned_by_gitlink
test_third_party_is_gdignored
test_nothing_in_the_game_names_the_upstream
test_skill_is_mirrored_for_copilot
test_skill_selects_exactly_five
exit "$failed"
