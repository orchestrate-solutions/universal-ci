#!/bin/bash
# Bump version and update changelog, package.json, and VERSION file
# Usage: .github/scripts/bump-version.sh [major|minor|patch]

set -e

VERSION_FILE="VERSION"
CHANGELOG_FILE="CHANGELOG.md"
PACKAGE_FILE="package.json"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ VERSION file not found"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '\n' | xargs)
echo "Current version: $CURRENT_VERSION"

# Determine bump type
BUMP_TYPE="${1:-patch}"
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    echo "Usage: $0 [major|minor|patch]"
    exit 1
fi

# Parse version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Bump version
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Get today's date
DATE=$(date +%Y-%m-%d)

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Update CHANGELOG.md - insert new version section after header
TEMP_CHANGELOG=$(mktemp)
{
    # Copy header and unreleased section
    head -n 14 "$CHANGELOG_FILE"
    
    # Add new version section
    echo ""
    echo "## [$NEW_VERSION] - $DATE"
    echo ""
    echo "### Added"
    echo "- "
    echo ""
    echo "### Changed"
    echo "- "
    echo ""
    echo "### Fixed"
    echo "- "
    echo ""
    
    # Copy rest of file (skip header)
    tail -n +15 "$CHANGELOG_FILE"
} > "$TEMP_CHANGELOG"

mv "$TEMP_CHANGELOG" "$CHANGELOG_FILE"

# Update package.json version
if [ -f "$PACKAGE_FILE" ]; then
    # Use Node.js to safely update JSON
    node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('$PACKAGE_FILE', 'utf8'));
        pkg.version = '$NEW_VERSION';
        fs.writeFileSync('$PACKAGE_FILE', JSON.stringify(pkg, null, 2) + '\n');
    "
    echo "✅ Updated $PACKAGE_FILE"
fi

echo ""
echo "✅ Version bumped: $CURRENT_VERSION → $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Edit CHANGELOG.md to describe changes under [$NEW_VERSION]"
echo "  2. git add VERSION CHANGELOG.md package.json"
echo "  3. git commit -m \"release: v$NEW_VERSION\""
echo "  4. git push origin main"
echo ""
echo "The GitHub Actions workflow will then:"
echo "  - Publish to npm"
echo "  - Create GitHub release"
echo "  - Tag the commit"
