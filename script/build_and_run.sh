#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ShortcutCoach"
BUNDLE_ID="com.gabrielblacher.ShortcutCoach"
MIN_SYSTEM_VERSION="15.0"
CORE_RESOURCE_BUNDLE="ShortcutCoach_ShortcutCoachCore.bundle"
APP_RESOURCE_BUNDLE="ShortcutCoach_ShortcutCoach.bundle"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BIN_DIR="$(swift build --show-bin-path)"
BUILD_BINARY="$BIN_DIR/$APP_NAME"

# Codesign the binary directly before staging
echo "▸ Codesigning $BUILD_BINARY with ad-hoc identity and stable bundle identifier..."
codesign --force --sign - --identifier "com.gabrielblacher.ShortcutCoach" "$BUILD_BINARY"

# ---------- Stage the .app bundle ----------
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_CONTENTS/Resources"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Copy AppIcon to Resources
cp "$ROOT_DIR/Sources/ShortcutCoach/Resources/AppIcon.icns" "$APP_CONTENTS/Resources/AppIcon.icns"

# Copy all SwiftPM resource bundles into Contents/ so Bundle.module resolves
# via Bundle.main.bundleURL (which points at Contents/ for a .app).
for rb in "$BIN_DIR"/*.bundle; do
  [ -d "$rb" ] && cp -R "$rb" "$APP_CONTENTS/$(basename "$rb")"
done

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>Shortcut Coach</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <false/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

# ---------- Helpers ----------
open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

# ---------- Mode dispatch ----------
case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    echo "=== Verify: checking staged app bundle ==="

    # 1. Info.plist exists and is a valid plist
    if ! /usr/bin/plutil -lint "$INFO_PLIST" >/dev/null 2>&1; then
      echo "FAIL: Info.plist missing or invalid" >&2; exit 1
    fi
    echo "  ✓ Info.plist valid"

    # 2. The app is a regular windowed app with an additional MenuBarExtra.
    LSE=$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null || echo "missing")
    if [ "$LSE" != "false" ]; then
      echo "FAIL: LSUIElement should be false for the main-window app" >&2; exit 1
    fi
    echo "  ✓ LSUIElement = false"

    # 3. Resource bundles are present
    for rb_name in "$CORE_RESOURCE_BUNDLE" "$APP_RESOURCE_BUNDLE"; do
      if [ ! -d "$APP_CONTENTS/$rb_name" ]; then
        echo "FAIL: resource bundle not found at $APP_CONTENTS/$rb_name" >&2; exit 1
      fi
    done
    echo "  ✓ Resource bundles present ($CORE_RESOURCE_BUNDLE, $APP_RESOURCE_BUNDLE)"

    # 4. Launch and confirm process is running
    open_app
    sleep 2
    if pgrep -x "$APP_NAME" >/dev/null; then
      echo "  ✓ Process '$APP_NAME' is running (pid $(pgrep -x "$APP_NAME" | head -1))"
    else
      echo "FAIL: '$APP_NAME' process not found after launch" >&2; exit 1
    fi

    # 5. Validate the immutable, versioned catalog inside the staged core bundle.
    CATALOG_PATH="$APP_CONTENTS/$CORE_RESOURCE_BUNDLE/mac-shortcuts.json"
    if [ ! -f "$CATALOG_PATH" ] || ! python3 -c "import json; json.load(open('$CATALOG_PATH'))" >/dev/null 2>&1; then
      echo "FAIL: immutable catalog missing or malformed" >&2; exit 1
    fi
    SCHEMA_VERSION=$(/usr/bin/plutil -extract schemaVersion raw -o - "$CATALOG_PATH")
    if [ "$SCHEMA_VERSION" != "1" ]; then
      echo "FAIL: unexpected catalog schema $SCHEMA_VERSION" >&2; exit 1
    fi
    echo "  ✓ Immutable catalog schema = 1"

    echo ""
    echo "=== ✅ Verification passed ==="
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
