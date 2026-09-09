#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SCHEME="${SCHEME:-TwilioVerifySNA}"

xcodebuild clean build \
  -workspace "$ROOT_DIR/TwilioVerifySNA.xcworkspace" \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | xcpretty

exit ${PIPESTATUS[0]}
