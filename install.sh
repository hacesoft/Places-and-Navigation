#!/bin/sh
# HC_INSTALLER_REV=2026-09-25.1 (obnova kódu při chybě, bez převodu dat)
set -eu

if [ "${HC_INSTALL_VERBOSE_INTERNAL:-0}" != "1" ]; then
  INSTALL_LOG="$(mktemp)"
  trap 'rm -f "$INSTALL_LOG"' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
  if HC_INSTALL_VERBOSE_INTERNAL=1 sh "$0" >"$INSTALL_LOG" 2>&1; then
    NEW_VERSION="$(sed -n 's/^Places &amp; Navigation version: //p' "$INSTALL_LOG" | head -n 1)"
    OLD_VERSION="$(sed -n 's/^Install previous version: //p' "$INSTALL_LOG" | head -n 1)"
    [ -n "$OLD_VERSION" ] || OLD_VERSION="nová instalace"
    SIZE_KIB="$(sed -n 's/^Installed size KiB: //p' "$INSTALL_LOG" | head -n 1)"
    [ -n "$NEW_VERSION" ] && [ -n "$SIZE_KIB" ] || { cat "$INSTALL_LOG" >&2; exit 1; }
    printf 'Aplikace: Places & Navigation\nVerze: %s -> %s\nVelikost instalace: %s KiB\nHotovo.\n' "$OLD_VERSION" "$NEW_VERSION" "$SIZE_KIB"
    exit 0
  else
    STATUS=$?
    cat "$INSTALL_LOG" >&2
    exit "$STATUS"
  fi
fi

PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
APP_DIR="$PROJECT_DIR/src"
INFO="$APP_DIR/appinfo/info.xml"
LEGACY_APP_ID="navigation"
LOCK_DIR="/tmp/hc_navigation-install.lock"
RUNTIME_ITEMS="appinfo css img js l10n lib templates"

say(){ printf '%s\n' "$*"; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
cleanup_lock(){ rmdir "$LOCK_DIR" >/dev/null 2>&1 || true; }

[ "$(id -u)" -eq 0 ] || die "Run this installer with: sudo sh install.sh"
command -v docker >/dev/null 2>&1 || die "Docker was not found."
[ -f "$INFO" ] || die "$INFO not found"
mkdir "$LOCK_DIR" 2>/dev/null || die "Another HC Navigation installation appears to be running: $LOCK_DIR"
trap cleanup_lock EXIT HUP INT TERM

APP_ID="$(sed -n 's:.*<id>\([^<]*\)</id>.*:\1:p' "$INFO" | head -n 1)"
APP_NAME="$(sed -n 's:.*<name>\([^<]*\)</name>.*:\1:p' "$INFO" | head -n 1)"
SOURCE_VERSION="$(sed -n 's:.*<version>\([^<]*\)</version>.*:\1:p' "$INFO" | head -n 1)"
MIN_NC_MAJOR="$(sed -n 's:.*<nextcloud[^>]*min-version="\([0-9][0-9]*\)".*:\1:p' "$INFO" | head -n 1)"
MAX_NC_MAJOR="$(sed -n 's:.*<nextcloud[^>]*max-version="\([0-9][0-9]*\)".*:\1:p' "$INFO" | head -n 1)"
[ "$APP_ID" = "hc_navigation" ] || die "Unexpected technical app id: $APP_ID"
[ -n "$APP_NAME" ] || APP_NAME="$APP_ID"
[ -n "$SOURCE_VERSION" ] || die "Could not determine app version."

for item in $RUNTIME_ITEMS; do [ -e "$APP_DIR/$item" ] || die "Required application item is missing: src/$item"; done
CORE_MANIFEST="$APP_DIR/appinfo/hc_shared_app_core.json"
[ -f "$CORE_MANIFEST" ] || die "Missing Core dependency manifest."
CORE_REQUIRED="$(sed -n 's/.*"requiredVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CORE_MANIFEST" | head -n 1)"
CORE_ID="hc_shared_app_core"
[ -n "$CORE_REQUIRED" ] || die "Could not determine required Core version."

WEB_CONTAINER=""; CRON_CONTAINER=""
container_has_occ(){ docker exec "$1" sh -c 'test -f /var/www/html/occ' >/dev/null 2>&1; }
if docker ps --format '{{.Names}}' | grep -qx 'nextcloud-app' && container_has_occ nextcloud-app; then WEB_CONTAINER=nextcloud-app; fi
if docker ps --format '{{.Names}}' | grep -qx 'nextcloud-cron' && container_has_occ nextcloud-cron; then CRON_CONTAINER=nextcloud-cron; fi
if [ -z "$WEB_CONTAINER" ]; then
  for c in $(docker ps --format '{{.Names}}' | grep -Ei 'nextcloud' || true); do case "$c" in *cron*) continue;; esac; if container_has_occ "$c"; then WEB_CONTAINER="$c"; break; fi; done
fi
if [ -z "$CRON_CONTAINER" ]; then
  for c in $(docker ps --format '{{.Names}}' | grep -Ei 'nextcloud.*cron|cron.*nextcloud' || true); do if container_has_occ "$c"; then CRON_CONTAINER="$c"; break; fi; done
fi
[ -n "$WEB_CONTAINER" ] || die "Could not find the Nextcloud web container."
say "Nextcloud web container: $WEB_CONTAINER"
[ -n "$CRON_CONTAINER" ] && say "Nextcloud cron container: $CRON_CONTAINER"

# Před prvním occ odsunout staré duplicitní kopie mimo custom_apps.
. "$PROJECT_DIR/scripts/custom-apps-safety.sh"
hc_clean_custom_apps "$APP_ID" "$WEB_CONTAINER" "$CRON_CONTAINER" || die "Could not safely move duplicate application trees out of custom_apps."

occ(){ docker exec -u www-data "$WEB_CONTAINER" php /var/www/html/occ "$@"; }
app_enabled(){ occ app:list --enabled 2>/dev/null | grep -q -- "- $1:"; }
version_at_least(){ docker exec "$WEB_CONTAINER" php -r 'exit(version_compare($argv[1], $argv[2], ">=") ? 0 : 1);' "$1" "$2"; }
version_greater(){ docker exec "$WEB_CONTAINER" php -r 'exit(version_compare($argv[1], $argv[2], ">") ? 0 : 1);' "$1" "$2"; }
read_app_version(){ docker exec "$WEB_CONTAINER" sh -c "test -f '/var/www/html/custom_apps/$1/appinfo/info.xml' && sed -n 's:.*<version>\\([^<]*\\)</version>.*:\\1:p' '/var/www/html/custom_apps/$1/appinfo/info.xml' | head -n 1" 2>/dev/null || true; }

NC_STATUS="$(occ status --output=json 2>/dev/null || true)"
NC_VERSION="$(printf '%s' "$NC_STATUS" | sed -n 's/.*"versionstring":"\([^"]*\)".*/\1/p')"
[ -n "$NC_VERSION" ] || die "Could not determine Nextcloud version."
NC_MAJOR="$(printf '%s' "$NC_VERSION" | cut -d. -f1)"
[ "$NC_MAJOR" = "35" ] || die "$APP_NAME $SOURCE_VERSION targets Nextcloud 35 only; detected $NC_VERSION."
[ "$MIN_NC_MAJOR" = "35" ] && [ "$MAX_NC_MAJOR" = "35" ] || die "info.xml must target exactly NC35."
say "Nextcloud version: $NC_VERSION"

CORE_VERSION="$(read_app_version "$CORE_ID")"
[ -n "$CORE_VERSION" ] || die "HC Shared App Core is not installed. Use the bundle installer."
version_at_least "$CORE_VERSION" "$CORE_REQUIRED" || die "HC Shared App Core $CORE_VERSION is too old; required >= $CORE_REQUIRED. Use the bundle installer."
app_enabled "$CORE_ID" || die "HC Shared App Core $CORE_VERSION is installed but disabled. Enable it or use the bundle installer."
say "HC Shared App Core: $CORE_VERSION (required >= $CORE_REQUIRED)"

CURRENT_VERSION="$(read_app_version "$APP_ID")"
say "Install previous version: ${CURRENT_VERSION:-nová instalace}"
if [ -n "$CURRENT_VERSION" ] && version_greater "$CURRENT_VERSION" "$SOURCE_VERSION"; then die "Refusing to downgrade $APP_ID from $CURRENT_VERSION to $SOURCE_VERSION."; fi
LEGACY_PRESENT=0; LEGACY_ENABLED=0
if docker exec "$WEB_CONTAINER" sh -c "test -d '/var/www/html/custom_apps/$LEGACY_APP_ID'" >/dev/null 2>&1; then LEGACY_PRESENT=1; fi
if app_enabled "$LEGACY_APP_ID"; then LEGACY_ENABLED=1; fi
[ "$LEGACY_PRESENT" -eq 1 ] && say "Legacy app '$LEGACY_APP_ID' detected. It will be preserved until hc_navigation is verified."

TMP_LOCAL="$(mktemp -d)"
STAGE="$TMP_LOCAL/$APP_ID"; mkdir -p "$STAGE"
for item in $RUNTIME_ITEMS; do cp -R "$APP_DIR/$item" "$STAGE/"; done
TARGET_DIR="/var/www/html/custom_apps/$APP_ID"
DATA_DIRECTORY="$(occ config:system:get datadirectory)"
case "$DATA_DIRECTORY" in /*) ;; *) die "Cannot locate Nextcloud data directory for deployment backup.";; esac
BACKUP_DIR="${DATA_DIRECTORY}/hc-core-deployment-backups/${APP_ID}.$(date +%Y%m%d%H%M%S).$$"
NEW_DIR="/tmp/${APP_ID}.new.$$"
REMOTE_TMP="/tmp/${APP_ID}.stage.$$"
CURRENT_ENABLED=0
if app_enabled "$APP_ID"; then CURRENT_ENABLED=1; fi
. "$PROJECT_DIR/scripts/install-transaction.sh"
hc_tx_begin "$WEB_CONTAINER" "$CRON_CONTAINER" "$APP_ID" "$TARGET_DIR" "$BACKUP_DIR" "$CURRENT_VERSION" "$CURRENT_ENABLED"

rollback(){
  nStatus=$?
  trap - EXIT HUP INT TERM
  if [ "$nStatus" -ne 0 ]; then
    printf 'ERROR: installation failed.\n' >&2
    hc_tx_restore || true
    if [ "$LEGACY_ENABLED" -eq 1 ]; then occ app:enable "$LEGACY_APP_ID" >/dev/null 2>&1 || true; fi
  fi
  rm -rf "$TMP_LOCAL" >/dev/null 2>&1 || true
  hc_cleanup_install_stage
  cleanup_lock
  exit "$nStatus"
}
trap rollback EXIT HUP INT TERM

# Nejprve připravit novou kopii mimo custom_apps.
docker exec "$WEB_CONTAINER" sh -c 'mkdir -p /var/www/html/custom_apps'
docker exec "$WEB_CONTAINER" rm -rf "$REMOTE_TMP" "$NEW_DIR" >/dev/null 2>&1 || true
docker exec "$WEB_CONTAINER" mkdir -p "$REMOTE_TMP"
docker cp "$STAGE/." "$WEB_CONTAINER:$REMOTE_TMP/"
docker exec "$WEB_CONTAINER" sh -c "mv '$REMOTE_TMP' '$NEW_DIR' && chown -R www-data:www-data '$NEW_DIR'"
for item in $RUNTIME_ITEMS; do docker exec "$WEB_CONTAINER" sh -c "test -e '$NEW_DIR/$item'" || die "Staging verification failed: $item"; done
# Před změnou aplikace ověřit PHP soubory ve stagingu.
docker exec "$WEB_CONTAINER" sh -c 'find "$1" -type f -name "*.php" -exec php -l {} \;' sh "$NEW_DIR" >"$TMP_LOCAL/php-lint.log" 2>&1 || { cat "$TMP_LOCAL/php-lint.log" >&2; die "Staged PHP validation failed."; }
if grep -q 'Errors parsing' "$TMP_LOCAL/php-lint.log"; then cat "$TMP_LOCAL/php-lint.log" >&2; die "Staged PHP validation failed."; fi

# Záloha starého kódu je mimo custom_apps. Obnova funguje i po app:enable.
hc_tx_disable_web
hc_tx_backup_web
hc_tx_place_web "$NEW_DIR"

# Starou navigaci deaktivovat až před zapnutím nové verze.
if [ "$LEGACY_ENABLED" -eq 1 ]; then occ app:disable "$LEGACY_APP_ID"; fi

docker exec "$WEB_CONTAINER" php -r 'if (function_exists("opcache_reset")) { opcache_reset(); }' >/dev/null 2>&1 || true
occ app:enable "$APP_ID"
# Navigace nemá vlastní tabulky; zapsat pouze její verzi.

CONFIG_VERSION="$(occ config:app:get "$APP_ID" installed_version 2>/dev/null || true)"
if [ "$CONFIG_VERSION" != "$SOURCE_VERSION" ]; then
  docker exec -u www-data "$WEB_CONTAINER" php -r 'require "/var/www/html/lib/base.php"; if (!\OC_App::updateApp($argv[1])) { throw new \RuntimeException("Application update failed"); }' "$APP_ID" || die "Targeted Navigation app update failed."
fi
CONFIG_VERSION="$(occ config:app:get "$APP_ID" installed_version 2>/dev/null || true)"
[ "$CONFIG_VERSION" = "$SOURCE_VERSION" ] || die "Nextcloud app config version mismatch. Expected $SOURCE_VERSION, reported ${CONFIG_VERSION:-missing}."

# Šetrně obnovit webové PHP bez vypnutí kontejneru; CLI OPcache nestačí.
if docker exec "$WEB_CONTAINER" sh -c 'command -v apache2ctl >/dev/null 2>&1'; then
  docker exec "$WEB_CONTAINER" apache2ctl -k graceful >/dev/null 2>&1 || true
  say "Web runtime refresh requested: Apache graceful reload"
elif docker exec "$WEB_CONTAINER" sh -c 'test -r /proc/1/comm && grep -qi php-fpm /proc/1/comm'; then
  docker exec "$WEB_CONTAINER" kill -USR2 1 >/dev/null 2>&1 || true
  say "Web runtime refresh requested: PHP-FPM reload"
fi
sleep 2

DEPLOYED_VERSION="$(read_app_version "$APP_ID")"
[ "$DEPLOYED_VERSION" = "$SOURCE_VERSION" ] || die "Version verification failed. Source $SOURCE_VERSION, deployed $DEPLOYED_VERSION."
app_enabled "$APP_ID" || die "$APP_ID is not enabled after installation."
for item in $RUNTIME_ITEMS; do docker exec "$WEB_CONTAINER" sh -c "test -e '$TARGET_DIR/$item'" || die "Deployment verification failed: $item"; done

# Samostatný cron svazek nahradit až po ověření webové instalace.
if [ -n "$CRON_CONTAINER" ] && [ "$CRON_CONTAINER" != "$WEB_CONTAINER" ]; then
  CRON_TARGET="/var/www/html/custom_apps/$APP_ID"; CRON_TMP="/tmp/${APP_ID}.stage.$$"
  PROBE_FILE=".hc-deploy-probe-$$"
  docker exec "$WEB_CONTAINER" touch "$TARGET_DIR/$PROBE_FILE"
  if ! docker exec "$CRON_CONTAINER" test -f "$CRON_TARGET/$PROBE_FILE"; then
    docker exec "$CRON_CONTAINER" sh -c 'mkdir -p /var/www/html/custom_apps'
    docker exec "$CRON_CONTAINER" rm -rf "$CRON_TMP" >/dev/null 2>&1 || true
    docker exec "$CRON_CONTAINER" mkdir -p "$CRON_TMP"
    docker cp "$STAGE/." "$CRON_CONTAINER:$CRON_TMP/"
    docker exec "$CRON_CONTAINER" chown -R www-data:www-data "$CRON_TMP"
    hc_tx_backup_cron
    hc_tx_place_cron "$CRON_TMP"
  fi
  docker exec "$WEB_CONTAINER" rm -f "$TARGET_DIR/$PROBE_FILE"
fi

# Starý kód je zálohovaný; původní tabulky a předvolby zůstávají.

say "$APP_NAME version: $DEPLOYED_VERSION"
SIZE_KIB="$(docker exec "$WEB_CONTAINER" du -sk "$TARGET_DIR" | awk 'NR==1 {print $1}')"
say "Installed size KiB: $SIZE_KIB"
say "Deployment verification: OK"
say "Older Navigation tables and preferences were retained."
say "$APP_NAME deployment finished successfully."
