#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="${1:-$ROOT_DIR/test-results}"
mkdir -p "$OUTPUT_DIR"

cd "$ROOT_DIR"
swift test --xunit-output "$OUTPUT_DIR/junit.xml" --parallel
