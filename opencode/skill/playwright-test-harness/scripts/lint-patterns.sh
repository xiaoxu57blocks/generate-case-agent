#!/bin/bash
# Check for forbidden coding patterns in pages/ and tests/
# Usage: ./scripts/lint-patterns.sh [path]
#   ./scripts/lint-patterns.sh              # scan pages/ and tests/
#   ./scripts/lint-patterns.sh pages/firmadmin/timeline.ts

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

TARGET="${1:-.}"
VIOLATIONS=0

check() {
  local label="$1"
  local pattern="$2"
  local path="$3"
  local exclude="$4"

  if [ -n "$exclude" ]; then
    MATCHES=$(grep -rn --include="*.ts" "$pattern" "$path" | grep -v "$exclude" | grep -v "//.*$pattern")
  else
    MATCHES=$(grep -rn --include="*.ts" "$pattern" "$path" | grep -v "//.*$pattern")
  fi

  if [ -n "$MATCHES" ]; then
    echo "❌ [$label]"
    echo "$MATCHES"
    echo ""
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
}

echo "Scanning: $TARGET"
echo "---"

# Forbidden: isVisible() used to gate interactions (allow .catch(() => false) pattern)
check "isVisible() gate" "isVisible()" "$TARGET" "catch"

# Forbidden: element-level timeouts
check "element timeout" "\.click({ timeout:" "$TARGET"
check "expect timeout"  "toBeVisible({ timeout:" "$TARGET"
check "waitFor timeout" "\.waitFor({ .*timeout:" "$TARGET"

# Forbidden: test.skip() for missing elements
check "test.skip()" "test\.skip()" "$TARGET"

# Forbidden: asserting on toast text (transient)
check "toast assertion" "successfully\!" "$TARGET"

# Warning: inline locators in test body (heuristic: page.locator inside test(
# (hard to detect reliably, skip for now)

echo "---"
if [ "$VIOLATIONS" -eq 0 ]; then
  echo "✅ No forbidden patterns found."
else
  echo "❌ $VIOLATIONS forbidden pattern(s) found."
  exit 1
fi
