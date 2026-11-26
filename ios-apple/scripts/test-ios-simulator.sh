#!/usr/bin/env bash
set -euo pipefail
: "${CM_BUILD_DIR:?Codemagic CM_BUILD_DIR must be defined}"
APP="$CM_BUILD_DIR/ios-apple/ios/DerivedData/Build/Products/Debug-iphonesimulator/App.app"
if [ ! -d "$APP" ]; then
  echo "ERROR: Simulator App.app not found at $APP" >&2
  exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
[ "$BUNDLE_ID" = 'com.rizedijital.app' ] || { echo "Unexpected bundle ID: $BUNDLE_ID" >&2; exit 1; }
# Available simulator runtimes / models vary with the Codemagic Xcode image.
SIM_ID="$(xcrun simctl list -j devices available | python3 -c 'import sys,json; d=json.load(sys.stdin)["devices"]; print(next((v["udid"] for xs in d.values() for v in xs if v.get("isAvailable",True) and "iPhone" in v.get("name", "")), ""))')"
if [ -z "$SIM_ID" ]; then
  TYPE_ID="$(xcrun simctl list -j devicetypes | python3 -c 'import sys,json; v=json.load(sys.stdin)["devicetypes"]; print(next((x["identifier"] for x in v if "iPhone" in x.get("name", "")), ""))')"
  RUNTIME_ID="$(xcrun simctl list -j runtimes | python3 -c 'import sys,json; v=json.load(sys.stdin)["runtimes"]; print(next((x["identifier"] for x in reversed(v) if x.get("isAvailable",True) and x.get("platform", "iOS") == "iOS"), ""))')"
  [ -n "$TYPE_ID" ] && [ -n "$RUNTIME_ID" ] || { echo 'No usable iOS simulator runtime/device type installed' >&2; exit 1; }
  SIM_ID="$(xcrun simctl create rizedijital-ci-test "$TYPE_ID" "$RUNTIME_ID")"
fi
echo "Using simulator: $SIM_ID"
STATE="$(xcrun simctl list -j devices available | python3 -c 'import sys,json; u=sys.argv[1]; d=json.load(sys.stdin)["devices"]; print(next((v.get("state", "") for xs in d.values() for v in xs if v.get("udid")==u), ""))' "$SIM_ID")"
if [ "$STATE" != 'Booted' ]; then xcrun simctl boot "$SIM_ID"; fi
xcrun simctl bootstatus "$SIM_ID" -b
xcrun simctl install "$SIM_ID" "$APP"
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"
sleep 8
xcrun simctl io "$SIM_ID" screenshot "$CM_BUILD_DIR/ios-preview.png"
