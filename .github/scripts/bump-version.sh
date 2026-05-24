#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Print message to stderr
log() {
  echo "$@" >&2
}

# Print error to stderr and exit
error() {
  log "❌ Error: $1"
  exit 1
}

# Helper to map labels to numeric value for hierarchy checks
label_value() {
  case "$1" in
    alpha) echo 1 ;;
    beta)  echo 2 ;;
    rc)    echo 3 ;;
    *)     echo 0 ;;
  esac
}

# 1. Parse inputs
BUMP_TYPE="${1:-}"
PRERELEASE_LABEL="${2:-none}"
LATEST_TAG="${3:-}"

if [ -z "$BUMP_TYPE" ]; then
  error "Bump type (arg 1) is required. Must be 'same', 'major', 'minor', 'patch', 'alpha', 'beta', or 'rc'."
fi

if [[ "$BUMP_TYPE" != "same" && "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "alpha" && "$BUMP_TYPE" != "beta" && "$BUMP_TYPE" != "rc" ]]; then
  error "Invalid bump type '$BUMP_TYPE'. Must be 'same', 'major', 'minor', 'patch', 'alpha', 'beta', or 'rc'."
fi

# 2. Fetch latest tag if not provided
if [ -z "$LATEST_TAG" ]; then
  LATEST_TAG=$(git tag --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)
  if [ -z "$LATEST_TAG" ]; then
    LATEST_TAG="v0.0.0"
  fi
fi

log "Latest tag found: $LATEST_TAG"

# Validate LATEST_TAG format (must start with v)
if [[ ! "$LATEST_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  error "Latest tag '$LATEST_TAG' does not follow version format vMAJOR.MINOR.PATCH[-LABEL.NUM]"
fi

VERSION="${LATEST_TAG#v}"
BASE_VERSION="${VERSION%%-*}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"

# Ensure MAJOR, MINOR, PATCH are integers
if ! [[ "$MAJOR" =~ ^[0-9]+$ && "$MINOR" =~ ^[0-9]+$ && "$PATCH" =~ ^[0-9]+$ ]]; then
  error "Failed to parse major/minor/patch numbers from version '$BASE_VERSION'"
fi

# Check if latest tag is prerelease or stable
IS_PRERELEASE=false
if [[ "$VERSION" == *"-"* ]]; then
  IS_PRERELEASE=true
fi

# Helper to determine target label for a new cycle
get_target_label() {
  local input_label="$1"
  local active_label="$2"
  
  if [[ "$input_label" == "alpha" || "$input_label" == "beta" || "$input_label" == "rc" ]]; then
    echo "$input_label"
  else
    # Any other value (none, ignore, empty, invalid) triggers inheritance / default
    if [ -n "$active_label" ]; then
      echo "$active_label"
    else
      echo "alpha" # Sensible fallback from stable state
    fi
  fi
}

NEXT=""

# 3. Decision Logic Tree

if [ "$IS_PRERELEASE" = "false" ]; then
  # Stable State
  if [[ "$BUMP_TYPE" == "same" || "$BUMP_TYPE" == "alpha" || "$BUMP_TYPE" == "beta" || "$BUMP_TYPE" == "rc" ]]; then
    error "The repository is in a stable state ($LATEST_TAG). You must select 'major', 'minor', or 'patch' to start a new prerelease cycle."
  fi
  
  # Resolve target label
  TARGET_LABEL=$(get_target_label "$PRERELEASE_LABEL" "")

  # Start a brand new prerelease series
  case "$BUMP_TYPE" in
    major)
      MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
      ;;
    minor)
      MINOR=$((MINOR + 1)); PATCH=0
      ;;
    patch)
      PATCH=$((PATCH + 1))
      ;;
  esac
  NEXT="v${MAJOR}.${MINOR}.${PATCH}-${TARGET_LABEL}.1"

else
  # Prerelease State
  SUFFIX="${VERSION#*-}"
  
  if [[ "$SUFFIX" != *.* ]]; then
    error "Invalid prerelease suffix '$SUFFIX'. Expected format LABEL.NUMBER (e.g. beta.1)."
  fi
  
  CURRENT_LABEL="${SUFFIX%%.*}"
  CURRENT_NUM="${SUFFIX#*.}"
  
  if ! [[ "$CURRENT_NUM" =~ ^[0-9]+$ ]]; then
    error "Prerelease number '$CURRENT_NUM' is not a valid integer."
  fi

  if [[ "$BUMP_TYPE" == "major" || "$BUMP_TYPE" == "minor" || "$BUMP_TYPE" == "patch" ]]; then
    # Force a new prerelease track
    TARGET_LABEL=$(get_target_label "$PRERELEASE_LABEL" "$CURRENT_LABEL")

    case "$BUMP_TYPE" in
      major)
        MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
        ;;
      minor)
        MINOR=$((MINOR + 1)); PATCH=0
        ;;
      patch)
        PATCH=$((PATCH + 1))
        ;;
    esac
    NEXT="v${MAJOR}.${MINOR}.${PATCH}-${TARGET_LABEL}.1"

  elif [ "$BUMP_TYPE" = "same" ]; then
    # Standard increment of active number
    NEXT_NUM=$((CURRENT_NUM + 1))
    NEXT="v${BASE_VERSION}-${CURRENT_LABEL}.${NEXT_NUM}"

  else
    # Target label selected directly (alpha, beta, or rc)
    VAL_CURRENT=$(label_value "$CURRENT_LABEL")
    VAL_TARGET=$(label_value "$BUMP_TYPE")

    log "Current label: $CURRENT_LABEL (value: $VAL_CURRENT)"
    log "Target label: $BUMP_TYPE (value: $VAL_TARGET)"

    if [ "$VAL_TARGET" -gt "$VAL_CURRENT" ]; then
      # Promote
      NEXT="v${BASE_VERSION}-${BUMP_TYPE}.1"
    elif [ "$VAL_TARGET" -eq "$VAL_CURRENT" ]; then
      # Target is same as current active -> behaves as "same"
      NEXT_NUM=$((CURRENT_NUM + 1))
      NEXT="v${BASE_VERSION}-${CURRENT_LABEL}.${NEXT_NUM}"
    else
      # Target is lower -> Demotion failure
      error "Cannot demote active prerelease label from '$CURRENT_LABEL' to '$BUMP_TYPE'."
    fi
  fi
fi

# Print final result to stdout
echo "$NEXT"
