#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUMP_SCRIPT="${SCRIPT_DIR}/bump-version.sh"

[ -f "$BUMP_SCRIPT" ] || { echo "❌ Error: bump-version.sh not found at $BUMP_SCRIPT"; exit 1; }

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ── Assertion core ────────────────────────────────────────────────────────────
# _assert NAME EXP_CODE EXP_OUT ACTUAL_CODE ACTUAL_OUT ACTUAL_ERR
_assert() {
  local name="$1" exp_code="$2" exp_out="$3" exit_code="$4" actual_out="$5" actual_err="$6"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  echo -n "Test $TOTAL_TESTS: $name... "

  if [ "$exit_code" -ne "$exp_code" ]; then
    echo -e "${RED}FAIL${NC} (expected exit $exp_code, got $exit_code)"
    echo "  Stdout: $actual_out"
    echo "  Stderr: $actual_err"
    FAILED_TESTS=$((FAILED_TESTS + 1)); return 0
  fi

  if [ "$exit_code" -eq 0 ]; then
    if [ "$actual_out" != "$exp_out" ]; then
      echo -e "${RED}FAIL${NC}"
      echo "  Expected: '$exp_out'"
      echo "  Got:      '$actual_out'"
      FAILED_TESTS=$((FAILED_TESTS + 1)); return 0
    fi
  elif [[ "$actual_err" != *"$exp_out"* ]]; then
    echo -e "${RED}FAIL${NC}"
    echo "  Expected error containing: '$exp_out'"
    echo "  Got: '$actual_err'"
    FAILED_TESTS=$((FAILED_TESTS + 1)); return 0
  fi

  echo -e "${GREEN}PASS${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
}

# run_test NAME BUMP_TYPE LABEL TAG EXP_CODE EXP_OUT
# Passes LATEST_TAG explicitly — no git context needed.
run_test() {
  local name="$1" bump_type="$2" label="$3" tag="$4" exp_code="$5" exp_out="$6"
  local tmp; tmp=$(mktemp)
  local actual_out="" exit_code=0
  actual_out=$("$BUMP_SCRIPT" "$bump_type" "$label" "$tag" 2>"$tmp") || exit_code=$?
  local actual_err; actual_err=$(cat "$tmp"); rm -f "$tmp"
  _assert "$name" "$exp_code" "$exp_out" "$exit_code" "$actual_out" "$actual_err"
}

# run_git_test NAME BUMP_TYPE LABEL EXP_CODE EXP_OUT TAG [TAG...]
# Spins up an isolated sandbox git repo, creates the given tags, then runs the script
# without an explicit tag so it resolves the latest via git.
run_git_test() {
  local name="$1" bump_type="$2" label="$3" exp_code="$4" exp_out="$5"
  shift 5

  local sandbox; sandbox=$(mktemp -d)
  git -C "$sandbox" init -q
  git -C "$sandbox" config user.name "test"
  git -C "$sandbox" config user.email "test@test.com"
  touch "$sandbox/file" && git -C "$sandbox" add file && git -C "$sandbox" commit -m "init" -q
  for tag in "$@"; do git -C "$sandbox" tag "$tag"; done

  local actual_out="" exit_code=0
  actual_out=$(cd "$sandbox" && "$BUMP_SCRIPT" "$bump_type" "$label" "" 2>"$sandbox/err") || exit_code=$?
  local actual_err; actual_err=$(cat "$sandbox/err")
  rm -rf "$sandbox"

  _assert "$name" "$exp_code" "$exp_out" "$exit_code" "$actual_out" "$actual_err"
}

# ── Tests ─────────────────────────────────────────────────────────────────────

echo "=================================================="
echo "Running Unified Bump Version Test Suite"
echo "=================================================="

# --- Happy Paths (Stable States) ---

run_test "Stable: minor + explicit alpha"      "minor" "alpha" "v1.2.3"         0 "v1.3.0-alpha.1"
run_test "Stable: major + explicit beta"       "major" "beta"  "v1.2.3"         0 "v2.0.0-beta.1"
run_test "Stable: patch + explicit rc"         "patch" "rc"    "v1.2.3"         0 "v1.2.4-rc.1"
run_test "Stable: minor + none (→ alpha)"      "minor" "none"  "v1.2.3"         0 "v1.3.0-alpha.1"

# --- Happy Paths (Prerelease - Increment & Promote) ---

run_test "Prerelease: same → increment alpha"  "same"  "none"  "v1.3.0-alpha.1" 0 "v1.3.0-alpha.2"
run_test "Prerelease: alpha on alpha → incr"   "alpha" "none"  "v1.3.0-alpha.1" 0 "v1.3.0-alpha.2"
run_test "Prerelease: promote alpha → beta"    "beta"  "none"  "v1.3.0-alpha.1" 0 "v1.3.0-beta.1"
run_test "Prerelease: promote beta → rc"       "rc"    "none"  "v1.3.0-beta.1"  0 "v1.3.0-rc.1"
run_test "Prerelease: rc on rc → increment"    "rc"    "none"  "v1.3.0-rc.1"    0 "v1.3.0-rc.2"

# --- Happy Paths (Prerelease - Forcing New Cycle) ---

run_test "Prerelease: minor + explicit alpha"  "minor" "alpha" "v1.3.0-alpha.2" 0 "v1.4.0-alpha.1"
run_test "Prerelease: minor + none (inherit)"  "minor" "none"  "v1.3.0-beta.2"  0 "v1.4.0-beta.1"
run_test "Prerelease: major + explicit beta"   "major" "beta"  "v1.3.0-alpha.2" 0 "v2.0.0-beta.1"
run_test "Prerelease: patch + explicit rc"     "patch" "rc"    "v1.3.0-alpha.2" 0 "v1.3.1-rc.1"

# --- Negative Paths (Stable - Forbidden) ---

run_test "Stable: same → fail"   "same"  "alpha" "v1.2.3" 1 "You must select 'major', 'minor', or 'patch'"
run_test "Stable: alpha → fail"  "alpha" "alpha" "v1.2.3" 1 "You must select 'major', 'minor', or 'patch'"
run_test "Stable: beta → fail"   "beta"  "alpha" "v1.2.3" 1 "You must select 'major', 'minor', or 'patch'"
run_test "Stable: rc → fail"     "rc"    "alpha" "v1.2.3" 1 "You must select 'major', 'minor', or 'patch'"

# --- Negative Paths (Prerelease - Demotions) ---

run_test "Prerelease: demote beta → alpha" "alpha" "alpha" "v1.3.0-beta.1" 1 "Cannot demote active prerelease label from 'beta' to 'alpha'"
run_test "Prerelease: demote rc → beta"    "beta"  "alpha" "v1.3.0-rc.1"   1 "Cannot demote active prerelease label from 'rc' to 'beta'"
run_test "Prerelease: demote rc → alpha"   "alpha" "alpha" "v1.3.0-rc.1"   1 "Cannot demote active prerelease label from 'rc' to 'alpha'"

# --- Validation Errors ---

run_test "Validation: missing bump type"   ""             "" "v1.2.3" 1 "Bump type (arg 1) is required"
run_test "Validation: invalid bump type"   "invalid_bump" "" "v1.2.3" 1 "Invalid bump type 'invalid_bump'"
run_test "Validation: unknown label → alpha fallback"   "minor" "ignore" "v1.2.3"       0 "v1.3.0-alpha.1"
run_test "Validation: unknown label → inherit on prerelease" "minor" "ignore" "v1.3.0-beta.1" 0 "v1.4.0-beta.1"

# --- Sandboxed Git Integration (tag resolution correctness) ---

run_git_test \
  "Git: stable v1.0.0 wins over its own prerelease v1.0.0-rc.1" \
  "same" "none" 1 "stable state (v1.0.0)" \
  "v1.0.0-rc.1" "v1.0.0"

run_git_test \
  "Git: newer prerelease v1.0.1-rc.1 wins over older stable v1.0.0" \
  "same" "none" 0 "v1.0.1-rc.2" \
  "v1.0.0" "v1.0.1-rc.1"

echo "=================================================="
if [ "$FAILED_TESTS" -eq 0 ]; then
  echo -e "${GREEN}🎉 All $TOTAL_TESTS tests passed successfully!${NC}"
  exit 0
else
  echo -e "${RED}❌ $FAILED_TESTS of $TOTAL_TESTS tests failed.${NC}"
  exit 1
fi
