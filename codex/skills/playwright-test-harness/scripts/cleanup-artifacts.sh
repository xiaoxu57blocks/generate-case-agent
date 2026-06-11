#!/bin/bash
# Clean up temporary artifact files produced by the add-test agent pipeline
# Usage: ./scripts/cleanup-artifacts.sh [case-id]
#   ./scripts/cleanup-artifacts.sh          # remove all /tmp/tc_* artifacts
#   ./scripts/cleanup-artifacts.sh TC-089   # remove only TC-089 artifacts

CASE_ID="${1:-}"

if [ -n "$CASE_ID" ]; then
  # Normalize: "TC-089" -> "tc_089" or "tc_089"
  SLUG=$(echo "$CASE_ID" | tr '[:upper:]' '[:lower:]' | sed 's/-/_/')
  FILES=$(ls /tmp/${SLUG}_*.md 2>/dev/null)
  if [ -z "$FILES" ]; then
    echo "No artifacts found for $CASE_ID (looked for /tmp/${SLUG}_*.md)"
  else
    rm -f /tmp/${SLUG}_*.md
    echo "✅ Removed artifacts for $CASE_ID:"
    echo "$FILES" | sed 's/^/  /'
  fi
else
  FILES=$(ls /tmp/tc_*.md 2>/dev/null)
  if [ -z "$FILES" ]; then
    echo "No pipeline artifacts found in /tmp."
  else
    rm -f /tmp/tc_*.md
    echo "✅ Removed all pipeline artifacts:"
    echo "$FILES" | sed 's/^/  /'
  fi
fi
