#!/usr/bin/env bash
# Persona SDDM theme. Drop any picture at sddm/persona/background.png to use it
# as the login background; otherwise wallpapers/red-slash.png is used.
#   sudo ./install.sh            install sddm + theme + config (does NOT touch your current login manager)
#   sudo ./install.sh --enable   additionally switch the display manager from greetd to sddm (next boot)
#   sudo ./install.sh --revert   switch back to greetd
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)

case ${1:-} in
    --revert)
        systemctl disable sddm.service
        systemctl enable -f greetd.service
        echo "reverted: greetd will start on next boot"
        exit 0 ;;
    ""|--enable) ;;
    *) echo "usage: sudo $0 [--enable|--revert]"; exit 2 ;;
esac

pacman -S --needed --noconfirm sddm

rm -rf /usr/share/sddm/themes/persona
install -d /usr/share/sddm/themes
cp -r "$here/persona" /usr/share/sddm/themes/persona
# background.png is your own picture (not tracked); fall back to the rice wallpaper
if [[ ! -f /usr/share/sddm/themes/persona/background.png ]]; then
    cp "$here/../wallpapers/red-slash.png" /usr/share/sddm/themes/persona/background.png
fi
chmod -R a+rX /usr/share/sddm/themes/persona

install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/persona.conf <<'CONF'
[General]
DisplayServer=x11

[Theme]
Current=persona
CONF
echo "theme installed to /usr/share/sddm/themes/persona"

if [[ ${1:-} == --enable ]]; then
    systemctl disable greetd.service || true
    systemctl enable -f sddm.service
    echo "sddm enabled; takes effect on next boot (greetd left installed for rollback)"
fi
