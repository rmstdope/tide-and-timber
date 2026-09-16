#!/usr/bin/env bash
# Checks scripts/install-export-templates against a fake Godot and a file:// release.
# No network and no real Godot.
set -u
root="$(cd "$(dirname "$0")/../.." && pwd)"
failed=0

ok()   { echo "ok $1"; }
fail() { echo "FAIL $1: $2"; failed=1; }

sandbox() {
  S="$(cd "$(mktemp -d)" && pwd)"
  mkdir -p "$S/repo/scripts" "$S/bin" "$S/home" "$S/rel"
  cp "$root/scripts/install-export-templates" "$S/repo/scripts/" 2>/dev/null
  case "$(uname -s)" in
    Darwin) T="$S/home/Library/Application Support/Godot/export_templates" ;;
    Linux)  T="$S/home/.local/share/godot/export_templates" ;;
    *)      T="" ;;
  esac
}

make_fake_godot() {
  printf '#!/bin/sh\nprintf '"'"'%%s\\n'"'"' '"'"'%s'"'"'\n' "$1" > "$S/bin/godot"
  chmod +x "$S/bin/godot"
}

make_release() {
  local num="$1" tpz
  rm -rf "$S/src"; mkdir -p "$S/src/templates" "$S/rel/$num-stable"
  printf '%s\n' "$num.stable" > "$S/src/templates/version.txt"
  printf 'm' > "$S/src/templates/macos.zip"
  printf 'w' > "$S/src/templates/windows_release_x86_64.exe"
  tpz="$S/rel/$num-stable/Godot_v$num-stable_export_templates.tpz"
  (cd "$S/src" && zip -qr "$tpz" templates)
  echo "$(shasum -a 512 "$tpz" | awk '{print $1}')  Godot_v$num-stable_export_templates.tpz" \
    > "$S/rel/$num-stable/SHA512-SUMS.txt"
}

# run_it [args...]: sets code; stderr in $S/err.
run_it() {
  (unset XDG_DATA_HOME; HOME="$S/home" GATE_GODOT="${GODOT_VALUE-$S/bin/godot}" \
    GODOT_RELEASES_URL="${URL_VALUE-file://$S/rel}" \
    bash "$S/repo/scripts/install-export-templates" "$@" >/dev/null 2>"$S/err")
  code=$?
}

no_staging() { ! ls -A "$T" 2>/dev/null | grep -q '^\.staging\.'; }
done_sb() { rm -rf "$S"; }

test_arguments_exit_2() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf
  run_it --force
  if [ "$code" -eq 2 ] && grep -q 'install-export-templates: usage:' "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_missing_godot_exits_1() {
  local t="${FUNCNAME[0]}"; sandbox
  GODOT_VALUE="$S/nope" run_it
  if [ "$code" -eq 1 ] && grep -qF "install-export-templates: no godot at $S/nope; run brew install --cask godot" "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_non_stable_version_exits_1() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.8.dev.custom_build.abc123
  run_it
  if [ "$code" -eq 1 ] && grep -qF "unsupported godot version '4.8.dev.custom_build.abc123'" "$S/err" && [ -n "$T" ] && [ ! -e "$T" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_installs_matching_templates() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  run_it
  local d="$T/4.7.2.stable"
  if [ "$code" -eq 0 ] && [ "$(cat "$d/version.txt" 2>/dev/null)" = "4.7.2.stable" ] \
    && [ -f "$d/macos.zip" ] && [ -f "$d/windows_release_x86_64.exe" ] \
    && [ "$(tail -n 1 "$S/err")" = "install-export-templates: installed 4.7.2.stable in $d" ] && no_staging; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_already_installed_skips_download() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  run_it
  URL_VALUE="file://$S/gone" run_it
  if [ "$code" -eq 0 ] && grep -q '4.7.2.stable already installed in' "$S/err" && ! grep -q downloading "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_incomplete_install_is_replaced() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  mkdir -p "$T/4.7.2.stable"; echo 4.7.2.stable > "$T/4.7.2.stable/version.txt"
  run_it
  if [ "$code" -eq 0 ] && [ -f "$T/4.7.2.stable/macos.zip" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_version_without_patch_uses_short_tag() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.8.stable.official.abc; make_release 4.8
  run_it
  if [ "$code" -eq 0 ] && [ "$(cat "$T/4.8.stable/version.txt" 2>/dev/null)" = "4.8.stable" ]; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_checksum_mismatch_installs_nothing() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  echo "$(printf '0%.0s' $(seq 128))  Godot_v4.7.2-stable_export_templates.tpz" > "$S/rel/4.7.2-stable/SHA512-SUMS.txt"
  run_it
  if [ "$code" -eq 1 ] && grep -qF 'checksum mismatch for Godot_v4.7.2-stable_export_templates.tpz' "$S/err" \
    && [ ! -e "$T/4.7.2.stable" ] && no_staging; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_unlisted_archive_installs_nothing() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  : > "$S/rel/4.7.2-stable/SHA512-SUMS.txt"
  run_it
  if [ "$code" -eq 1 ] && grep -qF 'no checksum listed for Godot_v4.7.2-stable_export_templates.tpz' "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_download_failure_exits_1() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf
  run_it
  if [ "$code" -eq 1 ] && grep -qF 'download failed (exit ' "$S/err" && grep -qF "file://$S/rel/4.7.2-stable/SHA512-SUMS.txt" "$S/err"; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_wrong_version_archive_installs_nothing() {
  local t="${FUNCNAME[0]}"; sandbox; make_fake_godot 4.7.2.stable.official.ed1daf0bf; make_release 4.7.2
  local tpz="$S/rel/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
  printf '4.7.1.stable\n' > "$S/src/templates/version.txt"; rm -f "$tpz"
  (cd "$S/src" && zip -qr "$tpz" templates)
  echo "$(shasum -a 512 "$tpz" | awk '{print $1}')  Godot_v4.7.2-stable_export_templates.tpz" > "$S/rel/4.7.2-stable/SHA512-SUMS.txt"
  run_it
  if [ "$code" -eq 1 ] && grep -qF 'Godot_v4.7.2-stable_export_templates.tpz does not hold templates for 4.7.2.stable' "$S/err" \
    && [ ! -e "$T/4.7.2.stable" ] && no_staging; then ok "$t"
  else fail "$t" "code=$code err=$(cat "$S/err")"; fi
  done_sb
}

test_arguments_exit_2
test_missing_godot_exits_1
test_non_stable_version_exits_1
test_installs_matching_templates
test_already_installed_skips_download
test_incomplete_install_is_replaced
test_version_without_patch_uses_short_tag
test_checksum_mismatch_installs_nothing
test_unlisted_archive_installs_nothing
test_download_failure_exits_1
test_wrong_version_archive_installs_nothing
exit "$failed"
