#!/bin/bash

################################################################################
# semantic-version.sh - Semantic Versioning Analyzer
#
# Analyzes git commits since last tag and determines semantic version bump
# Supports conventional commits (feat:, fix:, BREAKING:) and GitHub labels
#
# Usage:
#   # Analyze and output JSON (for AI/CLI interaction)
#   ./semantic-version.sh --analyze
#
#   # Interactive mode (prompts for breaking changes)
#   ./semantic-version.sh --interactive
#
#   # Get suggested bump (patch|minor|major)
#   ./semantic-version.sh --bump-type
#
#   # Prompt for breaking changes, output JSON response
#   ./semantic-version.sh --confirm-breaking
#
# Output Format (JSON):
#   {
#     "bump_type": "minor",
#     "changes": {
#       "breaking": 0,
#       "features": 2,
#       "fixes": 3
#     },
#     "commits": [...],
#     "requires_input": true,
#     "breaking_change_response": "no"
#   }
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default config file
CONFIG_FILE="${ROOT_DIR}/universal-ci.config.json"

# Color codes for human-readable output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

log_info() {
  echo -e "${BLUE}ℹ ${1}${NC}" >&2
}

log_success() {
  echo -e "${GREEN}✓ ${1}${NC}" >&2
}

log_warn() {
  echo -e "${YELLOW}⚠ ${1}${NC}" >&2
}

log_error() {
  echo -e "${RED}✗ ${1}${NC}" >&2
}

# JSON encode a string (escape quotes, newlines, etc)
json_encode() {
  local string="$1"
  echo "$string" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/g' | tr -d '\n'
}

# Read config value using sed (portable JSON parsing)
read_config_value() {
  local key="$1"
  local default="$2"
  
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "$default"
    return
  fi
  
  # Try to read from config, fallback to default
  local value=$(sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$CONFIG_FILE" 2>/dev/null | head -1)
  [[ -z "$value" ]] && value="$default"
  echo "$value"
}

# Get last tag, fallback to first commit
# Updated to detect "release commits" (chore: release v...) in case local tags are missing
get_last_tag() {
  # 1. Find the last commit that looks like a release (CodeUChain/Semantic Release pattern)
  # Looks for: "chore: release v", "release: v", "chore(release): v"
  local last_release_commit=$(git log --grep="^chore: release v" --grep="^release: v" --grep="^chore(release): v" -n 1 --format="%H")
  
  # 2. Find the last real git tag
  local last_git_tag=$(git describe --tags --abbrev=0 2>/dev/null)
  
  # 3. Determine which is more recent (closest to HEAD)
  if [[ -n "$last_release_commit" ]]; then
    # If we have a release commit, filtering by it is safer than tags which might remain locally even if history changed
    # or tags might be missing locally if not pulled
    echo "$last_release_commit"
    return
  fi

  if [[ -n "$last_git_tag" ]]; then
    echo "$last_git_tag"
    return
  fi
  
  # Fallback: First commit
  git rev-list --max-parents=0 HEAD 2>/dev/null || echo ""
}

# Get commits since last tag
get_commits_since_tag() {
  local tag="$1"
  local format="%H|%s|%b"
  
  if [[ -z "$tag" ]]; then
    git log --format="$format" --reverse
  else
    git log "${tag}..HEAD" --format="$format" --reverse
  fi
}

# Parse commit message for type (feat, fix, breaking, etc)
parse_commit_type() {
  local message="$1"
  
  # Check for BREAKING CHANGE in commit body or subject
  if echo "$message" | grep -q "^BREAKING CHANGE:" || echo "$message" | grep -q "^breaking:"; then
    echo "breaking"
  elif echo "$message" | grep -q "^feat"; then
    echo "feat"
  elif echo "$message" | grep -q "^fix"; then
    echo "fix"
  elif echo "$message" | grep -q "^docs"; then
    echo "docs"
  elif echo "$message" | grep -q "^style"; then
    echo "style"
  elif echo "$message" | grep -q "^refactor"; then
    echo "refactor"
  elif echo "$message" | grep -q "^perf"; then
    echo "perf"
  elif echo "$message" | grep -q "^test"; then
    echo "test"
  elif echo "$message" | grep -q "^ci"; then
    echo "ci"
  else
    echo "other"
  fi
}

# Analyze commits and determine version bump
analyze_commits() {
  local last_tag=$(get_last_tag)
  local commits=$(get_commits_since_tag "$last_tag")
  
  local breaking_count=0
  local feature_count=0
  local fix_count=0
  local other_count=0
  local commit_list=""
  
  while IFS='|' read -r hash subject body; do
    [[ -z "$hash" ]] && continue
    
    local type=$(parse_commit_type "$subject$body")
    local commit_entry=$(echo "$subject" | sed 's/"//g')
    
    case "$type" in
      breaking) ((breaking_count++)); commit_list+="\"breaking: $commit_entry\"," ;;
      feat) ((feature_count++)); commit_list+="\"feat: $commit_entry\"," ;;
      fix) ((fix_count++)); commit_list+="\"fix: $commit_entry\"," ;;
      *) ((other_count++)) ;;
    esac
  done <<< "$commits"
  
  # Determine bump type
  local bump_type="patch"
  [[ $breaking_count -gt 0 ]] && bump_type="major"
  [[ $feature_count -gt 0 && $bump_type == "patch" ]] && bump_type="minor"
  
  # Remove trailing comma from commit list
  commit_list="${commit_list%,}"
  
  # Return as space-separated values for later parsing
  echo "$bump_type|$breaking_count|$feature_count|$fix_count|$commit_list"
}

# Prompt user/agent for breaking changes
prompt_breaking_change() {
  local mode="${1:-interactive}"
  local response=""
  
  if [[ "$mode" == "json" ]]; then
    # JSON mode: output question, read response from stdin
    echo '{"prompt":"Has any breaking change been made to the API, CLI, or configuration?","expected":["yes","no"]}'
    return 0
  fi
  
  # Interactive mode: direct prompt
  log_warn "Breaking Change Detection"
  echo ""
  echo "Your commits suggest a ${YELLOW}${bump_type}${NC} version bump."
  echo ""
  echo "Has any breaking change been made to the API, CLI, or configuration?"
  echo "  • API changes that aren't backward compatible"
  echo "  • CLI flag/argument removal or significant changes"
  echo "  • Configuration format changes"
  echo "  • Database schema changes"
  echo ""
  
  while [[ -z "$response" ]]; do
    read -p "$(echo -e ${BLUE}Has breaking change? [yes/no]${NC}: )" response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$response" != "yes" && "$response" != "no" ]]; then
      log_error "Please respond with 'yes' or 'no'"
      response=""
    fi
  done
  
  # Update bump_type if breaking change
  if [[ "$response" == "yes" && "$bump_type" != "major" ]]; then
    bump_type="major"
  fi
  
  echo "$response"
}

# Output analysis as JSON
output_json() {
  local bump_type="$1"
  local breaking_count="$2"
  local feature_count="$3"
  local fix_count="$4"
  local commit_list="$5"
  local breaking_response="${6:-}"
  
  cat <<EOF
{
  "bump_type": "$bump_type",
  "changes": {
    "breaking": $breaking_count,
    "features": $feature_count,
    "fixes": $fix_count
  },
  "commits": [$commit_list],
  "requires_input": true,
  "breaking_change_response": "$breaking_response"
}
EOF
}

################################################################################
# Main
################################################################################

case "${1:-}" in
  --analyze)
    analysis=$(analyze_commits)
    IFS='|' read -r bump_type breaking_count feature_count fix_count commit_list <<< "$analysis"
    output_json "$bump_type" "$breaking_count" "$feature_count" "$fix_count" "$commit_list"
    ;;
  
  --bump-type)
    analysis=$(analyze_commits)
    IFS='|' read -r bump_type _ _ _ _ <<< "$analysis"
    echo "$bump_type"
    ;;
  
  --interactive)
    analysis=$(analyze_commits)
    IFS='|' read -r bump_type breaking_count feature_count fix_count commit_list <<< "$analysis"
    breaking_response=$(prompt_breaking_change "interactive")
    output_json "$bump_type" "$breaking_count" "$feature_count" "$fix_count" "$commit_list" "$breaking_response"
    log_success "Version bump: ${YELLOW}${bump_type}${NC}"
    ;;
  
  --json-prompt)
    # Output JSON-formatted breaking change prompt (for AI/JSON CLI)
    prompt_breaking_change "json"
    ;;
  
  --help)
    cat <<EOF
Semantic Version Analyzer - Determine version bumps from git history

USAGE:
  semantic-version.sh [OPTION]

OPTIONS:
  --analyze              Analyze commits, output JSON with suggested bump
  --bump-type           Output just the bump type (patch|minor|major)
  --interactive         Interactive mode with breaking change prompt
  --json-prompt         Output JSON-formatted breaking change prompt
  --help                Show this help message

CONVENTIONAL COMMIT TYPES:
  feat:     New feature (triggers minor bump)
  fix:      Bug fix (triggers patch bump)
  BREAKING: Breaking change (triggers major bump, overrides others)

EXAMPLE:
  # Analyze changes since last tag
  \$ ./semantic-version.sh --analyze
  {"bump_type":"minor","changes":{"breaking":0,"features":2,"fixes":1},...}

  # Interactive with breaking change prompt
  \$ ./semantic-version.sh --interactive

  # Use in script
  \$ BUMP=\$(./semantic-version.sh --bump-type)
  \$ echo "Next version bump: \$BUMP"

CONFIG:
  Settings in universal-ci.config.json under "semver" section
EOF
    ;;
  
  *)
    log_error "Unknown option: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
esac
