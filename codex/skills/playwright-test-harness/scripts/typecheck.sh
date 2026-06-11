#!/bin/bash
# TypeScript compile check — no test execution, just type errors
# Usage: ./scripts/typecheck.sh [file-pattern]
#   ./scripts/typecheck.sh                         # check entire project
#   ./scripts/typecheck.sh tests/firmadmin/cases   # check specific directory

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

if [ -n "$1" ]; then
  # Check specific files using ts-node's transpile to catch type errors
  echo "Checking: $1"
  npx tsc --noEmit --project tsconfig.json 2>&1 | grep -E "($1.*error TS|error TS)" | head -50
  EXIT_CODE=${PIPESTATUS[0]}
else
  echo "Checking entire project..."
  ERRORS=$(npx tsc --noEmit --project tsconfig.json 2>&1 | grep "error TS")
  if [ -z "$ERRORS" ]; then
    echo "✅ No TypeScript errors found."
  else
    echo "❌ TypeScript errors:"
    echo "$ERRORS"
    exit 1
  fi
fi
