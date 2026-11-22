#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
swift build -c release
app=".build/Tuneleaf.app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/Tuneleaf "$app/Contents/MacOS/Tuneleaf"
cp Info.plist "$app/Contents/Info.plist"
codesign --force --sign - "$app"
echo "Built $PWD/$app"
