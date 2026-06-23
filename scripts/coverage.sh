#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="${1:-$ROOT_DIR/coverage-results}"
mkdir -p "$OUTPUT_DIR"

cd "$ROOT_DIR"
swift test --enable-code-coverage --parallel

BIN_DIR=$(swift build --show-bin-path)
PROFILE_PATH=$(find "$ROOT_DIR/.build" -name "default.profdata" -path "*/codecov/*" | head -1)

if [[ -z "$PROFILE_PATH" ]]; then
  echo "Error: Could not find profdata file. Ensure code coverage was generated."
  exit 1
fi

BINARY_PATH="${BIN_DIR}/TwilioVerifySNAPackageTests.xctest"

# macOS bundles the binary inside .xctest
if [[ -d "$BINARY_PATH" ]]; then
  BINARY_PATH="${BINARY_PATH}/Contents/MacOS/TwilioVerifySNAPackageTests"
fi

xcrun llvm-cov export \
  "$BINARY_PATH" \
  -instr-profile="$PROFILE_PATH" \
  -format=lcov \
  -ignore-filename-regex='Tests/|\.build/' \
  > "$OUTPUT_DIR/coverage.lcov"

# Generate coverage summary
COVERAGE=$(awk -F'[:,]' '/^SF/{file=$2} /^DA/{key=file":"$2; if($3>hits[key]) hits[key]=$3; lines[key]=1} END{for(k in lines){total++; if(hits[k]>0) hit++} printf "%.1f%%\n",(hit/total)*100}' "$OUTPUT_DIR/coverage.lcov")
echo "Line Coverage: $COVERAGE" > "$OUTPUT_DIR/coverage.txt"

echo "Coverage report: $OUTPUT_DIR/coverage.lcov"
echo "Line Coverage: $COVERAGE"
