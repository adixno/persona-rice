#!/usr/bin/env bash
# Install the Persona rice. Anything it would overwrite is backed up first.
#   ./install.sh               everything (terminal greeting + Caelestia theme + bar + wallpaper)
#   ./install.sh --greeting    only the fish/fastfetch terminal greeting
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
backup="$HOME/.local/share/persona-rice/backup-$(date +%Y%m%d-%H%M%S)"
only_greeting=0
[[ ${1:-} == --greeting ]] && only_greeting=1

say() { printf '\e[1;37;41m P \e[0m %s\n' "$*"; }
warn() { printf '\e[1;30;47m ! \e[0m %s\n' "$*"; }

# copy src -> dst, backing up whatever was at dst
put() {
    local src=$1 dst=$2
    if [[ -e $dst ]]; then
        mkdir -p "$backup/$(dirname "${dst#"$HOME"/}")"
        cp -a "$dst" "$backup/${dst#"$HOME"/}"
        rm -rf "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
}

need() { command -v "$1" >/dev/null || missing+=("$1"); }
missing=()
need python3; need fastfetch; need fish
if ((!only_greeting)); then
    need caelestia; need qs; need hyprctl
fi
if ((${#missing[@]})); then
    warn "missing commands: ${missing[*]} (see README for packages)"
    exit 1
fi

# ── terminal greeting ───────────────────────────────────────────────────────────
say "terminal greeting"
put "$here/fastfetch/persona.py" "$cfg/fastfetch/persona.py"
put "$here/fastfetch/persona.jsonc" "$cfg/fastfetch/persona.jsonc"
put "$here/fish/conf.d/persona-greeting.fish" "$cfg/fish/conf.d/persona-greeting.fish"
if grep -qs 'function fish_greeting' "$cfg/fish/config.fish"; then
    warn "your config.fish defines its own fish_greeting, which overrides this one; remove it to see the greeting"
fi

if ((only_greeting)); then
    say "done. open a new fish terminal."
    exit 0
fi

# ── Caelestia: config, colour scheme, patched shell copy ────────────────────────
say "caelestia config"
put "$here/caelestia/shell-tokens.json" "$cfg/caelestia/shell-tokens.json"
put "$here/caelestia/persona-scheme.py" "$cfg/caelestia/persona-scheme.py"
put "$here/caelestia/persona-dark.txt" "$cfg/caelestia/persona-dark.txt"

# hide Caelestia's own bar on every monitor (persona-bar replaces it)
mons=$(hyprctl monitors -j | python3 -c 'import json,sys; print(json.dumps([m["name"] for m in json.load(sys.stdin)]))')
tmp=$(mktemp)
python3 - "$here/caelestia/shell.json" "$mons" >"$tmp" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
d.setdefault("bar", {})["excludedScreens"] = json.loads(sys.argv[2])
print(json.dumps(d, indent=2))
EOF
put "$tmp" "$cfg/caelestia/shell.json"
rm -f "$tmp"

# register the scheme with caelestia-cli so `caelestia scheme set -n persona` works (needs sudo)
schemes=$(python3 -c 'import caelestia, os; print(os.path.join(os.path.dirname(caelestia.__file__), "data/schemes"))' 2>/dev/null || true)
if [[ -n $schemes && -d $schemes ]]; then
    if [[ ! -e $schemes/persona/default/dark.txt ]]; then
        say "installing scheme into $schemes (sudo)"
        sudo install -Dm644 "$here/caelestia/persona-dark.txt" "$schemes/persona/default/dark.txt" ||
            warn "skipped; the scheme is still applied directly below"
    fi
else
    warn "caelestia python package not found; applying the scheme directly only"
fi

say "quickshell: persona-bar + patched caelestia"
put "$here/quickshell/persona-bar" "$cfg/quickshell/persona-bar"
put "$here/quickshell/caelestia-overlay" "$cfg/quickshell/caelestia-overlay"
put "$here/quickshell/caelestia-patches.py" "$cfg/quickshell/caelestia-patches.py"
put "$here/quickshell/sync-caelestia.sh" "$cfg/quickshell/sync-caelestia.sh"
chmod +x "$cfg/quickshell/sync-caelestia.sh"
"$cfg/quickshell/sync-caelestia.sh"

# ── wallpaper + scheme (wallpaper first: changing it can regenerate the scheme) ──
say "wallpaper"
walls="$HOME/Pictures/Wallpapers"
mkdir -p "$walls"
cp --update=none "$here"/wallpapers/*.png "$walls/"
caelestia wallpaper -f "$walls/red-slash.png" -N || warn "could not set wallpaper"
caelestia scheme set -n persona 2>/dev/null || true
python3 "$cfg/caelestia/persona-scheme.py"

# ── restart shells ──────────────────────────────────────────────────────────────
say "restarting shells"
caelestia shell -k 2>/dev/null || true
pkill -f '^qs -c persona-bar' 2>/dev/null || true
sleep 1
caelestia shell -d
qs -c persona-bar -n -d

cat <<EOF

$(say "done")
  - Hyprland borders/shadows + autostart: add hypr/persona-look.conf (hyprland.conf) or
    hypr/persona-look.lua (Lua config) from this repo. Not done for you so your config stays yours.
  - Lock screen avatar: put a square image at ~/.face
  - After every caelestia-shell update run: ~/.config/quickshell/sync-caelestia.sh
  - Backups of anything replaced: $backup
EOF
