#!/bin/bash
set -e

APP_NAME="MenuProgress"
BUNDLE_ID="Salmonization.MenuProgress"
APP_VERSION="1.0.0"
BUILD_VERSION="1"

APP_BUNDLE="${APP_NAME}.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
INFO_PLIST="${APP_BUNDLE}/Contents/Info.plist"

echo "=> Cleaning up..."
rm -rf "${APP_BUNDLE}"
echo "=> Creating .app directory structure..."
mkdir -p "${MACOS_DIR}"

# 1. Compile for Apple Silicon
echo "=> Compiling for Apple Silicon (arm64)..."
swiftc -O main.swift -target arm64-apple-macos11 -o "${APP_NAME}_arm64"

# 2. Compile for Intel Mac
echo "=> Compiling for Intel (x86_64)..."
swiftc -O main.swift -target x86_64-apple-macos10.15 -o "${APP_NAME}_x86_64"

# 3. Merge into a Universal Binary
echo "=> Creating Universal Binary..."
lipo -create -output "${MACOS_DIR}/${APP_NAME}" "${APP_NAME}_arm64" "${APP_NAME}_x86_64"
rm "${APP_NAME}_arm64" "${APP_NAME}_x86_64"

# 4. Generate Info.plist
echo "=> Generating Info.plist..."
cat <<EOF > "${INFO_PLIST}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "=> Build complete: ${APP_BUNDLE}"
