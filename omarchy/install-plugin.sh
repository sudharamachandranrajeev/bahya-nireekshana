#!/bin/bash
#
# Puts the Bahya Nireekshana bar widget (rajeevrama.nireekshana) into the
# Omarchy shell for the current user. No root needed; run it again after
# changing anything in plugin/.
#
#   omarchy/install-plugin.sh              install or update the widget
#   omarchy/install-plugin.sh --uninstall  take it out of the bar and remove it
#
# The widget was called rajeevrama.netwatch before; that copy is replaced and
# its place and settings in the bar are kept.

set -euo pipefail

ID=rajeevrama.nireekshana
OLD_ID=rajeevrama.netwatch
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy
PLUGINS=$CONFIG/plugins
SHELL_JSON=$CONFIG/shell.json
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

note() { printf '  %s\n' "$*"; }

if (( EUID == 0 )); then
  echo "Run this as yourself, without sudo: the widget lives in your own config." >&2
  exit 1
fi

if [[ ${1:-} == --uninstall ]]; then
  command -v omarchy >/dev/null && omarchy plugin disable "$ID" >/dev/null 2>&1 || true
  rm -rf "${PLUGINS:?}/$ID"
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  echo "Removed the bar widget."
  exit 0
fi

# Copy beside the old copy, then swap, so the shell never loads half a widget.
mkdir -p "$PLUGINS"
staging=$(mktemp -d "$PLUGINS/.$ID.XXXXXX")
trap 'rm -rf "$staging"' EXIT
cp -a "$HERE/plugin/." "$staging/"
chmod 755 "$staging"
rm -rf "${PLUGINS:?}/$ID.old"
[[ -e $PLUGINS/$ID ]] && mv "$PLUGINS/$ID" "$PLUGINS/$ID.old"
mv "$staging" "$PLUGINS/$ID"
rm -rf "${PLUGINS:?}/$ID.old"
note "widget: $PLUGINS/$ID"

if [[ -f $SHELL_JSON ]] && grep -q "\"$OLD_ID\"" "$SHELL_JSON"; then
  # Renamed in place: same spot in the bar, same settings.
  sed -i "s/\"$OLD_ID\"/\"$ID\"/g" "$SHELL_JSON"
  note "bar: replaced the netwatch widget in place"
fi
rm -rf "${PLUGINS:?}/$OLD_ID"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true

if [[ -f $SHELL_JSON ]] && grep -q "\"$ID\"" "$SHELL_JSON"; then
  note "bar: in place"
else
  omarchy plugin enable "$ID" --section right --before rajeevrama.paattu >/dev/null 2>&1 \
    || omarchy plugin enable "$ID" --section right >/dev/null 2>&1 \
    || note "couldn't add it to the bar: omarchy plugin enable $ID"
  note "bar: right section"
fi
