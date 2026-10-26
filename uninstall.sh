#!/bin/bash
#
# Removes what install.sh set up. Packages and vnstat's history are kept
# unless you pass --purge.
#
# Usage: sudo ./uninstall.sh [--purge]

set -euo pipefail

if (( EUID != 0 )); then
  echo "Run with sudo: sudo $0 $*" >&2
  exit 1
fi
user=${SUDO_USER:-}
purge=0
[[ ${1:-} == --purge ]] && purge=1

systemctl disable --now netwatch-rules-export.path netwatch-rules-export.service 2>/dev/null || true
rm -f /etc/systemd/system/netwatch-rules-export.service /etc/systemd/system/netwatch-rules-export.path \
  /usr/local/bin/netwatch-rules /usr/share/polkit-1/actions/local.rajeevrama.netwatch.rules.policy
rm -rf /run/netwatch
systemctl daemon-reload
echo "Removed the widget's rules manager."

rm -f /etc/opensnitchd/rules/000-netwatch-*.json /etc/opensnitchd/rules/001-netwatch-*.json \
  /etc/opensnitchd/rules/002-netwatch-*.json
rm -rf /etc/opensnitchd/netwatch
echo "Removed netwatch's OpenSnitch rules and lists (rules you made in OpenSnitch are untouched)."

if [[ -n $user && $user != root ]]; then
  home=$(getent passwd "$user" | cut -d: -f6)
  rm -f "$home/.config/autostart/opensnitch_ui.desktop"
  echo "Removed the OpenSnitch login item."
fi

if (( purge )); then
  pkill -x opensnitch-ui || true
  systemctl disable --now opensnitchd.service vnstat.service || true
  pacman -Rns --noconfirm opensnitch nethogs vnstat
  rm -rf /var/lib/vnstat
  echo "Removed the packages and vnstat's history."
else
  echo "Kept vnstat, OpenSnitch and nethogs installed and running. Use --purge to remove them too."
fi
