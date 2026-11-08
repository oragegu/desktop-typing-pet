#!/usr/bin/env bash
set -euo pipefail

APP_NAME="TypingPet"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_APP="/private/tmp/typingpet-build-${UID}/Typing Pet.app"
INSTALLED_APP="/Applications/Typing Pet.app"

"$ROOT_DIR/build-macos-app.sh"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

STAGING_DIR="$(mktemp -d /Applications/.typingpet-install.XXXXXX)"
STAGED_APP="$STAGING_DIR/Typing Pet.app"
BACKUP_APP="$STAGING_DIR/Typing Pet.previous.app"

restore_previous_app() {
  if [[ -d "$BACKUP_APP" && ! -e "$INSTALLED_APP" ]]; then
    mv "$BACKUP_APP" "$INSTALLED_APP"
  fi
  rm -rf "$STAGING_DIR"
}
trap restore_previous_app EXIT

/usr/bin/ditto --noextattr --noqtn "$SOURCE_APP" "$STAGED_APP"
xattr -cr "$STAGED_APP"
xattr -d com.apple.FinderInfo "$STAGED_APP" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$STAGED_APP"

if [[ -e "$INSTALLED_APP" ]]; then
  mv "$INSTALLED_APP" "$BACKUP_APP"
fi
mv "$STAGED_APP" "$INSTALLED_APP"
codesign --verify --deep --strict --verbose=2 "$INSTALLED_APP"

rm -rf "$BACKUP_APP"
trap - EXIT
rm -rf "$STAGING_DIR"
echo "Installed: $INSTALLED_APP"
