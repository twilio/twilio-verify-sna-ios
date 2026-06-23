#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TEAM_ID="${TEAM_ID:?Set TEAM_ID environment variable}"
BUNDLE_ID="${BUNDLE_ID:-com.twilio.TwilioVerifySNADemo}"

WORKSPACE="$ROOT_DIR/TwilioVerifySNA.xcworkspace"
OUTPUT_DIR="$ROOT_DIR/IPAs"
EXTRACT_DIR="$ROOT_DIR/extracted"
SIZES_FILE="$ROOT_DIR/sizes.txt"
ARCHIVE_PATH="$ROOT_DIR/build/archive.xcarchive"
EXPORT_OPTIONS="$ROOT_DIR/build/ExportOptions.plist"

rm -rf "$OUTPUT_DIR" "$EXTRACT_DIR" "$SIZES_FILE"
mkdir -p "$OUTPUT_DIR" "$(dirname "$EXPORT_OPTIONS")"

# Generate ExportOptions.plist
cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>match Development ${BUNDLE_ID}</string>
    </dict>
</dict>
</plist>
EOF

build_ipa() {
  local scheme="$1"
  local output_name="$2"
  local export_tmp="$ROOT_DIR/build/export_tmp"

  rm -rf "$export_tmp"
  mkdir -p "$export_tmp"

  echo "==> Archiving $scheme..."
  xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$scheme" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_STYLE="Manual" \
    -quiet

  echo "==> Exporting $scheme..."
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$export_tmp" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -quiet

  # Move exported IPA to final location
  local exported_ipa
  exported_ipa=$(find "$export_tmp" -name "*.ipa" -maxdepth 1 | head -1)
  mv "$exported_ipa" "$OUTPUT_DIR/$output_name"

  rm -rf "$ARCHIVE_PATH" "$export_tmp"
}

# Build with SDK
build_ipa "TwilioVerifySNADemo" "TwilioVerifySNADemo.ipa"

# Build without SDK (baseline)
build_ipa "TwilioVerifySNADemoNoSDK" "TwilioVerifySNADemoNoSDK.ipa"

# Measure IPA sizes
ipa_size_kb=$(du -sk "$OUTPUT_DIR/TwilioVerifySNADemo.ipa" | cut -f1)
ipa_size_mb=$(echo "scale=1; $ipa_size_kb / 1024" | bc)
echo "IPA size: ${ipa_size_mb} MB"
echo "IPA size: ${ipa_size_mb} MB" > "$SIZES_FILE"

ipa_no_sdk_size_kb=$(du -sk "$OUTPUT_DIR/TwilioVerifySNADemoNoSDK.ipa" | cut -f1)
ipa_no_sdk_size_mb=$(echo "scale=1; $ipa_no_sdk_size_kb / 1024" | bc)
echo "IPA without SDK size: ${ipa_no_sdk_size_mb} MB"
echo "IPA without SDK size: ${ipa_no_sdk_size_mb} MB" >> "$SIZES_FILE"

sdk_impact_kb=$((ipa_size_kb - ipa_no_sdk_size_kb))
sdk_impact_mb=$(printf "%.1f" "$(echo "scale=2; $sdk_impact_kb / 1024" | bc)")
echo "SDK size impact: ${sdk_impact_mb} MB"
echo "SDK size impact: ${sdk_impact_mb} MB" >> "$SIZES_FILE"

# Extract and measure frameworks
unzip -q "$OUTPUT_DIR/TwilioVerifySNADemo.ipa" -d "$EXTRACT_DIR"

app_size_kb=$(du -sk "$EXTRACT_DIR/Payload/TwilioVerifySNADemo.app" | cut -f1)
app_size_mb=$(echo "scale=1; $app_size_kb / 1024" | bc)
echo "App size: ${app_size_mb} MB"
echo "App size: ${app_size_mb} MB" >> "$SIZES_FILE"

for framework in "$EXTRACT_DIR/Payload/TwilioVerifySNADemo.app/Frameworks/"*.framework; do
  [ -d "$framework" ] || continue
  fw_name=$(basename "$framework")
  fw_size_kb=$(du -sk "$framework" | cut -f1)
  fw_size_mb=$(echo "scale=1; $fw_size_kb / 1024" | bc)
  impact=$(echo "scale=1; ($fw_size_kb * 100) / $app_size_kb" | bc)
  echo "${fw_name}: ${fw_size_mb} MB, Impact: ${impact}%"
  echo "${fw_name}: ${fw_size_mb} MB, Impact: ${impact}%" >> "$SIZES_FILE"
done

echo ""
echo "Results written to $SIZES_FILE"

# Cleanup
rm -rf "$EXTRACT_DIR" "$ROOT_DIR/build"
