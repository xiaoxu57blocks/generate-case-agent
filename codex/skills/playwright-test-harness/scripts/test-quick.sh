#!/bin/bash
# Run a single test quickly without setup/teardown dependencies
# Usage: ./scripts/test-quick.sh <test-file> <test-name-grep> [env]
#   ./scripts/test-quick.sh tests/firmadmin/cases/update_case.spec.ts "check the events color" stg
#   ./scripts/test-quick.sh tests/firmadmin/cases/update_case.spec.ts "check the events color"
#
# env defaults to stg

FILE="$1"
GREP="$2"
ENV="${3:-stg}"

if [ -z "$FILE" ] || [ -z "$GREP" ]; then
  echo "Usage: $0 <test-file> <test-name-grep> [env]"
  echo "  env: stg (default) | prod | ca"
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Running: $GREP"
echo "File:    $FILE"
echo "Env:     $ENV"
echo "---"

TEST_ENV="$ENV" npx playwright test "$FILE" \
  --config=playwright.test-only.config.ts \
  --grep "$GREP" \
  --reporter=line 2>&1 | tail -50
