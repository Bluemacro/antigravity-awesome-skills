#!/bin/bash

# Fork Disclaimer Auto-Population Script
# This script automatically generates and updates FORK_DISCLAIMER.md for all your forks
# 
# Usage:
#   ./scripts/apply-fork-disclaimer.sh <original_repo_owner> <original_repo_name>
#   Example: ./scripts/apply-fork-disclaimer.sh sickn33 agentic-awesome-skills
#
# Prerequisites:
#   - GitHub CLI (gh) installed and authenticated
#   - jq installed (for JSON parsing)
#   - Bash 4+
#
# What it does:
#   1. Reads the template from .github/FORK_DISCLAIMER_TEMPLATE.md
#   2. Replaces all placeholders with actual repository information
#   3. Generates FORK_DISCLAIMER.md in the current fork
#   4. Commits and pushes the changes

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}===================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Validate input
validate_input() {
    if [ $# -ne 2 ]; then
        print_error "Invalid number of arguments"
        echo "Usage: $0 <original_repo_owner> <original_repo_name>"
        echo "Example: $0 sickn33 agentic-awesome-skills"
        exit 1
    fi
}

# Get current fork information
get_fork_info() {
    local owner=$(gh api user --jq '.login')
    local repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' | cut -d'/' -f2)
    
    echo "$owner:$repo"
}

# Read template
read_template() {
    local template_path=".github/FORK_DISCLAIMER_TEMPLATE.md"
    
    if [ ! -f "$template_path" ]; then
        print_error "Template not found at $template_path"
        exit 1
    fi
    
    cat "$template_path"
}

# Replace placeholders
replace_placeholders() {
    local content="$1"
    local original_author="$2"
    local original_repo="$3"
    local fork_owner="$4"
    local fork_repo_name="$5"
    
    # Replace all placeholders
    content="${content//\{\{ORIGINAL_AUTHOR\}\}/$original_author}"
    content="${content//\{\{ORIGINAL_REPO\}\}/$original_repo}"
    content="${content//\{\{FORK_OWNER\}\}/$fork_owner}"
    content="${content//\{\{FORK_REPO_NAME\}\}/$fork_repo_name}"
    
    echo "$content"
}

# Generate disclaimer file
generate_disclaimer() {
    local original_author="$1"
    local original_repo="$2"
    local fork_owner="$3"
    local fork_repo_name="$4"
    local output_file=".github/FORK_DISCLAIMER.md"
    
    print_info "Reading template..."
    local template=$(read_template)
    
    print_info "Replacing placeholders..."
    local content=$(replace_placeholders "$template" "$original_author" "$original_repo" "$fork_owner" "$fork_repo_name")
    
    print_info "Writing to $output_file..."
    echo "$content" > "$output_file"
    
    print_success "Generated $output_file"
}

# Commit and push
commit_and_push() {
    local repo_name="$1"
    
    if [ -z "$(git status --porcelain)" ]; then
        print_info "No changes to commit"
        return 0
    fi
    
    print_info "Staging changes..."
    git add .github/FORK_DISCLAIMER.md
    
    print_info "Committing changes..."
    git commit -m "docs: add fork disclaimer notice for legal clarity and attribution

This fork is a reference copy of the upstream repository.
All rights remain with the original authors.
See .github/FORK_DISCLAIMER.md for details."
    
    print_info "Pushing to remote..."
    git push origin main
    
    print_success "Changes committed and pushed"
}

# Main execution
main() {
    print_header "Fork Disclaimer Auto-Population Tool"
    
    # Validate input
    validate_input "$@"
    
    local original_author="$1"
    local original_repo="$2"
    
    # Check prerequisites
    check_prerequisites
    
    # Get fork information
    print_info "Retrieving fork information..."
    local fork_info=$(get_fork_info)
    local fork_owner=$(echo "$fork_info" | cut -d':' -f1)
    local fork_repo_name=$(echo "$fork_info" | cut -d':' -f2)
    
    print_success "Fork detected: $fork_owner/$fork_repo_name"
    print_success "Original repo: $original_author/$original_repo"
    
    # Generate disclaimer
    generate_disclaimer "$original_author" "$original_repo" "$fork_owner" "$fork_repo_name"
    
    # Commit and push
    commit_and_push "$fork_repo_name"
    
    print_header "✓ Fork Disclaimer Successfully Applied"
    echo ""
    echo "Fork Information:"
    echo "  Owner: $fork_owner"
    echo "  Repo: $fork_repo_name"
    echo ""
    echo "Original Repository:"
    echo "  Owner: $original_author"
    echo "  Repo: $original_repo"
    echo ""
    echo "View your fork: https://github.com/$fork_owner/$fork_repo_name"
}

# Run main function
main "$@"
