#!/bin/zsh
# Builds Markdown Viewer (Release), installs it to /Applications and registers it for .md files.
set -euo pipefail
cd "$(dirname "$0")"
# Build outside the (iCloud-synced) Desktop: file-provider xattrs break code signing.
BUILD_DIR="$HOME/Library/Developer/Xcode/DerivedData/MarkdownViewer-local"

xcodebuild -project MarkdownViewer.xcodeproj -scheme MarkdownViewer -configuration Release \
  -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$BUILD_DIR/spm" build -quiet

APP="/Applications/MarkdownViewer.app"
pkill -x MarkdownViewer 2>/dev/null || true
rm -rf "$APP"
cp -R "$BUILD_DIR"/Build/Products/Release/MarkdownViewer.app "$APP"

LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREGISTER" -u "$BUILD_DIR/Build/Products/Release/MarkdownViewer.app" 2>/dev/null || true
"$LSREGISTER" -f "$APP"

# Make it the default app for Markdown files.
swift - <<'SWIFT'
import AppKit
import UniformTypeIdentifiers
let app = URL(fileURLWithPath: "/Applications/MarkdownViewer.app")
let sem = DispatchSemaphore(value: 0)
var types = [UTType(importedAs: "net.daringfireball.markdown")]
if let md = UTType(filenameExtension: "md"), !types.contains(md) { types.append(md) }
for t in types {
  NSWorkspace.shared.setDefaultApplication(at: app, toOpen: t) { err in
    print(err.map { "\(t.identifier): failed – \($0.localizedDescription)" } ?? "\(t.identifier): default set")
    sem.signal()
  }
  sem.wait()
}
SWIFT
echo "Installed: $APP"
