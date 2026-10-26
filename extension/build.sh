#!/usr/bin/env bash
# Build the Chrome and Firefox packages of the Nireekshana extension.
#
#   extension/build.sh [version]
#
# Writes extension/dist/Nireekshana-<version>-chrome.zip and
# extension/dist/Nireekshana-<version>-firefox.zip, plus unpacked copies in
# extension/dist/chrome and extension/dist/firefox for "Load unpacked".
# Needs node (18+) and either zip or python3.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(dirname "$here")"
dist="$here/dist"

if [[ $# -gt 0 && -n "$1" ]]; then
  version="${1#v}"
else
  version="$(node "$here/tools/manifest.mjs" version)"
fi

themes="$root/themes/builtin.json"
[[ -f "$themes" ]] || { echo "Missing $themes" >&2; exit 1; }

zip_dir() { # zip_dir <dir> <out.zip>
  local dir="$1" out="$2"
  rm -f "$out"
  if command -v zip >/dev/null 2>&1; then
    (cd "$dir" && zip -q -r -X "$out" .)
  else
    python3 - "$dir" "$out" <<'PY'
import os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for base, dirs, files in os.walk(src):
        dirs.sort()
        for name in sorted(files):
            path = os.path.join(base, name)
            z.write(path, os.path.relpath(path, src))
PY
  fi
}

mkdir -p "$dist"
for target in chrome firefox; do
  out="$dist/$target"
  rm -rf "$out"
  mkdir -p "$out/icons" "$out/themes"
  cp -R "$here/src/." "$out/"
  cp "$here"/icons/icon-{16,32,48,128}.png "$out/icons/"
  cp "$themes" "$out/themes/builtin.json"
  node "$here/tools/manifest.mjs" write "$target" "$version" "$out/manifest.json"
  zip_dir "$out" "$dist/Nireekshana-$version-$target.zip"
  echo "Built $dist/Nireekshana-$version-$target.zip"
done
