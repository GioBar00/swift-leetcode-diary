#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUMP_SCRIPT="${SCRIPT_DIR}/bump-version.sh"

if [ ! -f "$BUMP_SCRIPT" ]; then
  echo "❌ Error: bump-version.sh not found at $BUMP_SCRIPT"
  exit 1
fi

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ANSI colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper to run a test case
# Parameters:
# 1: test_name
# 2: bump_type
# 3: prerelease_label
# 4: latest_tag
# 5: expected_exit_code
# 6: expected_output_substring
run_test() {
  local name="$1"
  local bump_type="$2"
  local label="$3"
  local tag="$4"
  local exp_code="$5"
  local exp_out="$6"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -n "Test $((TOTAL_TESTS)): $name... "

  local out_file
  local err_file
  out_file=$(mktemp)
  err_file=$(mktemp)
  
  local exit_code=0
  "$BUMP_SCRIPT" "$bump_type" "$label" "$tag" > "$out_file" 2> "$err_file" || exit_code=$?

  local actual_out
  local actual_err
  actual_out=$(cat "$out_file")
  actual_err=$(cat "$err_file")
  
  rm -f "$out_file" "$err_file"

  # Validate exit code
  if [ "$exit_code" -ne "$exp_code" ]; then
    echo -e "${RED}FAIL${NC}"
    echo "  Expected exit code $exp_code, got $exit_code"
    echo "  Stdout: $actual_out"
    echo "  Stderr: $actual_err"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return 1
  fi

  # Validate output
  if [ "$exit_code" -eq 0 ]; then
    if [ "$actual_out" != "$exp_out" ]; then
      echo -e "${RED}FAIL${NC}"
      echo "  Expected output: '$exp_out'"
      echo "  Got output:      '$actual_out'"
      echo "  Stderr: $actual_err"
      FAILED_TESTS=$((FAILED_TESTS + 1))
      return 1
    fi
  else
    if [[ "$actual_err" != *"$exp_out"* ]]; then
      echo -e "${RED}FAIL${NC}"
      echo "  Expected error substring: '$exp_out'"
      echo "  Got error message:        '$actual_err'"
      FAILED_TESTS=$((FAILED_TESTS + 1))
      return 1
    fi
  fi

  echo -e "${GREEN}PASS${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
  return 0
}

echo "=================================================="
echo "Running Unified Bump Version Test Suite"
echo "=================================================="

# --- Happy Paths (Stable States) ---

run_test \
  "Stable state: minor bump with explicit alpha label" \
  "minor" "alpha" "v1.2.3" \
  0 "v1.3.0-alpha.1"

run_test \
  "Stable state: major bump with explicit beta label" \
  "major" "beta" "v1.2.3" \
  0 "v2.0.0-beta.1"

run_test \
  "Stable state: patch bump with explicit rc label" \
  "patch" "rc" "v1.2.3" \
  0 "v1.2.4-rc.1"

run_test \
  "Stable state: minor bump with 'none' label (defaults to alpha)" \
  "minor" "none" "v1.2.3" \
  0 "v1.3.0-alpha.1"

# --- Happy Paths (Prerelease States - Increments & Promotions) ---

run_test \
  "Prerelease state: same (increments active alpha)" \
  "same" "none" "v1.3.0-alpha.1" \
  0 "v1.3.0-alpha.2"

run_test \
  "Prerelease state: target == active label alpha (smart increment)" \
  "alpha" "none" "v1.3.0-alpha.1" \
  0 "v1.3.0-alpha.2"

run_test \
  "Prerelease state: promote alpha to beta" \
  "beta" "none" "v1.3.0-alpha.1" \
  0 "v1.3.0-beta.1"

run_test \
  "Prerelease state: promote beta to rc" \
  "rc" "none" "v1.3.0-beta.1" \
  0 "v1.3.0-rc.1"

run_test \
  "Prerelease state: target == active label rc (smart increment)" \
  "rc" "none" "v1.3.0-rc.1" \
  0 "v1.3.0-rc.2"

# --- Happy Paths (Prerelease States - Forcing New Cycle) ---

run_test \
  "Prerelease state: force new minor track with explicit alpha" \
  "minor" "alpha" "v1.3.0-alpha.2" \
  0 "v1.4.0-alpha.1"

run_test \
  "Prerelease state: force new minor track inheriting active label (none)" \
  "minor" "none" "v1.3.0-beta.2" \
  0 "v1.4.0-beta.1"

run_test \
  "Prerelease state: force new major track with explicit beta" \
  "major" "beta" "v1.3.0-alpha.2" \
  0 "v2.0.0-beta.1"

run_test \
  "Prerelease state: force new patch track with explicit rc" \
  "patch" "rc" "v1.3.0-alpha.2" \
  0 "v1.3.1-rc.1"

# --- Negative Paths (Stable States - Forbidden Operations) ---

run_test \
  "Stable state: bump type 'same' (should fail)" \
  "same" "alpha" "v1.2.3" \
  1 "You must select 'major', 'minor', or 'patch' to start a new prerelease cycle"

run_test \
  "Stable state: direct label target alpha (should fail)" \
  "alpha" "alpha" "v1.2.3" \
  1 "You must select 'major', 'minor', or 'patch' to start a new prerelease cycle"

run_test \
  "Stable state: direct label target beta (should fail)" \
  "beta" "alpha" "v1.2.3" \
  1 "You must select 'major', 'minor', or 'patch' to start a new prerelease cycle"

run_test \
  "Stable state: direct label target rc (should fail)" \
  "rc" "alpha" "v1.2.3" \
  1 "You must select 'major', 'minor', or 'patch' to start a new prerelease cycle"

# --- Negative Paths (Prerelease States - Invalid Demotions) ---

run_test \
  "Prerelease state: demote beta to alpha (should fail)" \
  "alpha" "alpha" "v1.3.0-beta.1" \
  1 "Cannot demote active prerelease label from 'beta' to 'alpha'"

run_test \
  "Prerelease state: demote rc to beta (should fail)" \
  "beta" "alpha" "v1.3.0-rc.1" \
  1 "Cannot demote active prerelease label from 'rc' to 'beta'"

run_test \
  "Prerelease state: demote rc to alpha (should fail)" \
  "alpha" "alpha" "v1.3.0-rc.1" \
  1 "Cannot demote active prerelease label from 'rc' to 'alpha'"

# --- Validation Errors ---

run_test \
  "Validation: missing bump type" \
  "" "" "v1.2.3" \
  1 "Bump type (arg 1) is required"

run_test \
  "Validation: invalid bump type" \
  "invalid_bump" "alpha" "v1.2.3" \
  1 "Invalid bump type 'invalid_bump'"

run_test \
  "Validation: unknown/ignored target label behaves as none (falls back to alpha on stable)" \
  "minor" "ignore" "v1.2.3" \
  0 "v1.3.0-alpha.1"

run_test \
  "Validation: unknown/ignored target label inherits active label on prerelease" \
  "minor" "ignore" "v1.3.0-beta.1" \
  0 "v1.4.0-beta.1"

echo "=================================================="
if [ "$FAILED_TESTS" -eq 0 ]; then
  echo -e "${GREEN}🎉 All $TOTAL_TESTS tests passed successfully!${NC}"
  exit 0
else
  echo -e "${RED}❌ $FAILED_TESTS of $TOTAL_TESTS tests failed.${NC}"
  exit 1
fi
