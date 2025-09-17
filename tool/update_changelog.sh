#!/bin/bash

# Script to update CHANGELOG.md files with GitHub release notes
# Usage: ./update_changelog.sh <tag_name> <repo_owner> <repo_name>

set -e

TAG_NAME="$1"
REPO_OWNER="$2"
REPO_NAME="$3"

if [ -z "$TAG_NAME" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
    echo "Usage: $0 <tag_name> <repo_owner> <repo_name>"
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

echo "Fetching release notes for $TAG_NAME..."

# Get release notes from GitHub API
RELEASE_NOTES=$(gh api repos/$REPO_OWNER/$REPO_NAME/releases/tags/$TAG_NAME --jq '.body')

if [ -z "$RELEASE_NOTES" ] || [ "$RELEASE_NOTES" = "null" ]; then
    echo "Error: Could not fetch release notes for tag $TAG_NAME"
    exit 1
fi

# Function to update a CHANGELOG.md file
update_changelog() {
    local changelog_file="$1"
    local package_name="$2"
    
    if [ ! -f "$changelog_file" ]; then
        echo "Warning: $changelog_file not found, skipping..."
        return
    fi

    echo "Updating $changelog_file..."
    
    # Create temporary file
    temp_file=$(mktemp)
    
    # Get current date
    current_date=$(date '+%Y-%m-%d')
    
    # Create new changelog entry
    cat > "$temp_file" << EOF
## $TAG_NAME ($current_date)

$RELEASE_NOTES

EOF
    
    # Append existing changelog content (skip the first title line if it exists)
    if grep -q "^#" "$changelog_file"; then
        # If file starts with a title, keep it and add content after
        head -1 "$changelog_file" >> "$temp_file"
        echo "" >> "$temp_file"
        tail -n +2 "$changelog_file" >> "$temp_file"
    else
        # If no title, just append everything
        cat "$changelog_file" >> "$temp_file"
    fi
    
    # Replace original file
    mv "$temp_file" "$changelog_file"
    
    echo "✅ Updated $changelog_file"
}

# Update both CHANGELOG files
update_changelog "packages/isar_plus/CHANGELOG.md" "isar_plus"
update_changelog "packages/isar_plus_flutter_libs/CHANGELOG.md" "isar_plus_flutter_libs"

echo "🎉 CHANGELOG files updated successfully!"