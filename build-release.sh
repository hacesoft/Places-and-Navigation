#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SRC="$ROOT/src"
python3 "$ROOT/scripts/check-languages.py"
INFO="$SRC/appinfo/info.xml"
[ -f "$INFO" ] || { echo "ERROR: $INFO not found" >&2; exit 1; }
APP_ID="$(sed -n 's:.*<id>\([^<]*\)</id>.*:\1:p' "$INFO" | head -n 1)"
VERSION="$(sed -n 's:.*<version>\([^<]*\)</version>.*:\1:p' "$INFO" | head -n 1)"
[ -n "$APP_ID" ] || { echo "ERROR: app id not found" >&2; exit 1; }
[ -n "$VERSION" ] || { echo "ERROR: version not found" >&2; exit 1; }
for item in appinfo css img js l10n lib templates; do [ -e "$SRC/$item" ] || { echo "ERROR: missing src/$item" >&2; exit 1; }; done

# build-release.sh creates archives only. It never installs the application,
# touches Nextcloud data, or clears the shared map cache.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/hc-navigation-release.XXXXXX")"
APP="$WORK/$APP_ID"
SOURCE="$WORK/hc_navigation-$VERSION"
RELEASE="$ROOT/release"
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
mkdir -p "$APP" "$SOURCE" "$RELEASE"
# release/ contains generated output only; keep one current runtime version.
find "$RELEASE" -maxdepth 1 -type f \( -name "$APP_ID-*.zip" -o -name "$APP_ID-*.tar.gz" \) -delete
find "$RELEASE" -maxdepth 1 -type f -name 'hc-navigation-*-full-source.zip' -delete
for item in appinfo css img js l10n lib templates; do cp -R "$SRC/$item" "$APP/$item"; done
cp "$ROOT/LICENSE" "$APP/LICENSE"
(
 cd "$WORK"
 tar -czf "$RELEASE/$APP_ID-$VERSION.tar.gz" "$APP_ID"
 if command -v zip >/dev/null 2>&1; then zip -qr "$RELEASE/$APP_ID-$VERSION.zip" "$APP_ID"; fi
)

# Full source contains installation scripts, live code and bilingual documentation.
(cd "$ROOT" && tar -cf - LICENSE README.md README_CZ.md install.sh uninstall.sh build-release.sh scripts docs src) | (cd "$SOURCE" && tar -xf -)
(cd "$WORK" && zip -qr "$RELEASE/hc_navigation-$VERSION-full-source.zip" "hc_navigation-$VERSION")

echo "Built release/$APP_ID-$VERSION.tar.gz"
[ -f "$RELEASE/$APP_ID-$VERSION.zip" ] && echo "Built release/$APP_ID-$VERSION.zip"
echo "Built release/hc_navigation-$VERSION-full-source.zip"
