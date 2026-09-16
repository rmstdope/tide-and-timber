#!/usr/bin/env bash
# Checks the Godot toolchain declarations on this branch: brew installs the stock cask, the old
# install script is gone, and CLAUDE.md names the engine version as it ships. No network, no brew.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

test_install_is_brew_cask() {
  local value
  value="$(awk '$1=="install"{sub(/#.*/,""); $1=""; sub(/^[ \t]+/,""); sub(/[ \t]+$/,""); print; exit}' \
    "$root/.cerebro/project.conf")"
  if [ "$value" = "brew install --cask godot" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "install is '$value'"; fi
}

test_no_install_script() {
  if [ ! -e "$root/scripts/install-godot.sh" ]; then ok "${FUNCNAME[0]}"
  else fail "${FUNCNAME[0]}" "scripts/install-godot.sh still exists"; fi
}

test_claude_md_names_godot_4_7() {
  if ! grep -q 'Built with Godot 4.7' "$root/CLAUDE.md"; then
    fail "${FUNCNAME[0]}" "CLAUDE.md lacks 'Built with Godot 4.7'"
  elif grep -q 'Godot 4.5' "$root/CLAUDE.md"; then
    fail "${FUNCNAME[0]}" "CLAUDE.md still mentions 'Godot 4.5'"
  else ok "${FUNCNAME[0]}"; fi
}

test_install_is_brew_cask
test_no_install_script
test_claude_md_names_godot_4_7
exit "$failed"
