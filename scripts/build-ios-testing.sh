#!/bin/bash
# Shared by Codemagic and the fork's launch checks. No maintainer credentials/hooks.
set -euo pipefail
cd "$(dirname "$0")/.."
sdk="${1:-iphoneos}"
output="${2:-$PWD/build/ios-testing}"
mkdir -p "$output"
case "$sdk" in
    iphoneos) destination='generic/platform=iOS'; signing=(CODE_SIGNING_ALLOWED=NO) ;;
    iphonesimulator) destination='generic/platform=iOS Simulator'; signing=(CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO) ;;
    *) echo "Expected iphoneos or iphonesimulator" >&2; exit 2 ;;
esac
xcodebuild -workspace "$PWD/Monal/Monal.xcworkspace" -scheme 'Monal Alpha' \
    -configuration Alpha -sdk "$sdk" -destination "$destination" \
    -derivedDataPath "$output/DerivedData" ENABLE_DEBUG_DYLIB=NO \
    "${signing[@]}" build > "$output-build.log" 2>&1 || {
    tail -100 "$output-build.log"; exit 1;
}
app="$output/DerivedData/Build/Products/Alpha-$sdk/Monal.alpha.app"
python3 scripts/verify-ios-package.py "$app" --sdk "$sdk"
echo "Built $app"
