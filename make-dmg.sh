#!/bin/zsh
# Builds a universal (Apple Silicon + Intel) Release build and packages it as a
# drag-to-Applications DMG in ./dist — ready to attach to a GitHub Release.
#
# Optional environment variables:
#   VERSION           Version string (default: MARKETING_VERSION from the project)
#   DEVELOPER_ID      e.g. "Developer ID Application: Your Name (TEAMID)"  → signs for distribution
#   NOTARY_PROFILE    notarytool keychain profile name → notarizes + staples the DMG
#                     (create once: xcrun notarytool store-credentials <name> --apple-id … --team-id …)
# Without DEVELOPER_ID the app is ad-hoc signed; users must allow it once in
# System Settings → Privacy & Security (see README).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="MarkdownViewer"
VOL_NAME="Markdown Viewer"
# Build outside the (possibly iCloud-synced) project folder: file-provider xattrs break code signing.
BUILD_DIR="${BUILD_DIR:-$HOME/Library/Developer/Xcode/DerivedData/MarkdownViewer-dist}"
DIST_DIR="$PWD/dist"

build_args=(
  -project MarkdownViewer.xcodeproj -scheme "$APP_NAME" -configuration Release
  -destination "generic/platform=macOS"
  -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$BUILD_DIR/spm"
)
[[ -n "${VERSION:-}" ]] && build_args+=(MARKETING_VERSION="$VERSION")
if [[ -n "${DEVELOPER_ID:-}" ]]; then
  build_args+=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$DEVELOPER_ID" OTHER_CODE_SIGN_FLAGS="--timestamp")
fi

echo "==> Building…"
rm -rf "$BUILD_DIR/Build/Products"
xcodebuild "${build_args[@]}" build -quiet

APP="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
VERSION="$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)"
DMG="$DIST_DIR/$APP_NAME-$VERSION.dmg"
echo "==> Built $APP_NAME $VERSION ($(lipo -archs "$APP/Contents/MacOS/$APP_NAME"))"

# Keep Launch Services pointing at /Applications, not this build copy.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -u "$APP" 2>/dev/null || true

echo "==> Creating DMG…"
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto "$APP" "$STAGING/$APP_NAME.app"
rm -rf "$APP"   # don't leave a second copy around for Spotlight / "Open With"
ln -s /Applications "$STAGING/Applications"
mkdir -p "$DIST_DIR"
rm -f "$DMG"
hdiutil create -volname "$VOL_NAME" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null

if [[ -n "${DEVELOPER_ID:-}" ]]; then
  echo "==> Signing DMG…"
  codesign --force --timestamp --sign "$DEVELOPER_ID" "$DMG"
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "==> Notarizing (this can take a few minutes)…"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
  fi
fi

(cd "$DIST_DIR" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "==> Done: $DMG"
