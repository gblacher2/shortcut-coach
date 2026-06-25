#!/usr/bin/env bash
# install_local_app.sh — Build ShortcutCoach and install to ~/Applications.
# Usage:
#   script/install_local_app.sh             # installs to ~/Applications (no sudo)
#   script/install_local_app.sh --system    # installs to /Applications  (may need sudo)
#
# This script is idempotent: re-running it replaces the previous install.
# It does NOT enable launch-at-login. See the note at the end for how to do
# that manually if desired.
set -euo pipefail

APP_NAME="ShortcutCoach"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_APP="$ROOT_DIR/dist/$APP_NAME.app"
BUILD_SCRIPT="$ROOT_DIR/script/build_and_run.sh"

# ── Determine install target ────────────────────────────────────────────────
USE_SYSTEM=false
if [[ "${1:-}" == "--system" ]]; then
  USE_SYSTEM=true
fi

if $USE_SYSTEM; then
  INSTALL_DIR="/Applications"
else
  INSTALL_DIR="$HOME/Applications"
fi

INSTALL_APP="$INSTALL_DIR/$APP_NAME.app"

# ── Build & stage ───────────────────────────────────────────────────────────
echo "▸ Building $APP_NAME …"

# Run the build script in --verify mode which builds, stages, launches, and
# confirms the process exists.  We only care about the build+stage part; we
# kill the launched process immediately after verification.
"$BUILD_SCRIPT" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ! -d "$DIST_APP" ]]; then
  echo "error: staged app not found at $DIST_APP" >&2
  exit 1
fi

# ── Install ─────────────────────────────────────────────────────────────────
echo "▸ Installing to $INSTALL_DIR …"
mkdir -p "$INSTALL_DIR"

# Remove a previous install so we get a clean copy (idempotent).
if [[ -d "$INSTALL_APP" ]]; then
  rm -rf "$INSTALL_APP"
fi

# Use cp -R to copy the entire .app bundle.
cp -R "$DIST_APP" "$INSTALL_APP"

echo ""
echo "✔ Installed: $INSTALL_APP"
echo ""
echo "  Launch with:    open \"$INSTALL_APP\""
echo ""
echo "───────────────────────────────────────────────────────────"
echo "  Optional: Launch at Login (manual opt-in)"
echo ""
echo "  To have ShortcutCoach start automatically when you log in:"
echo ""
echo "    1. Open System Settings → General → Login Items"
echo "    2. Click '+' under 'Open at Login'"
echo "    3. Navigate to $INSTALL_APP and add it"
echo ""
echo "  Or via the command line:"
echo ""
echo "    osascript -e 'tell application \"System Events\" to make login item at end with properties {path:\"$INSTALL_APP\", hidden:false}'"
echo "───────────────────────────────────────────────────────────"
