#!/bin/bash
#
# System side of the network widget (rajeevrama.netwatch):
#
#   vnstat      per-connection traffic history (day / week / month)
#   OpenSnitch  per-app firewall: asks before an unknown app connects, keeps
#               allow/deny rules, and enforces the netwatch blocklists
#   nethogs     live per-app usage (opened from the widget in a terminal)
#
# Usage: sudo ./install.sh          install / repair (safe to re-run)
#        ./install.sh --check       show what's installed, change nothing
#
# Files this script owns (removed by uninstall.sh):
#   /etc/opensnitchd/netwatch/                      blocklist / allowlist files
#   /etc/opensnitchd/rules/00[0-2]-netwatch-*.json  rules that use them
#   /usr/local/bin/netwatch-rules                   lets the widget list and change rules
#   /usr/share/polkit-1/actions/local.rajeevrama.netwatch.rules.policy
#   /etc/systemd/system/netwatch-rules-export.{service,path}
#   ~/.config/autostart/opensnitch_ui.desktop       starts the prompt window at login

set -euo pipefail

PACKAGES=(vnstat nethogs opensnitch)
LISTS=/etc/opensnitchd/netwatch
RULES=/etc/opensnitchd/rules
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
POLICY=/usr/share/polkit-1/actions/local.rajeevrama.netwatch.rules.policy

# System services that need the network before you can answer a prompt.
CORE_APPS=(
  /usr/lib/systemd/systemd-resolved
  /usr/lib/systemd/systemd-timesyncd
  /usr/bin/NetworkManager
  /usr/bin/pacman
)

say() { printf '\033[1m%s\033[0m\n' "$*"; }
note() { printf '  %s\n' "$*"; }

check() {
  for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then note "$(pacman -Q "$pkg")"; else note "$pkg: not installed"; fi
  done
  for unit in vnstat opensnitchd; do
    note "$unit.service: $(systemctl is-active "$unit.service" 2>/dev/null || true)"
  done
  if pgrep -x opensnitch-ui >/dev/null; then note "OpenSnitch window: running"; else note "OpenSnitch window: not running"; fi
  if [[ -d $LISTS ]]; then note "lists: $LISTS"; else note "lists: not set up"; fi
  if [[ -x /usr/local/bin/netwatch-rules && -f $POLICY ]]; then note "rules manager: installed"; else note "rules manager: not installed"; fi
  note "netwatch-rules-export.path: $(systemctl is-active netwatch-rules-export.path 2>/dev/null || true)"
}

if [[ ${1:-} == --check ]]; then
  check
  exit 0
fi

if (( EUID != 0 )); then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
user=${SUDO_USER:-}
if [[ -z $user || $user == root ]]; then
  echo "Run this through sudo from your own account, so the prompt window can be set up for you." >&2
  exit 1
fi
home=$(getent passwd "$user" | cut -d: -f6)
uid=$(id -u "$user")
group=$(id -gn "$user")

# ---------- packages ----------

say "Installing ${PACKAGES[*]}"
if ! pacman -S --needed --noconfirm "${PACKAGES[@]}"; then
  echo "pacman failed. If it was a download error, run 'omarchy update' and try again." >&2
  exit 1
fi

# ---------- vnstat ----------

say "Starting vnstat (traffic history)"
systemctl enable --now vnstat.service
note "History starts now; the widget shows numbers after vnstat's first 5-minute save."

# ---------- OpenSnitch lists and rules ----------

say "Setting up OpenSnitch blocklists and rules"
install -d -m 755 "$LISTS/block-domains" "$LISTS/block-nets" "$LISTS/allow-domains" "$LISTS/allow-nets"
# Leave OpenSnitch's own directory permissions alone if it already exists.
[[ -d $RULES ]] || install -d -m 755 "$RULES"

# Create a file only if it doesn't exist, so re-running never undoes your edits.
# OpenSnitch reloads rules on write events, so files are written in place.
write_once() {
  local path=$1
  if [[ -e $path ]]; then
    note "kept $path"
    return
  fi
  cat >"$path"
  chmod 644 "$path"
  note "wrote $path"
}

write_once "$LISTS/block-domains/list.txt" <<'EOF'
# Domains blocked for every app, in hosts format: one per line, prefixed
# with 0.0.0.0. Each name matches exactly (add www.example.com separately).
# OpenSnitch reloads this file when you save it.
#
# 0.0.0.0 example.com
EOF

write_once "$LISTS/block-nets/list.txt" <<'EOF'
# IP addresses and networks blocked for every app, in CIDR notation, one per
# line. Use /32 (IPv4) or /128 (IPv6) for a single address.
# OpenSnitch reloads this file when you save it.
#
# 203.0.113.7/32
# 198.51.100.0/24
EOF

write_once "$LISTS/allow-domains/list.txt" <<'EOF'
# Domains every app may reach without being asked, in hosts format: one per
# line, prefixed with 0.0.0.0. The blocklists still win over this list.
# OpenSnitch reloads this file when you save it.
#
# 0.0.0.0 archlinux.org
EOF

write_once "$LISTS/allow-nets/list.txt" <<'EOF'
# IP addresses and networks every app may reach without being asked, in CIDR
# notation, one per line. The blocklists still win over this list.
# OpenSnitch reloads this file when you save it.
#
# 192.168.1.0/24
EOF

now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Rules are evaluated alphabetically and a matching deny/reject or
# "precedence" rule ends the search, so the 000 blocklists beat everything,
# the 001 allowlist comes next, and your own rules from the prompts follow.
list_rule() {
  local name=$1 action=$2 operand=$3 dir=$4 description=$5
  write_once "$RULES/$name.json" <<EOF
{
  "created": "$now",
  "updated": "$now",
  "name": "$name",
  "description": "$description (managed by netwatch)",
  "enabled": true,
  "precedence": true,
  "action": "$action",
  "duration": "always",
  "operator": {
    "type": "lists",
    "operand": "$operand",
    "sensitive": false,
    "data": "$dir",
    "list": []
  }
}
EOF
}

list_rule 000-netwatch-block-domains reject lists.domains "$LISTS/block-domains" "Blocked domains"
list_rule 000-netwatch-block-nets reject lists.nets "$LISTS/block-nets" "Blocked IPs and networks"
list_rule 001-netwatch-allow-domains allow lists.domains "$LISTS/allow-domains" "Always-allowed domains"
list_rule 001-netwatch-allow-nets allow lists.nets "$LISTS/allow-nets" "Always-allowed IPs and networks"

for app in "${CORE_APPS[@]}"; do
  [[ -x $app ]] || continue
  name="002-netwatch-allow-$(basename "$app" | tr '[:upper:]' '[:lower:]')"
  write_once "$RULES/$name.json" <<EOF
{
  "created": "$now",
  "updated": "$now",
  "name": "$name",
  "description": "Core system service (managed by netwatch)",
  "enabled": true,
  "precedence": false,
  "action": "allow",
  "duration": "always",
  "operator": {
    "type": "simple",
    "operand": "process.path",
    "sensitive": false,
    "data": "$app",
    "list": []
  }
}
EOF
done

say "Starting OpenSnitch (firewall)"
systemctl enable --now opensnitchd.service
default_action=$(sed -n 's/.*"DefaultAction"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' /etc/opensnitchd/default-config.json 2>/dev/null | head -n1 || true)
note "When the prompt window isn't running, unknown connections get: ${default_action:-unknown} (DefaultAction in /etc/opensnitchd/default-config.json)."

# ---------- rules manager for the widget ----------

# OpenSnitch saves its rules readable by root only. A small helper exports a
# summary the widget can read (refreshed whenever rules or lists change), and
# makes the changes you ask for in the widget, after Omarchy's polkit prompt.
say "Installing the rules manager used by the widget"
install -m 755 "$HERE/bin/netwatch-rules" /usr/local/bin/netwatch-rules
install -m 644 "$HERE/polkit/local.rajeevrama.netwatch.rules.policy" "$POLICY"
install -m 644 "$HERE/systemd/netwatch-rules-export.service" "$HERE/systemd/netwatch-rules-export.path" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now netwatch-rules-export.path
systemctl enable netwatch-rules-export.service
systemctl start netwatch-rules-export.service
note "rules summary: /run/netwatch/rules.json"

# ---------- prompt window at login ----------

say "Starting the OpenSnitch prompt window at login for $user"
autostart="$home/.config/autostart"
install -d -o "$user" -g "$group" "$autostart"
cat >"$autostart/opensnitch_ui.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=OpenSnitch
Comment=Asks before unknown apps use the network
Exec=opensnitch-ui --background
Icon=opensnitch-ui
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
chown "$user:$group" "$autostart/opensnitch_ui.desktop"
note "wrote $autostart/opensnitch_ui.desktop"

# Start it now in the running session (the autostart generator only runs at
# login or on a user-manager reload).
user_systemctl() {
  runuser -u "$user" -- env XDG_RUNTIME_DIR="/run/user/$uid" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" systemctl --user "$@"
}
if pgrep -u "$user" -x opensnitch-ui >/dev/null; then
  note "already running"
elif [[ -S /run/user/$uid/bus ]] && user_systemctl daemon-reload \
  && user_systemctl start app-opensnitch_ui@autostart.service; then
  note "started"
else
  note "couldn't start it from here; it will start at next login (or run: opensnitch-ui &)"
fi

say "Done"
check
cat <<EOF

Next:
  * OpenSnitch now asks the first time each app connects. Choose "always" to
    remember the answer; your choices show up as rules in its window.
  * Review and change what's allowed or blocked from the widget panel:
    "Allowed & blocked" (asks for your password once every few minutes).
  * Live per-app usage: middle-click the network widget, or run: sudo nethogs -C
EOF
