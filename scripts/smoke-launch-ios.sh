#!/bin/bash
# Cold launch and relaunch, with process survival and diagnostics as evidence.
set -euo pipefail
cd "$(dirname "$0")/.."
build="${1:-$PWD/build/ios-testing}"
app="$build/DerivedData/Build/Products/Alpha-iphonesimulator/Monal.alpha.app"
mkdir -p "$build/launch"
device="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; devices=json.load(sys.stdin)["devices"]; print(next(d["udid"] for group in devices.values() for d in group if d["name"] == "iPhone 16"))')"
xcrun simctl boot "$device" || true
xcrun simctl bootstatus "$device" -b
xcrun simctl install "$device" "$app"
for attempt in cold relaunch; do
    launch="$(xcrun simctl launch --terminate-running-process "$device" monal.alpha)"
    echo "$launch" | tee "$build/launch/$attempt.txt"
    pid="${launch##*: }"
    [[ "$pid" =~ ^[0-9]+$ ]]
    for second in {1..20}; do
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
            xcrun simctl spawn "$device" log show --last 3m --style compact --predicate 'process == "Monal.alpha"' > "$build/launch/runtime.log" || true
            echo "Monal exited during $attempt (PID $pid)" >&2
            exit 1
        fi
    done
    xcrun simctl io "$device" screenshot "$build/launch/$attempt.png"
done
xcrun simctl spawn "$device" log show --last 5m --style compact --predicate 'process == "Monal.alpha"' > "$build/launch/runtime.log" || true
echo 'Both simulator launches survived 20 seconds.' | tee "$build/launch/result.txt"
