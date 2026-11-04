#!/usr/bin/env bash
# Refresh the user copy of Caelestia from the system package and re-apply local changes:
#   1. copy /etc/xdg/quickshell/caelestia
#   2. lay caelestia-overlay/ on top (new + replaced files)
#   3. run caelestia-patches.py (targeted edits)
# Builds in a temp dir and only swaps it in if every step succeeds.
# Run after every caelestia-shell update, then restart the shell.
set -euo pipefail

here="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
src=/etc/xdg/quickshell/caelestia
dst="$here/caelestia"
bar_height=50 # keep in sync with barHeight in persona-bar/shell.qml

tmp=$(mktemp -d "$here/.caelestia-build.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

cp -r "$src/." "$tmp/"
cp -r "$here/caelestia-overlay/." "$tmp/"

# Push Caelestia's frame below the persona-bar taskbar
win="$tmp/modules/drawers/ContentWindow.qml"
grep -q 'WlrLayershell.exclusionMode: ExclusionMode.Ignore' "$win" || {
    echo "patch anchor not found in $win, Caelestia changed upstream" >&2
    exit 1
}
sed -i "s|^\(\s*\)WlrLayershell.exclusionMode: ExclusionMode.Ignore|&\n\1margins.top: $bar_height|" "$win"

python3 "$here/caelestia-patches.py" "$tmp"

# keep the last working copy for rollback: mv caelestia.prev caelestia
rm -rf "$dst.prev"
[ -d "$dst" ] && mv "$dst" "$dst.prev"
mv "$tmp" "$dst"
trap - EXIT
echo "synced $src -> $dst"
