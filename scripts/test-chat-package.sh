#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../Packages/ExyteChat"
root="$(cd ../.. && pwd)"
device="$(python3 "$root/scripts/prepare-ios-simulator.py")"
xcodebuild -list -json > "$root/build/chat-schemes.json"
scheme="$(python3 - "$root/build/chat-schemes.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
schemes=(data.get('workspace') or data.get('project') or {}).get('schemes', [])
for candidate in ('ExyteChat', 'Chat', 'Chat-Package'):
    if candidate in schemes:
        print(candidate)
        break
else:
    raise SystemExit(f'No chat package test scheme in {schemes}')
PY
)"
xcodebuild -scheme "$scheme" -destination "platform=iOS Simulator,id=$device" \
    -derivedDataPath "$root/build/chat-tests" \
    -resultBundlePath "$root/build/chat-results.xcresult" test > "$root/build/chat-tests.log" 2>&1 || {
    sed -n '/error:/p' "$root/build/chat-tests.log"
    tail -130 "$root/build/chat-tests.log"; exit 1;
}
tail -45 "$root/build/chat-tests.log"
xcrun xcresulttool export attachments --path "$root/build/chat-results.xcresult" --output-path "$root/build/chat-screenshots"
