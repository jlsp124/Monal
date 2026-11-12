#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
build="${1:-$PWD/build/ios-testing}"
app="$build/DerivedData/Build/Products/Alpha-iphoneos/Monal.alpha.app"
python3 scripts/verify-ios-package.py "$app" --sdk iphoneos
mkdir -p "$build/ipa"
staging="$(mktemp -d "$build/ipa/staging.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/Payload"
ditto "$app" "$staging/Payload/Monal.alpha.app"
cd "$staging"
/usr/bin/zip -qry -X "$staging/Monal-alpha-unsigned.ipa" Payload
mv "$staging/Monal-alpha-unsigned.ipa" "$build/ipa/Monal-alpha-unsigned.ipa"
echo "Unsigned package: $build/ipa/Monal-alpha-unsigned.ipa"
