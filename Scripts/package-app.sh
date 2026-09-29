#!/bin/zsh
set -euo pipefail
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIRECTORY/.." && pwd)"
APP_NAME="LidSleepToggle"
DIST_DIRECTORY="$PROJECT_ROOT/dist"
ZIP_PATH="$DIST_DIRECTORY/$APP_NAME.zip"
STAGING_DIRECTORY="$(/usr/bin/mktemp -d /private/tmp/LidSleepToggle.XXXXXX)"
APP_DIRECTORY="$STAGING_DIRECTORY/$APP_NAME.app"
STAGED_ZIP_PATH="$STAGING_DIRECTORY/$APP_NAME.zip"

trap '/bin/rm -rf "$STAGING_DIRECTORY"' EXIT

/usr/bin/make -C "$PROJECT_ROOT" release
BIN_DIRECTORY="$PROJECT_ROOT/.build/release"

/bin/mkdir -p "$APP_DIRECTORY/Contents/MacOS" "$APP_DIRECTORY/Contents/Resources"
/bin/cp -X "$BIN_DIRECTORY/$APP_NAME" "$APP_DIRECTORY/Contents/MacOS/$APP_NAME"
/bin/cp -X "$PROJECT_ROOT/Resources/Info.plist" "$APP_DIRECTORY/Contents/Info.plist"
/usr/bin/xattr -cr "$APP_DIRECTORY"
/usr/bin/codesign --force --deep --sign - "$APP_DIRECTORY"

/bin/mkdir -p "$DIST_DIRECTORY"
/bin/rm -rf "$DIST_DIRECTORY/$APP_NAME.app"
/bin/rm -f "$ZIP_PATH" "$ZIP_PATH.sha256"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_DIRECTORY" "$STAGED_ZIP_PATH"
/bin/cp -X "$STAGED_ZIP_PATH" "$ZIP_PATH"
/usr/bin/shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "Archive: $ZIP_PATH"
