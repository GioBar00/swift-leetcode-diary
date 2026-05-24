#!/usr/bin/env bash
set -euo pipefail

# ── Helpers ──────────────────────────────────────────────────────────────────

err() { echo "❌ Error: $1" >&2; exit 1; }
log() { echo "$@" >&2; }

# Maps a prerelease label to a numeric rank.
# Stable (no label) is handled externally as rank 4 — higher than rc=3.
label_rank() {
  case "$1" in
    alpha) echo 1 ;; beta) echo 2 ;; rc) echo 3 ;; *) echo 0 ;;
  esac
}

# Outputs a zero-padded sort key for a semver tag, suitable for string comparison.
# Stable releases rank higher than any prerelease at the same base (4 > rc=3).
semver_key() {
  local tag="${1#v}"
  local base="${tag%%-*}"
  local suffix=""
  [[ "$tag" == *-* ]] && suffix="${tag#*-}"

  local maj min pat lrank num
  IFS='.' read -r maj min pat <<< "$base"

  if [ -z "$suffix" ]; then
    lrank=4; num=0
  else
    lrank=$(label_rank "${suffix%%.*}")
    num="${suffix#*.}"
  fi

  printf "%010d%010d%010d%02d%010d" "$maj" "$min" "$pat" "$lrank" "$num"
}

# Bumps MAJOR/MINOR/PATCH globals in-place.
bump_base() {
  case "$1" in
    major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
    minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
    patch) PATCH=$((PATCH + 1)) ;;
  esac
}

# Returns the resolved label for a new cycle:
# explicit alpha/beta/rc → use it; anything else → inherit active or default to alpha.
resolve_label() {
  case "$1" in
    alpha|beta|rc) echo "$1" ;;
    *) [ -n "$2" ] && echo "$2" || echo "alpha" ;;
  esac
}

# ── Inputs ───────────────────────────────────────────────────────────────────

BUMP_TYPE="${1:-}"
PRERELEASE_LABEL="${2:-none}"
LATEST_TAG="${3:-}"

[ -z "$BUMP_TYPE" ] && err "Bump type (arg 1) is required. Must be 'same', 'major', 'minor', 'patch', 'alpha', 'beta', or 'rc'."

case "$BUMP_TYPE" in
  same|major|minor|patch|alpha|beta|rc) ;;
  *) err "Invalid bump type '$BUMP_TYPE'. Must be 'same', 'major', 'minor', 'patch', 'alpha', 'beta', or 'rc'." ;;
esac

# ── Resolve latest tag ───────────────────────────────────────────────────────

if [ -z "$LATEST_TAG" ]; then
  for TAG in $(git tag 2>/dev/null || true); do
    if [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      if [ -z "$LATEST_TAG" ] || [[ "$(semver_key "$TAG")" > "$(semver_key "$LATEST_TAG")" ]]; then
        LATEST_TAG="$TAG"
      fi
    fi
  done
  LATEST_TAG="${LATEST_TAG:-v0.0.0}"
fi

log "Latest tag found: $LATEST_TAG"

[[ "$LATEST_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]] \
  || err "Latest tag '$LATEST_TAG' does not follow version format vMAJOR.MINOR.PATCH[-LABEL.NUM]"

# ── Parse tag ────────────────────────────────────────────────────────────────

VERSION="${LATEST_TAG#v}"
BASE_VERSION="${VERSION%%-*}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"

[[ "$MAJOR" =~ ^[0-9]+$ && "$MINOR" =~ ^[0-9]+$ && "$PATCH" =~ ^[0-9]+$ ]] \
  || err "Failed to parse major/minor/patch numbers from version '$BASE_VERSION'"

# ── Compute next version ─────────────────────────────────────────────────────

if [[ "$VERSION" != *-* ]]; then
  # ── Stable state ──────────────────────────────────────────────────────────
  case "$BUMP_TYPE" in
    same|alpha|beta|rc)
      err "The repository is in a stable state ($LATEST_TAG). You must select 'major', 'minor', or 'patch' to start a new prerelease cycle." ;;
  esac
  TARGET_LABEL=$(resolve_label "$PRERELEASE_LABEL" "")
  bump_base "$BUMP_TYPE"
  echo "v${MAJOR}.${MINOR}.${PATCH}-${TARGET_LABEL}.1"

else
  # ── Prerelease state ──────────────────────────────────────────────────────
  SUFFIX="${VERSION#*-}"
  [[ "$SUFFIX" == *.* ]] || err "Invalid prerelease suffix '$SUFFIX'. Expected format LABEL.NUMBER (e.g. beta.1)."
  CURRENT_LABEL="${SUFFIX%%.*}"
  CURRENT_NUM="${SUFFIX#*.}"
  [[ "$CURRENT_NUM" =~ ^[0-9]+$ ]] || err "Prerelease number '$CURRENT_NUM' is not a valid integer."

  case "$BUMP_TYPE" in
    major|minor|patch)
      TARGET_LABEL=$(resolve_label "$PRERELEASE_LABEL" "$CURRENT_LABEL")
      bump_base "$BUMP_TYPE"
      echo "v${MAJOR}.${MINOR}.${PATCH}-${TARGET_LABEL}.1"
      ;;
    same)
      echo "v${BASE_VERSION}-${CURRENT_LABEL}.$((CURRENT_NUM + 1))"
      ;;
    *)
      # alpha / beta / rc — compare against active label rank
      VAL_CURRENT=$(label_rank "$CURRENT_LABEL")
      VAL_TARGET=$(label_rank "$BUMP_TYPE")
      log "Current label: $CURRENT_LABEL (rank: $VAL_CURRENT) → target: $BUMP_TYPE (rank: $VAL_TARGET)"
      if   [ "$VAL_TARGET" -gt "$VAL_CURRENT" ]; then echo "v${BASE_VERSION}-${BUMP_TYPE}.1"
      elif [ "$VAL_TARGET" -eq "$VAL_CURRENT" ]; then echo "v${BASE_VERSION}-${CURRENT_LABEL}.$((CURRENT_NUM + 1))"
      else err "Cannot demote active prerelease label from '$CURRENT_LABEL' to '$BUMP_TYPE'."
      fi
      ;;
  esac
fi
