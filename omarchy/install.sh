#!/bin/bash
#
# System side of Bahya Nireekshana's bar widget (rajeevrama.nireekshana):
#
#   vnstat      per-connection traffic history (day / week / month)
#   OpenSnitch  per-app firewall: asks before an unknown app connects, keeps
#               allow/deny rules, and enforces the Bahya Nireekshana blocklists
#   nethogs     live per-app usage (opened from the widget in a terminal), and
#               daily usage per app for the app's Apps page (nireekshana-apps)
#
# Usage: sudo ./install.sh          install / repair (safe to re-run)
#        ./install.sh --check       show what's installed, change nothing
#
# Files this script owns (removed by uninstall.sh):
#   /etc/opensnitchd/nireekshana/                         blocklist / allowlist files
#   /etc/opensnitchd/rules/00[0-2]-nireekshana-*.json     rules that use them
#   /usr/local/bin/nireekshana-rules                      lets the widget list and change rules
#   /usr/share/polkit-1/actions/local.rajeevrama.nireekshana.rules.policy
#   /etc/systemd/system/nireekshana-rules-export.{service,path}
#   /usr/local/bin/nireekshana-apps, /etc/systemd/system/nireekshana-apps.service
#   /var/lib/nireekshana/apps.json                       daily usage per app
#   ~/.config/autostart/opensnitch_ui.desktop             starts the prompt window at login
#
# The project was called netwatch before. A machine set up under that name is
# moved over: its lists are kept, its rules, helper and units are replaced.
# The bar widget itself is installed by install-plugin.sh, without sudo.

set -euo pipefail

PACKAGES=(vnstat nethogs opensnitch)
LISTS=/etc/opensnitchd/nireekshana
RULES=/etc/opensnitchd/rules
OLD_LISTS=/etc/opensnitchd/netwatch
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
POLICY=/usr/share/polkit-1/actions/local.rajeevrama.nireekshana.rules.policy

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
  if [[ -x /usr/local/bin/nireekshana-rules && -f $POLICY ]]; then note "rules manager: installed"; else note "rules manager: not installed"; fi
  note "nireekshana-rules-export.path: $(systemctl is-active nireekshana-rules-export.path 2>/dev/null || true)"
  note "nireekshana-apps.service: $(systemctl is-active nireekshana-apps.service 2>/dev/null || true)"
  if [[ -e /usr/local/bin/netwatch-rules || -d $OLD_LISTS ]]; then note "old netwatch setup: still there (run with sudo to move it over)"; fi
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
# Copied, not moved: the old netwatch rules keep reading their lists until the
# renamed rules below are in place.
if [[ -d $OLD_LISTS && ! -e $LISTS ]]; then
  cp -a "$OLD_LISTS" "$LISTS"
  note "copied your netwatch lists to $LISTS"
fi
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
  "description": "$description (managed by Bahya Nireekshana)",
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

list_rule 000-nireekshana-block-domains reject lists.domains "$LISTS/block-domains" "Blocked domains"
list_rule 000-nireekshana-block-nets reject lists.nets "$LISTS/block-nets" "Blocked IPs and networks"
list_rule 001-nireekshana-allow-domains allow lists.domains "$LISTS/allow-domains" "Always-allowed domains"
list_rule 001-nireekshana-allow-nets allow lists.nets "$LISTS/allow-nets" "Always-allowed IPs and networks"

for app in "${CORE_APPS[@]}"; do
  [[ -x $app ]] || continue
  name="002-nireekshana-allow-$(basename "$app" | tr '[:upper:]' '[:lower:]')"
  write_once "$RULES/$name.json" <<EOF
{
  "created": "$now",
  "updated": "$now",
  "name": "$name",
  "description": "Core system service (managed by Bahya Nireekshana)",
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

# The renamed rules now enforce the lists, so the netwatch ones can go.
for old in "$RULES"/00[0-2]-netwatch-*.json; do
  [[ -e $old ]] || continue
  rm -f "$old"
  note "removed $old"
done
if [[ -d $OLD_LISTS ]]; then
  rm -rf "$OLD_LISTS"
  note "removed $OLD_LISTS"
fi

say "Starting OpenSnitch (firewall)"
systemctl enable --now opensnitchd.service
default_action=$(sed -n 's/.*"DefaultAction"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' /etc/opensnitchd/default-config.json 2>/dev/null | head -n1 || true)
note "When the prompt window isn't running, unknown connections get: ${default_action:-unknown} (DefaultAction in /etc/opensnitchd/default-config.json)."

# ---------- rules manager for the widget ----------

# OpenSnitch saves its rules readable by root only. A small helper exports a
# summary the widget can read (refreshed whenever rules or lists change), and
# makes the changes you ask for in the widget, after Omarchy's polkit prompt.
say "Installing the rules manager used by the widget"
if [[ -e /etc/systemd/system/netwatch-rules-export.path ]]; then
  systemctl disable --now netwatch-rules-export.path netwatch-rules-export.service 2>/dev/null || true
  rm -f /etc/systemd/system/netwatch-rules-export.service /etc/systemd/system/netwatch-rules-export.path
fi
rm -f /usr/local/bin/netwatch-rules /usr/share/polkit-1/actions/local.rajeevrama.netwatch.rules.policy
rm -rf /run/netwatch
install -m 755 "$HERE/bin/nireekshana-rules" /usr/local/bin/nireekshana-rules
install -m 644 "$HERE/polkit/local.rajeevrama.nireekshana.rules.policy" "$POLICY"
install -m 644 "$HERE/systemd/nireekshana-rules-export.service" "$HERE/systemd/nireekshana-rules-export.path" /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now nireekshana-rules-export.path
systemctl enable nireekshana-rules-export.service
systemctl start nireekshana-rules-export.service
note "rules summary: /run/nireekshana/rules.json"

say "Installing the per-app usage counter"
install -m 755 "$HERE/bin/nireekshana-apps" /usr/local/bin/nireekshana-apps
install -m 644 "$HERE/systemd/nireekshana-apps.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable nireekshana-apps.service
systemctl restart nireekshana-apps.service
note "daily usage per app: /var/lib/nireekshana/apps.json"

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
