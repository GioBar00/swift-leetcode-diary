#!/bin/bash
set -euo pipefail

STABLE_TAG=$1
PREV_STABLE_TAG=$2
TARGET_REV=${3:-HEAD}

# Generate the new section
git-cliff --config .github/cliff.toml "$PREV_STABLE_TAG..$TARGET_REV" --tag "$STABLE_TAG" --strip header > new-section.md

# Find line numbers in CHANGELOG.md
# 1. End of header (the line before the first "## [")
FIRST_RELEASE_LINE=$(grep -n "^## \[" CHANGELOG.md | head -n 1 | cut -d: -f1)
HEADER_END=$((FIRST_RELEASE_LINE - 1))

# 2. Start of previous stable release
PREV_RELEASE_LINE=$(grep -n "^## \[$PREV_STABLE_TAG\]" CHANGELOG.md | cut -d: -f1)

# Reconstruct the file
head -n "$HEADER_END" CHANGELOG.md > CHANGELOG_NEW.md
cat new-section.md >> CHANGELOG_NEW.md
echo "" >> CHANGELOG_NEW.md
tail -n +$PREV_RELEASE_LINE CHANGELOG.md >> CHANGELOG_NEW.md

mv CHANGELOG_NEW.md CHANGELOG.md
rm new-section.md
