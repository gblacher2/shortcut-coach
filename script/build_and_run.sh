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
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

# Resource membership changed during the overhaul. A clean package build avoids
# copying stale files left inside SwiftPM-generated resource bundles.
swift package clean
swift build
BIN_DIR="$(swift build --show-bin-path)"
BUILD_BINARY="$BIN_DIR/$APP_NAME"

# ---------- Stage the .app bundle ----------
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

# Copy AppIcon to Resources
cp "$ROOT_DIR/Sources/ShortcutCoach/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"

# Copy SwiftPM resource bundles into the canonical app Resources directory.
# CatalogLoader checks this packaged location before Bundle.module's developer
# fallback so distribution never depends on an absolute .build path.
for rb in "$BIN_DIR"/*.bundle; do
  [ -d "$rb" ] && cp -R "$rb" "$APP_RESOURCES/$(basename "$rb")"
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

# Sign the completed bundle so the signature seals Info.plist and resources.
echo "▸ Codesigning $APP_BUNDLE with ad-hoc identity and stable bundle identifier..."
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"

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

    # 2. The completed bundle signature must cover the executable and resources.
    if ! codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE" >/dev/null 2>&1; then
      echo "FAIL: staged app bundle signature is invalid" >&2; exit 1
    fi
    echo "  ✓ Bundle signature valid"

    # 3. The app is a regular windowed app with an additional MenuBarExtra.
    LSE=$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null || echo "missing")
    if [ "$LSE" != "false" ]; then
      echo "FAIL: LSUIElement should be false for the main-window app" >&2; exit 1
    fi
    echo "  ✓ LSUIElement = false"

    # 4. Resource bundles are present
    for rb_name in "$CORE_RESOURCE_BUNDLE" "$APP_RESOURCE_BUNDLE"; do
      if [ ! -d "$APP_RESOURCES/$rb_name" ]; then
        echo "FAIL: resource bundle not found at $APP_RESOURCES/$rb_name" >&2; exit 1
      fi
    done
    echo "  ✓ Resource bundles present ($CORE_RESOURCE_BUNDLE, $APP_RESOURCE_BUNDLE)"
    if [ -f "$APP_RESOURCES/$APP_RESOURCE_BUNDLE/mac-shortcuts.json" ] || \
       [ -f "$APP_RESOURCES/$APP_RESOURCE_BUNDLE/my-mac-environment.json" ]; then
      echo "FAIL: duplicate catalog resource found outside the core bundle" >&2; exit 1
    fi
    echo "  ✓ No duplicate catalog resources in the app bundle"

    # 5. Launch and confirm process is running
    open_app
    sleep 2
    if pgrep -x "$APP_NAME" >/dev/null; then
      echo "  ✓ Process '$APP_NAME' is running (pid $(pgrep -x "$APP_NAME" | head -1))"
    else
      echo "FAIL: '$APP_NAME' process not found after launch" >&2; exit 1
    fi
    sleep 3
    if ! pgrep -x "$APP_NAME" >/dev/null; then
      echo "FAIL: '$APP_NAME' exited during the launch stability check" >&2; exit 1
    fi
    echo "  ✓ Process remains running after 5 seconds"

    # 6. Validate the immutable, versioned catalog inside the staged core bundle.
    CATALOG_PATH="$APP_RESOURCES/$CORE_RESOURCE_BUNDLE/mac-shortcuts.json"
    if [ ! -f "$CATALOG_PATH" ]; then
      echo "FAIL: immutable catalog missing or malformed" >&2; exit 1
    fi
    if ! SCHEMA_VERSION=$(/usr/bin/plutil -extract schemaVersion raw -o - "$CATALOG_PATH" 2>/dev/null); then
      echo "FAIL: immutable catalog missing or malformed" >&2; exit 1
    fi
    if [ "$SCHEMA_VERSION" != "1" ]; then
      echo "FAIL: unexpected catalog schema $SCHEMA_VERSION" >&2; exit 1
    fi
    echo "  ✓ Immutable catalog schema = 1"

    # 7. Validate the separate, versioned My Mac environment resource.
    ENVIRONMENT_PATH="$APP_RESOURCES/$CORE_RESOURCE_BUNDLE/my-mac-environment.json"
    if [ ! -f "$ENVIRONMENT_PATH" ]; then
      echo "FAIL: My Mac environment resource missing" >&2; exit 1
    fi
    ENVIRONMENT_FORMAT=$(/usr/bin/plutil -extract format raw -o - "$ENVIRONMENT_PATH" 2>/dev/null || echo "missing")
    ENVIRONMENT_SCHEMA=$(/usr/bin/plutil -extract schemaVersion raw -o - "$ENVIRONMENT_PATH" 2>/dev/null || echo "missing")
    ENVIRONMENT_BINDINGS=$(/usr/bin/plutil -extract bindings raw -o - "$ENVIRONMENT_PATH" 2>/dev/null || echo "missing")
    ENVIRONMENT_CONFLICTS=$(/usr/bin/plutil -extract conflicts raw -o - "$ENVIRONMENT_PATH" 2>/dev/null || echo "missing")
    if [ "$ENVIRONMENT_FORMAT" != "shortcut-coach-environment/v1" ] || \
       [ "$ENVIRONMENT_SCHEMA" != "1" ] || \
       [ "$ENVIRONMENT_BINDINGS" != "37" ] || \
       [ "$ENVIRONMENT_CONFLICTS" != "3" ]; then
      echo "FAIL: My Mac environment resource has unexpected format or counts" >&2; exit 1
    fi
    echo "  ✓ My Mac environment schema = 1 (37 bindings, 3 conflicts)"

    echo ""
    echo "=== ✅ Verification passed ==="
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
