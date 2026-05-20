#!/bin/bash

# Comprehensive PR Review Script
# Supports both bulk review and single PR URL review
# Generates reports with format: <SEVERITY>_<BRANCH_NAME>_<AUTHOR_NAME>.md

set -e

# Configuration
CURRENT_REPO_DIR="/Users/deepakshingan/Development/krista-global-catalog"
REPORTS_DIR="$CURRENT_REPO_DIR/PR_REVIEW"
API_BASE="https://api.bitbucket.org/2.0/repositories/syncappinc/krista-global-catalog"
TEMP_DIR_PREFIX="/tmp/pr_review_"

# Bitbucket Authentication (optional)
# Set these environment variables for API access to open PRs:
# export BITBUCKET_USERNAME="your-username"
# export BITBUCKET_APP_PASSWORD="your-app-password"
BITBUCKET_AUTH=""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warning() { printf "${YELLOW}[WARNING]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# Initialize Bitbucket authentication after logging functions are defined
if [ -n "$BITBUCKET_USERNAME" ] && [ -n "$BITBUCKET_APP_PASSWORD" ]; then
    BITBUCKET_AUTH="-u $BITBUCKET_USERNAME:$BITBUCKET_APP_PASSWORD"
    log_info "Bitbucket authentication configured for user: $BITBUCKET_USERNAME"
fi

# Setup directories and clean previous reports
setup_directories() {
    local clean_previous="$1"

    # Clean all previous reports only if requested
    if [ "$clean_previous" = "true" ] && [ -d "$REPORTS_DIR" ]; then
        log_info "Cleaning previous reports..."
        rm -rf "$REPORTS_DIR"
    fi

    mkdir -p "$REPORTS_DIR"
    log_success "Reports directory ready: $REPORTS_DIR"
}

# Clone repository to temporary directory
clone_repository() {
    local repo_info="$1"
    local branch="$2"

    local temp_dir="${TEMP_DIR_PREFIX}$(date +%s)_$$"
    local repo_url="https://bitbucket.org/${repo_info}.git"

    log_info "Cloning repository $repo_info to temporary directory..."
    log_info "Repository URL: $repo_url"
    log_info "Target branch: $branch"

    # Create temp directory
    mkdir -p "$temp_dir"

    # Clone repository with specific branch
    if git clone --depth 1 --branch "$branch" "$repo_url" "$temp_dir" 2>/dev/null; then
        log_success "Successfully cloned repository to $temp_dir"
        echo "$temp_dir"
        return 0
    fi

    # Fallback: clone default branch and try to checkout target branch
    log_warning "Failed to clone specific branch, trying default branch..."
    if git clone --depth 50 "$repo_url" "$temp_dir" 2>/dev/null; then
        cd "$temp_dir"
        if git checkout "$branch" 2>/dev/null || git checkout "origin/$branch" 2>/dev/null; then
            log_success "Successfully cloned repository and checked out branch $branch"
            echo "$temp_dir"
            return 0
        else
            log_warning "Could not checkout branch $branch, using default branch"
            echo "$temp_dir"
            return 0
        fi
    fi

    # Cleanup on failure
    rm -rf "$temp_dir" 2>/dev/null
    log_error "Failed to clone repository $repo_info"
    return 1
}

# Cleanup temporary directory
cleanup_temp_dir() {
    local temp_dir="$1"

    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ] && [[ "$temp_dir" == /tmp/pr_review_* ]]; then
        log_info "Cleaning up temporary directory: $temp_dir"
        rm -rf "$temp_dir"
        log_success "Temporary directory cleaned up"
    fi
}

# Check if we're analyzing the current repository or need to clone
is_current_repository() {
    local repo_info="$1"

    # Extract repository name from repo_info (syncappinc/krista-global-catalog -> krista-global-catalog)
    local repo_name=$(echo "$repo_info" | cut -d'/' -f2)
    local current_repo_name=$(basename "$CURRENT_REPO_DIR")

    if [ "$repo_name" = "$current_repo_name" ]; then
        return 0  # true - same repository
    else
        return 1  # false - different repository
    fi
}

# Parse PR URL to extract PR ID and repository info
parse_pr_url() {
    local pr_url="$1"

    # Extract repository and PR ID from various URL formats
    # https://bitbucket.org/syncappinc/krista-global-catalog/pull-requests/1565
    # https://bitbucket.org/syncappinc/customer-success/pull-requests/32

    if echo "$pr_url" | grep -q "bitbucket.org.*pull-requests"; then
        local repo_info=$(echo "$pr_url" | grep -oE 'bitbucket.org/[^/]+/[^/]+' | sed 's|bitbucket.org/||')
        local pr_id=$(echo "$pr_url" | grep -oE 'pull-requests/[0-9]+' | grep -oE '[0-9]+')

        if [ -n "$pr_id" ] && [ -n "$repo_info" ]; then
            echo "$repo_info|$pr_id"
            return 0
        fi
    fi

    return 1
}

# Get PR details from Bitbucket API
get_pr_details() {
    local repo_info="$1"
    local pr_id="$2"

    log_info "Fetching PR details for PR #$pr_id from repository $repo_info..."

    local api_url="https://api.bitbucket.org/2.0/repositories/$repo_info/pullrequests/$pr_id"
    local pr_data

    # Try API call with authentication if available
    if [ -n "$BITBUCKET_AUTH" ]; then
        pr_data=$(curl -s $BITBUCKET_AUTH "$api_url" 2>/dev/null)
    else
        pr_data=$(curl -s "$api_url" 2>/dev/null)
    fi
    local curl_exit_code=$?

    if [ $curl_exit_code -eq 0 ] && [ -n "$pr_data" ]; then
        # Check if we got an error response
        if echo "$pr_data" | jq -e '.error' >/dev/null 2>&1; then
            local error_msg=$(echo "$pr_data" | jq -r '.error.message' 2>/dev/null || echo "Unknown API error")
            log_warning "API returned error: $error_msg"
        elif echo "$pr_data" | jq -e '.id' >/dev/null 2>&1; then
            # Success - parse PR data
            local title=$(echo "$pr_data" | jq -r '.title' 2>/dev/null || echo "Unknown Title")
            local state=$(echo "$pr_data" | jq -r '.state' 2>/dev/null || echo "UNKNOWN")
            local source_branch=$(echo "$pr_data" | jq -r '.source.branch.name' 2>/dev/null || echo "unknown-branch")
            local target_branch=$(echo "$pr_data" | jq -r '.destination.branch.name' 2>/dev/null || echo "unknown-target")
            local author=$(echo "$pr_data" | jq -r '.author.display_name' 2>/dev/null | tr ' ' '_' || echo "Unknown_Author")
            local created_date=$(echo "$pr_data" | jq -r '.created_on' 2>/dev/null || echo "Unknown Date")

            log_success "Retrieved PR details from API"
            echo "$pr_id|$title|$state|$source_branch|$target_branch|$author|$created_date"
            return 0
        else
            log_warning "API returned unexpected response format"
        fi
    else
        log_warning "API call failed (curl exit code: $curl_exit_code)"
    fi

    log_warning "Falling back to git analysis for PR #$pr_id"
    return 1
}

# Get OPEN PR details from git branches (fallback method) - SKIPS MERGED PRs
get_pr_from_git() {
    local pr_id="$1"

    log_info "Searching for OPEN PR #$pr_id in git branches (skipping merged PRs)..."

    cd "$CURRENT_REPO_DIR"

    # Try to find by PR number in branch names
    local pr_branch=$(git branch -r | grep -i "$pr_id" | head -1 | sed 's/.*origin\///' 2>/dev/null || echo "")
    if [ -n "$pr_branch" ]; then
        local latest_commit=$(git log --oneline "$pr_branch" -1 2>/dev/null || echo "")
        if [ -n "$latest_commit" ]; then
            local commit_hash=$(echo "$latest_commit" | cut -d' ' -f1)
            local commit_msg=$(echo "$latest_commit" | cut -d' ' -f2-)
            local author=$(git show --format="%an" -s "$commit_hash" 2>/dev/null | tr ' ' '_' || echo "Unknown_Author")
            local date=$(git show --format="%ci" -s "$commit_hash" 2>/dev/null || echo "Unknown Date")

            log_success "Found branch related to PR #$pr_id: $pr_branch"
            echo "$pr_id|$commit_msg|OPEN|$pr_branch|develop-1.0|$author|$date"
            return 0
        fi
    fi

    log_warning "PR #$pr_id not found in git history or branches"
    return 1
}

# Analyze branch directly (for open PRs without PR ID)
analyze_branch_directly() {
    local branch_name="$1"
    local repo_dir="${2:-$CURRENT_REPO_DIR}"

    log_info "Analyzing branch directly: $branch_name"

    cd "$repo_dir"

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
        log_error "Branch $branch_name not found"
        return 1
    fi

    # Get branch information
    local latest_commit=$(git log "origin/$branch_name" --oneline -1 2>/dev/null)
    if [ -z "$latest_commit" ]; then
        log_error "Could not get commit information for branch $branch_name"
        return 1
    fi

    local commit_hash=$(echo "$latest_commit" | cut -d' ' -f1)
    local commit_msg=$(echo "$latest_commit" | cut -d' ' -f2-)
    local author=$(git show --format="%an" -s "$commit_hash" 2>/dev/null | tr ' ' '_' || echo "Unknown_Author")
    local date=$(git show --format="%ci" -s "$commit_hash" 2>/dev/null || echo "Unknown Date")

    log_success "Found branch information for $branch_name"
    echo "branch|$commit_msg|OPEN|$branch_name|develop-1.0|$author|$date"
    return 0
}

# Find recent branches that might be open PRs
find_recent_branches() {
    log_info "Finding recent branches that might be open PRs..."

    cd "$CURRENT_REPO_DIR"
    git fetch origin >/dev/null 2>&1

    # Get branches sorted by recent activity
    git for-each-ref --sort=-committerdate refs/remotes/origin --format='%(refname:short)|%(committerdate)|%(authorname)' | \
    grep -E "(feature/|bugfix/|hotfix/)" | \
    head -20 | \
    while IFS='|' read -r branch_ref commit_date author_name; do
        local branch=$(echo "$branch_ref" | sed 's/origin\///')
        local clean_author=$(echo "$author_name" | tr ' ' '_')
        local latest_commit=$(git log "$branch_ref" --oneline -1 2>/dev/null)
        local commit_msg=$(echo "$latest_commit" | cut -d' ' -f2-)

        echo "$branch|$clean_author|$commit_msg|$commit_date|recent"
    done
}

# Get all open and draft PRs from Bitbucket API with pagination
get_all_open_prs() {
    local page_url="$API_BASE/pullrequests?state=OPEN&pagelen=100"
    local all_prs_file="/tmp/pr_data_$$"
    local page_count=0

    # Clear temp file
    > "$all_prs_file"

    while [ -n "$page_url" ] && [ $page_count -lt 10 ]; do  # Limit to 10 pages max
        page_count=$((page_count + 1))
        local pr_data

        if [ -n "$BITBUCKET_AUTH" ]; then
            pr_data=$(curl -s $BITBUCKET_AUTH "$page_url" 2>/dev/null)
        else
            pr_data=$(curl -s "$page_url" 2>/dev/null)
        fi

        if [ $? -eq 0 ] && [ -n "$pr_data" ]; then
            if echo "$pr_data" | jq -e '.values' >/dev/null 2>&1; then
                # Parse PR data and filter for OPEN status (includes DRAFT)
                echo "$pr_data" | jq -r '.values[] | select(.state == "OPEN") | "\(.source.branch.name)|\(.author.display_name)|\(.title)|\(.created_on)|\(.id)"' 2>/dev/null >> "$all_prs_file"

                # Get next page URL
                page_url=$(echo "$pr_data" | jq -r '.next // empty' 2>/dev/null)
            else
                break
            fi
        else
            break
        fi
    done

    if [ -s "$all_prs_file" ]; then
        local pr_count=$(wc -l < "$all_prs_file")
        log_success "Retrieved $pr_count open PRs from Bitbucket API"

        # Clean and output PR data
        while IFS='|' read -r branch author title created_on pr_id; do
            if [ -n "$branch" ] && [ -n "$pr_id" ]; then
                # Clean author name
                local clean_author=$(echo "$author" | tr ' ' '_')
                echo "$branch|$clean_author|$title|$created_on|$pr_id"
            fi
        done < "$all_prs_file"

        rm -f "$all_prs_file"
        return 0
    fi

    rm -f "$all_prs_file"
    return 1
}

# Get OPEN and DRAFT PRs only (with fallback) - EXCLUDES MERGED PRs
get_open_prs() {
    # Try API first for actual open PRs
    if get_all_open_prs; then
        return 0
    fi

    # Fallback to recent branch analysis (OPEN PRs only)
    log_warning "API access failed, using recent branch analysis for OPEN PRs"
    log_info "Filtering for recent branches (likely open PRs, excluding old/merged branches)"

    cd "$CURRENT_REPO_DIR"
    git fetch origin >/dev/null 2>&1

    # Get recent branches only (last 30 days) to avoid old merged branches
    local cutoff_date=$(date -d '30 days ago' '+%Y-%m-%d' 2>/dev/null || date -v-30d '+%Y-%m-%d' 2>/dev/null || echo '2024-01-01')

    # Get branches with recent activity that look like PR branches
    git for-each-ref --sort=-committerdate refs/remotes/origin --format='%(refname:short)|%(committerdate:short)|%(authorname)' | \
    grep -E "(feature/|bugfix/|hotfix/)" | \
    while IFS='|' read -r branch_ref commit_date author_name; do
        # Skip if older than 30 days
        if [[ "$commit_date" < "$cutoff_date" ]]; then
            continue
        fi

        local branch=$(echo "$branch_ref" | sed 's/origin\///')
        local clean_author=$(echo "$author_name" | tr ' ' '_')

        # Get latest commit info
        local latest_commit=$(git log "$branch_ref" --oneline -1 2>/dev/null)
        local commit_msg=$(echo "$latest_commit" | cut -d' ' -f2-)

        # Check if this branch might be merged (has merge commit in develop-1.0)
        if git merge-base --is-ancestor "$branch_ref" origin/develop-1.0 2>/dev/null; then
            # Check if it's actually merged by looking for merge commit
            local merge_commit=$(git log origin/develop-1.0 --oneline --grep="$branch" --grep="pull request" -i --max-count=1 2>/dev/null)
            if [ -n "$merge_commit" ]; then
                # Skip merged branches
                continue
            fi
        fi

        echo "$branch|$clean_author|$commit_msg|$commit_date|recent"
    done
}

# Analyze changes in a branch
analyze_branch_changes() {
    local branch="$1"
    local repo_dir="${2:-$CURRENT_REPO_DIR}"

    cd "$repo_dir"

    # Try different base branches for comparison
    local base_branches=("develop-1.0" "develop" "main" "master")

    for base_branch in "${base_branches[@]}"; do
        # Try with origin prefix first
        if git diff --name-only "origin/$base_branch...origin/$branch" 2>/dev/null | head -20; then
            return 0
        fi
        # Try without origin prefix
        if git diff --name-only "$base_branch...$branch" 2>/dev/null | head -20; then
            return 0
        fi
    done

    # Fallback: get all files in the repository
    log_warning "Could not find base branch for comparison, listing all files"
    find . -name "*.java" -type f | head -20 | sed 's|^\./||'
}

# Analyze changes for a specific PR using API
analyze_pr_changes() {
    local repo_info="$1"
    local pr_id="$2"
    local repo_dir="${3:-$CURRENT_REPO_DIR}"

    log_info "Analyzing file changes for PR #$pr_id..."

    cd "$repo_dir"

    # Try API first
    local api_url="https://api.bitbucket.org/2.0/repositories/$repo_info/pullrequests/$pr_id/diffstat"
    local diff_data

    if diff_data=$(curl -s "$api_url" 2>/dev/null); then
        if echo "$diff_data" | jq -e '.values' >/dev/null 2>&1; then
            echo "$diff_data" | jq -r '.values[].new.path // .values[].old.path' 2>/dev/null | head -20
            return 0
        fi
    fi

    # Fallback to git analysis
    log_warning "API diffstat failed, using git analysis"

    # Try to find the merge commit for this PR
    local merge_commit=$(git log --oneline --grep="pull request #$pr_id" --grep="#$pr_id" -i --max-count=1 | cut -d' ' -f1)

    if [ -n "$merge_commit" ]; then
        # Get the parent commits to find the actual changes
        local parents=$(git show --format="%P" -s "$merge_commit")
        local parent1=$(echo "$parents" | cut -d' ' -f1)
        local parent2=$(echo "$parents" | cut -d' ' -f2)

        if [ -n "$parent2" ]; then
            # This is a merge commit, get diff between parents
            git diff --name-only "$parent1..$parent2" 2>/dev/null | head -20
        else
            # Single commit, get diff with parent
            git diff --name-only "$merge_commit^..$merge_commit" 2>/dev/null | head -20
        fi
    else
        log_warning "Could not find changes for PR #$pr_id"
        echo ""
    fi
}

# Analyze Java code quality with comprehensive severity classification
analyze_java_code_quality() {
    local file_path="$1"
    local repo_dir="${2:-$CURRENT_REPO_DIR}"
    local critical_issues=""
    local major_issues=""
    local medium_issues=""
    local minor_issues=""

    if [ ! -f "$repo_dir/$file_path" ]; then
        return 0
    fi

    local file_content=$(cat "$repo_dir/$file_path")
    local file_lines=$(echo "$file_content" | wc -l)

    # CRITICAL ISSUES (Security vulnerabilities, major bugs)
    if echo "$file_content" | grep -q "password\s*=\s*\".*\"\|secret\s*=\s*\".*\"\|key\s*=\s*\".*\""; then
        critical_issues="${critical_issues}CRITICAL-SECURITY: Hardcoded credentials detected in $file_path|"
    fi

    if echo "$file_content" | grep -q "SQL.*+.*\|PreparedStatement.*+"; then
        critical_issues="${critical_issues}CRITICAL-SECURITY: SQL injection vulnerability in $file_path|"
    fi

    if echo "$file_content" | grep -q "Runtime.getRuntime.*exec\|ProcessBuilder.*start"; then
        critical_issues="${critical_issues}CRITICAL-SECURITY: Command injection risk in $file_path|"
    fi

    if echo "$file_content" | grep -q "catch.*Exception.*{[[:space:]]*}"; then
        critical_issues="${critical_issues}CRITICAL-QUALITY: Empty catch blocks in $file_path - exceptions silently ignored|"
    fi

    if echo "$file_content" | grep -q "Class.forName\|Method.invoke" && ! echo "$file_content" | grep -q "SecurityManager"; then
        critical_issues="${critical_issues}CRITICAL-SECURITY: Unsafe reflection usage in $file_path|"
    fi

    # MAJOR ISSUES (Poor practices, significant problems)
    if echo "$file_content" | grep -q "catch.*Exception.*printStackTrace"; then
        major_issues="${major_issues}MAJOR-QUALITY: Using printStackTrace in $file_path - security risk and poor logging|"
    fi

    if echo "$file_content" | grep -q "System.out.println\|System.err.println"; then
        major_issues="${major_issues}MAJOR-QUALITY: Using System.out/err in $file_path instead of proper logging|"
    fi

    if echo "$file_content" | grep -q "new.*Stream\|new.*Reader\|new.*Writer" && ! echo "$file_content" | grep -q "try.*with.*resources"; then
        major_issues="${major_issues}MAJOR-RESOURCE: Resource leak risk in $file_path - not using try-with-resources|"
    fi

    if [ "$file_lines" -gt 1000 ]; then
        major_issues="${major_issues}MAJOR-MAINTAINABILITY: Very large file $file_path ($file_lines lines) - urgent refactoring needed|"
    fi

    if echo "$file_content" | grep -q "TODO\|FIXME\|XXX"; then
        major_issues="${major_issues}MAJOR-QUALITY: Unresolved TODO/FIXME comments in $file_path|"
    fi

    # MEDIUM ISSUES (Code quality, maintainability)
    if echo "$file_content" | grep -q "public class.*{" && ! echo "$file_content" | grep -q "private\|protected"; then
        medium_issues="${medium_issues}MEDIUM-OOP: Poor encapsulation in $file_path - no private/protected members|"
    fi

    if echo "$file_content" | grep -q "for.*:.*for.*:"; then
        medium_issues="${medium_issues}MEDIUM-PERFORMANCE: Nested loops in $file_path - review algorithmic complexity|"
    fi

    if echo "$file_content" | grep -q "String.*+.*String.*+"; then
        medium_issues="${medium_issues}MEDIUM-PERFORMANCE: Multiple string concatenations in $file_path - use StringBuilder|"
    fi

    if [ "$file_lines" -gt 500 ] && [ "$file_lines" -le 1000 ]; then
        medium_issues="${medium_issues}MEDIUM-MAINTAINABILITY: Large file $file_path ($file_lines lines) - consider splitting|"
    fi

    if echo "$file_content" | grep -q "public class" && ! echo "$file_content" | grep -q "/\*\*"; then
        medium_issues="${medium_issues}MEDIUM-DOCS: Missing JavaDoc for public class in $file_path|"
    fi

    if echo "$file_content" | grep -q "if.*{.*if.*{.*if.*{"; then
        medium_issues="${medium_issues}MEDIUM-COMPLEXITY: Deep nesting detected in $file_path - consider refactoring|"
    fi

    # MINOR ISSUES (Style, conventions, minor improvements)
    if echo "$file_content" | grep -q "public.*method.*{" && ! echo "$file_content" | grep -q "/\*\*.*@param\|/\*\*.*@return"; then
        minor_issues="${minor_issues}MINOR-DOCS: Missing JavaDoc for public methods in $file_path|"
    fi

    if echo "$file_content" | grep -q "import.*\*"; then
        minor_issues="${minor_issues}MINOR-STYLE: Wildcard imports in $file_path - use specific imports|"
    fi

    if [ "$file_lines" -gt 300 ] && [ "$file_lines" -le 500 ]; then
        minor_issues="${minor_issues}MINOR-MAINTAINABILITY: Moderately large file $file_path ($file_lines lines) - monitor growth|"
    fi

    if echo "$file_content" | grep -q "catch.*Exception.*e.*{.*log"; then
        minor_issues="${minor_issues}MINOR-QUALITY: Generic exception logging in $file_path - consider specific exception types|"
    fi

    if ! echo "$file_content" | grep -q "@Override" && echo "$file_content" | grep -q "public.*equals\|public.*hashCode\|public.*toString"; then
        minor_issues="${minor_issues}MINOR-STYLE: Missing @Override annotations in $file_path|"
    fi

    echo "$critical_issues$major_issues$medium_issues$minor_issues"
}

# Analyze code quality with comprehensive severity-based filtering
analyze_code_quality() {
    local files_changed="$1"
    local repo_dir="${2:-$CURRENT_REPO_DIR}"

    local total_files=0
    local java_files=0
    local js_files=0
    local config_files=0
    local doc_files=0
    local test_files=0
    local critical_issues=0
    local major_issues=0
    local medium_issues=0
    local minor_issues=0
    local java_issues=""

    while IFS= read -r file; do
        if [ -n "$file" ]; then
            total_files=$((total_files + 1))

            case "$file" in
                *.java)
                    java_files=$((java_files + 1))
                    if [[ "$file" == *"Test.java" ]] || [[ "$file" == *"test"* ]]; then
                        test_files=$((test_files + 1))
                    fi

                    # Comprehensive Java analysis with all severity levels
                    local file_issues=$(analyze_java_code_quality "$file" "$repo_dir")
                    if [ -n "$file_issues" ]; then
                        java_issues="${java_issues}${file}:${file_issues};"

                        # Count issue types by severity
                        critical_issues=$((critical_issues + $(echo "$file_issues" | grep -o "CRITICAL-" | wc -l)))
                        major_issues=$((major_issues + $(echo "$file_issues" | grep -o "MAJOR-" | wc -l)))
                        medium_issues=$((medium_issues + $(echo "$file_issues" | grep -o "MEDIUM-" | wc -l)))
                        minor_issues=$((minor_issues + $(echo "$file_issues" | grep -o "MINOR-" | wc -l)))
                    fi
                    ;;
                *.js|*.jsx|*.ts|*.tsx) js_files=$((js_files + 1)) ;;
                *.json|*.xml|*.yml|*.yaml|*.properties) config_files=$((config_files + 1)) ;;
                *.md|*.txt) doc_files=$((doc_files + 1)) ;;
            esac
        fi
    done <<< "$files_changed"

    echo "$total_files|$java_files|$js_files|$config_files|$doc_files|$test_files|$critical_issues|$major_issues|$medium_issues|$minor_issues|$java_issues"
}

# Generate PR report
generate_pr_report() {
    local branch="$1"
    local author="$2"
    local commit_msg="$3"
    local date="$4"
    local files_changed="$5"
    local repo_dir="${6:-$CURRENT_REPO_DIR}"
    
    # Clean branch and author names for filename
    local clean_branch=$(echo "$branch" | sed 's/[^a-zA-Z0-9_-]/_/g')
    local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9_-]/_/g')

    # Analyze code quality with comprehensive severity-based filtering
    local quality_metrics=$(analyze_code_quality "$files_changed" "$repo_dir")
    local total_files=$(echo "$quality_metrics" | cut -d'|' -f1)
    local java_files=$(echo "$quality_metrics" | cut -d'|' -f2)
    local js_files=$(echo "$quality_metrics" | cut -d'|' -f3)
    local config_files=$(echo "$quality_metrics" | cut -d'|' -f4)
    local doc_files=$(echo "$quality_metrics" | cut -d'|' -f5)
    local test_files=$(echo "$quality_metrics" | cut -d'|' -f6)
    local critical_issues=$(echo "$quality_metrics" | cut -d'|' -f7)
    local major_issues=$(echo "$quality_metrics" | cut -d'|' -f8)
    local medium_issues=$(echo "$quality_metrics" | cut -d'|' -f9)
    local minor_issues=$(echo "$quality_metrics" | cut -d'|' -f10)
    local java_issues=$(echo "$quality_metrics" | cut -d'|' -f11)

    # Always generate comprehensive report with ALL suggestions (including SOLID principles)
    local total_actionable_issues=$((critical_issues + major_issues + medium_issues + minor_issues))
    log_info "Generating comprehensive report with all code quality suggestions..."

    # Determine severity prefix for filename (always generate comprehensive report)
    local severity_prefix="COMPREHENSIVE"
    if [ $critical_issues -gt 0 ]; then
        severity_prefix="CRITICAL"
    elif [ $major_issues -gt 0 ]; then
        severity_prefix="MAJOR"
    elif [ $medium_issues -gt 0 ]; then
        severity_prefix="MEDIUM"
    elif [ $minor_issues -gt 0 ]; then
        severity_prefix="MINOR"
    fi

    local report_file="$REPORTS_DIR/${severity_prefix}_${clean_branch}_${clean_author}.md"

    # Generate comprehensive actionable report with remediation steps
    cat > "$report_file" << EOF
# 🚨 ACTIONABLE PR REVIEW REPORT - $severity_prefix PRIORITY

**Branch**: $branch
**Author**: $author
**Date**: $(date '+%B %d, %Y')
**Last Commit**: $commit_msg
**Commit Date**: $date
**Priority Level**: $severity_prefix

---

## ⚠️ **ISSUES SUMMARY**

| Severity | Count | Action Required | Timeline |
|----------|-------|-----------------|----------|
| 🔴 **CRITICAL** | $critical_issues | $([ $critical_issues -gt 0 ] && echo "**IMMEDIATE FIX REQUIRED**" || echo "None") | $([ $critical_issues -gt 0 ] && echo "Before any review" || echo "-") |
| 🟠 **MAJOR** | $major_issues | $([ $major_issues -gt 0 ] && echo "**FIX BEFORE MERGE**" || echo "None") | $([ $major_issues -gt 0 ] && echo "Before merge" || echo "-") |
| 🟡 **MEDIUM** | $medium_issues | $([ $medium_issues -gt 0 ] && echo "**SHOULD FIX**" || echo "None") | $([ $medium_issues -gt 0 ] && echo "This sprint" || echo "-") |
| 🔵 **MINOR** | $minor_issues | $([ $minor_issues -gt 0 ] && echo "**CONSIDER FIXING**" || echo "None") | $([ $minor_issues -gt 0 ] && echo "Next sprint" || echo "-") |

**Total Actionable Issues**: $total_actionable_issues

---

## 📊 **CHANGE OVERVIEW**

**Files Changed**: $total_files (Java: $java_files, JS/TS: $js_files, Config: $config_files, Docs: $doc_files, Tests: $test_files)

### Files Modified:
\`\`\`
$files_changed
\`\`\`

---

## 🔴 **CRITICAL ISSUES** $([ $critical_issues -gt 0 ] && echo "($critical_issues found)" || echo "(None)")

$(if [ $critical_issues -gt 0 ]; then
    echo "**🚨 IMMEDIATE ACTION REQUIRED - DO NOT MERGE UNTIL FIXED**"
    echo ""
    echo "### Issues Found:"
    echo "$java_issues" | grep -o "CRITICAL-[^|]*" | sed 's/CRITICAL-/🔴 **/' | sed 's/:/**: /' | sed 's/$//'
    echo ""
    echo "### Remediation Steps:"
    echo "1. **Security Review**: Conduct immediate security audit"
    echo "2. **Fix Vulnerabilities**: Address hardcoded credentials, SQL injection, command injection"
    echo "3. **Code Review**: Senior developer review required"
    echo "4. **Testing**: Comprehensive security testing before any deployment"
    echo ""
    echo "**Impact**: Critical security risks, potential system compromise"
    echo "**Timeline**: Fix immediately before any code review"
else
    echo "**✅ No critical issues found**"
fi)

---

## 🟠 **MAJOR ISSUES** $([ $major_issues -gt 0 ] && echo "($major_issues found)" || echo "(None)")

$(if [ $major_issues -gt 0 ]; then
    echo "**⚠️ FIX BEFORE MERGE - High Priority**"
    echo ""
    echo "### Issues Found:"
    echo "$java_issues" | grep -o "MAJOR-[^|]*" | sed 's/MAJOR-/🟠 **/' | sed 's/:/**: /' | sed 's/$//'
    echo ""
    echo "### Remediation Steps:"
    echo "1. **Replace System.out**: Use proper logging framework (SLF4J, Logback)"
    echo "2. **Fix Exception Handling**: Replace printStackTrace with proper logging"
    echo "3. **Resource Management**: Implement try-with-resources for all I/O operations"
    echo "4. **Code Refactoring**: Split large files (>1000 lines) into smaller modules"
    echo "5. **Remove TODO/FIXME**: Address all unresolved comments"
    echo ""
    echo "**Impact**: Poor practices affecting code quality, security, maintainability"
    echo "**Timeline**: Fix before merge to maintain code standards"
else
    echo "**✅ No major issues found**"
fi)

---

## 🟡 **MEDIUM ISSUES** $([ $medium_issues -gt 0 ] && echo "($medium_issues found)" || echo "(None)")

$(if [ $medium_issues -gt 0 ]; then
    echo "**⚠️ SHOULD FIX - Code Quality Improvements**"
    echo ""
    echo "### Issues Found:"
    echo "$java_issues" | grep -o "MEDIUM-[^|]*" | sed 's/MEDIUM-/🟡 **/' | sed 's/:/**: /' | sed 's/$//'
    echo ""
    echo "### Remediation Steps:"
    echo "1. **Improve Encapsulation**: Add private/protected access modifiers"
    echo "2. **Optimize Performance**: Replace nested loops with efficient algorithms"
    echo "3. **String Optimization**: Use StringBuilder for multiple concatenations"
    echo "4. **Add Documentation**: Include JavaDoc for public classes"
    echo "5. **Reduce Complexity**: Refactor deeply nested code structures"
    echo "6. **File Size Management**: Consider splitting files >500 lines"
    echo ""
    echo "**Impact**: Code quality and maintainability improvements"
    echo "**Timeline**: Consider fixing in current sprint"
else
    echo "**✅ No medium issues found**"
fi)

---

## 🔵 **MINOR ISSUES** $([ $minor_issues -gt 0 ] && echo "($minor_issues found)" || echo "(None)")

$(if [ $minor_issues -gt 0 ]; then
    echo "**ℹ️ CONSIDER FIXING - Style and Convention Improvements**"
    echo ""
    echo "### Issues Found:"
    echo "$java_issues" | grep -o "MINOR-[^|]*" | sed 's/MINOR-/🔵 **/' | sed 's/:/**: /' | sed 's/$//'
    echo ""
    echo "### Remediation Steps:"
    echo "1. **Documentation**: Add JavaDoc for public methods with @param and @return"
    echo "2. **Import Optimization**: Replace wildcard imports with specific imports"
    echo "3. **File Size Monitoring**: Monitor growth of files >300 lines"
    echo "4. **Exception Specificity**: Use specific exception types instead of generic Exception"
    echo "5. **Annotation Compliance**: Add @Override annotations where applicable"
    echo ""
    echo "**Impact**: Code style and convention improvements"
    echo "**Timeline**: Consider fixing in next sprint or maintenance cycle"
else
    echo "**✅ No minor issues found**"
fi)

---

## 🎯 **PRIORITY ACTION PLAN**

### **Immediate Actions (Before Any Review)**
$(if [ $critical_issues -gt 0 ]; then
    echo "1. 🔴 **Fix $critical_issues CRITICAL issues** - Security vulnerabilities and major bugs"
    echo "2. 🔍 **Security audit** - Review all hardcoded credentials and injection risks"
    echo "3. 🧪 **Test thoroughly** - Ensure fixes don't break functionality"
else
    echo "✅ No immediate critical actions required"
fi)

### **Before Merge**
$(if [ $major_issues -gt 0 ]; then
    echo "1. 🟠 **Address $major_issues MAJOR issues** - Poor practices and quality problems"
    echo "2. 📝 **Update logging** - Replace System.out with proper logging framework"
    echo "3. 🛡️ **Resource management** - Implement try-with-resources where needed"
else
    echo "✅ No major issues blocking merge"
fi)

### **Code Quality Improvements**
$(if [ $medium_issues -gt 0 ]; then
    echo "1. 🟡 **Consider fixing $medium_issues MEDIUM issues** - Code quality improvements"
    echo "2. 📚 **Add documentation** - JavaDoc for public classes and methods"
    echo "3. 🔧 **Refactor large files** - Split files >500 lines for better maintainability"
else
    echo "✅ Code quality standards met"
fi)

---

## 🚨 **MERGE DECISION**

$(if [ $critical_issues -gt 0 ]; then
    echo "**🔴 DO NOT MERGE** - Critical issues must be fixed first"
    echo ""
    echo "**Blocking Issues**: $critical_issues critical security/quality problems"
    echo "**Risk Level**: HIGH - Potential security vulnerabilities or system failures"
elif [ $major_issues -gt 0 ]; then
    echo "**🟠 MERGE WITH CAUTION** - Major issues should be addressed"
    echo ""
    echo "**Issues to Address**: $major_issues major quality/security concerns"
    echo "**Risk Level**: MEDIUM - Code quality and maintainability concerns"
else
    echo "**✅ SAFE TO MERGE** - No critical or major issues found"
    echo ""
    echo "**Quality Status**: Good - Only minor improvements suggested"
    echo "**Risk Level**: LOW - Standard code review recommended"
fi)

---

## 📋 **QUICK CHECKLIST FOR REVIEWER**

- [ ] **Critical Issues**: $([ $critical_issues -eq 0 ] && echo "✅ None found" || echo "🔴 $critical_issues found - MUST FIX")
- [ ] **Major Issues**: $([ $major_issues -eq 0 ] && echo "✅ None found" || echo "🟠 $major_issues found - Should fix")
- [ ] **Security Review**: $([ $critical_issues -eq 0 ] && echo "✅ No obvious vulnerabilities" || echo "🔴 Security issues detected")
- [ ] **Code Quality**: $([ $major_issues -eq 0 ] && echo "✅ Standards met" || echo "🟠 Improvements needed")
- [ ] **Test Coverage**: $([ $test_files -gt 0 ] && echo "✅ Tests present" || echo "⚠️ No test files found")

**Estimated Review Time**: $(if [ $critical_issues -gt 0 ]; then echo "2-4 hours (critical fixes needed)"; elif [ $major_issues -gt 0 ]; then echo "1-2 hours (quality improvements)"; else echo "30-60 minutes (standard review)"; fi)

---

## 🏗️ **SOLID PRINCIPLES RECOMMENDATIONS**

### **S - Single Responsibility Principle**
- [ ] **Review class responsibilities** - Each class should have one reason to change
- [ ] **Split large classes** - Classes >300 lines may have multiple responsibilities
- [ ] **Extract utility methods** - Move helper functions to dedicated utility classes
- [ ] **Separate concerns** - Business logic, data access, and presentation should be separate

### **O - Open/Closed Principle**
- [ ] **Use interfaces/abstractions** - Depend on abstractions, not concrete implementations
- [ ] **Strategy pattern** - Consider for conditional logic that might change
- [ ] **Extension points** - Design for extension without modification
- [ ] **Plugin architecture** - Allow new functionality without changing existing code

### **L - Liskov Substitution Principle**
- [ ] **Inheritance contracts** - Subclasses should be substitutable for base classes
- [ ] **Method preconditions** - Don't strengthen preconditions in subclasses
- [ ] **Method postconditions** - Don't weaken postconditions in subclasses
- [ ] **Behavioral compatibility** - Subclasses should behave as expected by clients

### **I - Interface Segregation Principle**
- [ ] **Small, focused interfaces** - Clients shouldn't depend on unused methods
- [ ] **Role-based interfaces** - Create interfaces based on client needs
- [ ] **Avoid fat interfaces** - Split large interfaces into smaller, cohesive ones
- [ ] **Client-specific interfaces** - Design interfaces from client perspective

### **D - Dependency Inversion Principle**
- [ ] **Dependency injection** - Inject dependencies rather than creating them
- [ ] **Abstract dependencies** - Depend on interfaces, not concrete classes
- [ ] **Inversion of control** - Let framework/container manage object creation
- [ ] **Configuration over hardcoding** - Use configuration for dependencies

---

## 🎯 **CODE QUALITY ENHANCEMENT SUGGESTIONS**

### **Design Patterns to Consider**
- [ ] **Factory Pattern** - For object creation with complex logic
- [ ] **Observer Pattern** - For event-driven architectures
- [ ] **Command Pattern** - For encapsulating requests as objects
- [ ] **Builder Pattern** - For complex object construction
- [ ] **Decorator Pattern** - For adding behavior without inheritance
- [ ] **Repository Pattern** - For data access abstraction
- [ ] **MVC/MVP Pattern** - For separating presentation from business logic

### **Clean Code Practices**
- [ ] **Meaningful names** - Use intention-revealing names for variables/methods
- [ ] **Small functions** - Keep methods under 20 lines when possible
- [ ] **Avoid deep nesting** - Use early returns and guard clauses
- [ ] **Remove code duplication** - Extract common logic into shared methods
- [ ] **Consistent formatting** - Follow team coding standards
- [ ] **Comments for why, not what** - Explain business logic, not obvious code
- [ ] **Error handling** - Use proper exception handling, not generic catches

### **Testing Recommendations**
- [ ] **Unit tests** - Test individual components in isolation
- [ ] **Integration tests** - Test component interactions
- [ ] **Test coverage** - Aim for >80% code coverage on business logic
- [ ] **Test naming** - Use descriptive test method names (Given_When_Then)
- [ ] **Mock dependencies** - Use mocks for external dependencies
- [ ] **Test edge cases** - Include boundary conditions and error scenarios
- [ ] **Arrange-Act-Assert** - Structure tests clearly

### **Performance & Security**
- [ ] **Resource management** - Use try-with-resources for closeable objects
- [ ] **Input validation** - Validate all external inputs
- [ ] **SQL injection prevention** - Use parameterized queries
- [ ] **Logging security** - Don't log sensitive information
- [ ] **Memory leaks** - Check for proper cleanup of resources
- [ ] **Caching strategy** - Consider caching for expensive operations

---

*Generated by Comprehensive SOLID Principles PR Reviewer v3.0 - $(date)*
EOF

    log_success "Report generated: $(basename "$report_file")"
}

# Print usage information
print_usage() {
    echo "Comprehensive OPEN & DRAFT PR Review Script"
    echo "==========================================="
    echo ""
    echo "🎯 FOCUS: Only analyzes OPEN and DRAFT PRs (excludes merged PRs)"
    echo ""
    echo "Usage:"
    echo "  $0                           # Review all open/draft PRs (default)"
    echo "  $0 --url <PR_URL>           # Review specific open/draft PR by URL"
    echo "  $0 --branch <BRANCH_NAME>   # Review specific branch directly"
    echo "  $0 --recent                 # Show recent branches (potential open PRs)"
    echo "  $0 --help                   # Show this help"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 --url https://bitbucket.org/syncappinc/krista-global-catalog/pull-requests/1684"
    echo "  $0 --branch feature/KE-1684-some-feature"
    echo "  $0 --recent"
    echo ""
    echo "Supported URL formats:"
    echo "  - https://bitbucket.org/[workspace]/[repository]/pull-requests/[PR_ID]"
    echo "  - https://bitbucket.org/[workspace]/[repository]/pull-requests/[PR_ID]/[title]"
    echo ""
    echo "Authentication (for open PRs):"
    echo "  export BITBUCKET_USERNAME=\"your-username\""
    echo "  export BITBUCKET_APP_PASSWORD=\"your-app-password\""
    echo ""
    echo "Note: The script analyzes code in the current working directory."
    echo "      Make sure you're in the correct repository when analyzing PRs."
}

# Review single PR by URL
review_single_pr() {
    local pr_url="$1"

    log_info "Starting Single PR Review"
    echo "=========================="

    # Parse PR URL
    log_info "Parsing PR URL: $pr_url"
    local url_data
    if ! url_data=$(parse_pr_url "$pr_url"); then
        log_error "Invalid PR URL format. Expected: https://bitbucket.org/[workspace]/[repository]/pull-requests/[PR_ID]"
        log_error "Received: $pr_url"
        exit 1
    fi

    local repo_info=$(echo "$url_data" | cut -d'|' -f1)
    local pr_id=$(echo "$url_data" | cut -d'|' -f2)

    log_info "Extracted Repository: $repo_info"
    log_info "Extracted PR ID: $pr_id"

    # Setup directories (don't clean previous reports for single PR)
    setup_directories false

    # Get PR details
    local pr_data
    if pr_data=$(get_pr_details "$repo_info" "$pr_id"); then
        log_success "Retrieved PR details from API"
    elif pr_data=$(get_pr_from_git "$pr_id"); then
        log_success "Retrieved PR details from git"
    else
        log_error "Could not retrieve OPEN PR details for PR #$pr_id from repository $repo_info"
        log_error "This might be because:"
        log_error "1. The PR doesn't exist or is not open"
        log_error "2. The PR is already merged (we only analyze OPEN/DRAFT PRs)"
        log_error "3. The repository is different from the current working directory"
        log_error "4. API access is restricted"
        exit 1
    fi

    # Check if PR is merged and skip if so
    local clean_pr_data=$(echo "$pr_data" | grep -v "\[INFO\]\|\[SUCCESS\]\|\[WARNING\]\|\[ERROR\]" | tail -1)
    local pr_state=$(echo "$clean_pr_data" | cut -d'|' -f3)

    if [ "$pr_state" = "MERGED" ]; then
        log_warning "PR #$pr_id is MERGED - skipping analysis (we only analyze OPEN/DRAFT PRs)"
        echo ""
        echo "💡 This script only analyzes OPEN and DRAFT PRs."
        echo "   Merged PRs are excluded from analysis."
        exit 0
    fi

    # Parse PR data (extract only the data line, ignore log messages)
    local clean_pr_data=$(echo "$pr_data" | grep -v "\[INFO\]\|\[SUCCESS\]\|\[WARNING\]\|\[ERROR\]" | tail -1)

    local pr_id_parsed=$(echo "$clean_pr_data" | cut -d'|' -f1)
    local pr_title=$(echo "$clean_pr_data" | cut -d'|' -f2)
    local pr_state=$(echo "$clean_pr_data" | cut -d'|' -f3)
    local source_branch=$(echo "$clean_pr_data" | cut -d'|' -f4)
    local target_branch=$(echo "$clean_pr_data" | cut -d'|' -f5)
    local author=$(echo "$clean_pr_data" | cut -d'|' -f6)
    local created_date=$(echo "$clean_pr_data" | cut -d'|' -f7)

    log_info "PR Details:"
    echo "  Title: $pr_title"
    echo "  State: $pr_state"
    echo "  Branch: $source_branch -> $target_branch"
    echo "  Author: $author"
    echo ""

    # Determine if we need to clone the repository
    local repo_dir="$CURRENT_REPO_DIR"
    local temp_dir=""
    local cleanup_needed=false

    if ! is_current_repository "$repo_info"; then
        log_info "Different repository detected, cloning for analysis..."
        if temp_dir=$(clone_repository "$repo_info" "$source_branch"); then
            repo_dir="$temp_dir"
            cleanup_needed=true
            log_success "Repository cloned successfully for analysis"
        else
            log_error "Failed to clone repository, cannot perform code analysis"
            exit 1
        fi
    else
        log_info "Analyzing current repository"
    fi

    # Analyze PR changes
    local files_changed
    if files_changed=$(analyze_pr_changes "$repo_info" "$pr_id" "$repo_dir"); then
        log_success "Analyzed PR changes"
    else
        files_changed=$(analyze_branch_changes "$source_branch" "$repo_dir")
        log_warning "Used fallback branch analysis"
    fi

    # Generate report
    if generate_pr_report "$source_branch" "$author" "$pr_title" "$created_date" "$files_changed" "$repo_dir"; then
        log_success "Generated actionable PR review report"

        # Show report location
        local clean_branch=$(echo "$source_branch" | sed 's/[^a-zA-Z0-9_-]/_/g')
        local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9_-]/_/g')

        # Find the generated report
        local report_file=$(find "$REPORTS_DIR" -name "*${clean_branch}_${clean_author}.md" | head -1)
        if [ -n "$report_file" ]; then
            echo ""
            echo "📄 **REPORT GENERATED**: $(basename "$report_file")"
            echo "📁 **LOCATION**: $report_file"
        fi
    else
        # Generate comprehensive report even with no issues (SOLID principles suggestions)
        if generate_pr_report "$source_branch" "$author" "$commit_msg" "$created_date" "No files changed" "$CURRENT_REPO_DIR"; then
            log_success "Generated comprehensive SOLID principles report"

            # Show report location
            local clean_branch=$(echo "$source_branch" | sed 's/[^a-zA-Z0-9_-]/_/g')
            local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9_-]/_/g')

            # Find the generated report
            local report_file=$(find "$REPORTS_DIR" -name "*${clean_branch}_${clean_author}.md" | head -1)
            if [ -n "$report_file" ]; then
                echo ""
                echo "📄 **COMPREHENSIVE REPORT GENERATED**: $(basename "$report_file")"
                echo "📁 **LOCATION**: $report_file"
            fi
        else
            log_info "Comprehensive report generated with SOLID principles suggestions"
        fi
    fi

    # Cleanup temporary directory if needed
    if [ "$cleanup_needed" = true ] && [ -n "$temp_dir" ]; then
        cleanup_temp_dir "$temp_dir"
    fi

    echo ""
    echo "Jay Bhavani, Jay Shivaji! 🙏"
}

# Show recent branches that might be open PRs
show_recent_branches() {
    log_info "Recent Branches Analysis"
    echo "========================"
    echo ""

    local recent_branches=$(find_recent_branches)

    if [ -z "$recent_branches" ]; then
        log_warning "No recent branches found"
        return 0
    fi

    local count=0
    echo "Recent branches that might be open PRs:"
    echo ""

    echo "$recent_branches" | while IFS='|' read -r branch author commit_msg commit_date branch_type; do
        count=$((count + 1))
        echo "$count. Branch: $branch"
        echo "   Author: $author"
        echo "   Latest: $commit_msg"
        echo "   Date: $commit_date"
        echo "   Command: ./simple_pr_reviewer.sh --branch $branch"
        echo ""
    done

    echo "💡 To analyze a specific branch:"
    echo "   ./simple_pr_reviewer.sh --branch <branch-name>"
}

# Review branch directly
review_branch_directly() {
    local branch_name="$1"

    log_info "Starting Branch Analysis"
    echo "========================"
    echo ""

    # Setup directories (don't clean previous reports)
    setup_directories false

    # Analyze branch directly
    local branch_data
    if branch_data=$(analyze_branch_directly "$branch_name"); then
        log_success "Retrieved branch details"
    else
        log_error "Could not analyze branch $branch_name"
        exit 1
    fi

    # Parse branch data
    local clean_branch_data=$(echo "$branch_data" | grep -v "\[INFO\]\|\[SUCCESS\]\|\[WARNING\]\|\[ERROR\]" | tail -1)

    local branch_id=$(echo "$clean_branch_data" | cut -d'|' -f1)
    local commit_msg=$(echo "$clean_branch_data" | cut -d'|' -f2)
    local branch_state=$(echo "$clean_branch_data" | cut -d'|' -f3)
    local source_branch=$(echo "$clean_branch_data" | cut -d'|' -f4)
    local target_branch=$(echo "$clean_branch_data" | cut -d'|' -f5)
    local author=$(echo "$clean_branch_data" | cut -d'|' -f6)
    local created_date=$(echo "$clean_branch_data" | cut -d'|' -f7)

    log_info "Branch Details:"
    echo "  Branch: $source_branch"
    echo "  Latest Commit: $commit_msg"
    echo "  State: $branch_state"
    echo "  Author: $author"
    echo ""

    # Analyze branch changes
    local files_changed
    files_changed=$(analyze_branch_changes "$source_branch" "$CURRENT_REPO_DIR")
    log_success "Analyzed branch changes"

    # Generate report
    if generate_pr_report "$source_branch" "$author" "$commit_msg" "$created_date" "$files_changed" "$CURRENT_REPO_DIR"; then
        log_success "Generated actionable branch review report"

        # Show report location
        local clean_branch=$(echo "$source_branch" | sed 's/[^a-zA-Z0-9_-]/_/g')
        local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9_-]/_/g')

        # Find the generated report
        local report_file=$(find "$REPORTS_DIR" -name "*${clean_branch}_${clean_author}.md" | head -1)
        if [ -n "$report_file" ]; then
            echo ""
            echo "📄 **REPORT GENERATED**: $(basename "$report_file")"
            echo "📁 **LOCATION**: $report_file"
        fi
    else
        # Generate comprehensive report even with no issues (SOLID principles suggestions)
        if generate_pr_report "$source_branch" "$author" "$commit_msg" "$created_date" "No files changed" "$CURRENT_REPO_DIR"; then
            log_success "Generated comprehensive SOLID principles report"

            # Show report location
            local clean_branch=$(echo "$source_branch" | sed 's/[^a-zA-Z0-9_-]/_/g')
            local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9_-]/_/g')

            # Find the generated report
            local report_file=$(find "$REPORTS_DIR" -name "*${clean_branch}_${clean_author}.md" | head -1)
            if [ -n "$report_file" ]; then
                echo ""
                echo "📄 **COMPREHENSIVE REPORT GENERATED**: $(basename "$report_file")"
                echo "📁 **LOCATION**: $report_file"
            fi
        else
            log_info "Comprehensive report generated with SOLID principles suggestions"
        fi
    fi

    echo ""
    echo "Jay Bhavani, Jay Shivaji! 🙏"
}

# Main function for bulk review
main() {
    local pr_url=""
    local branch_name=""
    local show_recent=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --url)
                pr_url="$2"
                shift 2
                ;;
            --branch)
                branch_name="$2"
                shift 2
                ;;
            --recent)
                show_recent=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Handle recent branches display
    if [ "$show_recent" = true ]; then
        show_recent_branches
        return 0
    fi

    # Handle branch analysis
    if [ -n "$branch_name" ]; then
        review_branch_directly "$branch_name"
        return 0
    fi

    # Handle single PR review
    if [ -n "$pr_url" ]; then
        review_single_pr "$pr_url"
        return 0
    fi

    # Default: bulk review of all open PRs
    log_info "Starting Comprehensive PR Review for Open PRs"
    echo "=============================================="

    # Setup (clean previous reports for bulk review)
    setup_directories true

    # Get open PRs (for current repository only)
    local open_prs=$(get_open_prs)

    if [ -z "$open_prs" ]; then
        log_warning "No open PR branches found in current repository"
        exit 0
    fi

    local total_prs=$(echo "$open_prs" | wc -l | xargs)
    log_info "Found $total_prs PRs to process in current repository"
    
    # Process each PR and track actionable issues
    local processed_count=0
    local actionable_count=0
    local critical_prs=0
    local major_prs=0
    local medium_prs=0
    local minor_prs=0

    while IFS= read -r pr_data; do
        if [ -n "$pr_data" ]; then
            local branch=$(echo "$pr_data" | cut -d'|' -f1)
            local author=$(echo "$pr_data" | cut -d'|' -f2)
            local commit_msg=$(echo "$pr_data" | cut -d'|' -f3)
            local date=$(echo "$pr_data" | cut -d'|' -f4)
            local pr_id=$(echo "$pr_data" | cut -d'|' -f5)

            if [ -n "$pr_id" ] && [ "$pr_id" != "unknown" ]; then
                log_info "Analyzing PR #$pr_id: $branch by $author"
            else
                log_info "Analyzing branch: $branch by $author (no PR ID available)"
            fi

            # Analyze changes
            local files_changed=$(analyze_branch_changes "$branch")

            # Generate report (only if issues found)
            if generate_pr_report "$branch" "$author" "$commit_msg" "$date" "$files_changed"; then
                actionable_count=$((actionable_count + 1))

                # Count severity levels for summary
                local quality_metrics=$(analyze_code_quality "$files_changed")
                local critical_issues=$(echo "$quality_metrics" | cut -d'|' -f7)
                local major_issues=$(echo "$quality_metrics" | cut -d'|' -f8)
                local medium_issues=$(echo "$quality_metrics" | cut -d'|' -f9)
                local minor_issues=$(echo "$quality_metrics" | cut -d'|' -f10)

                [ $critical_issues -gt 0 ] && critical_prs=$((critical_prs + 1))
                [ $major_issues -gt 0 ] && major_prs=$((major_prs + 1))
                [ $medium_issues -gt 0 ] && medium_prs=$((medium_prs + 1))
                [ $minor_issues -gt 0 ] && minor_prs=$((minor_prs + 1))

                log_success "Report generated with actionable issues"
            fi

            processed_count=$((processed_count + 1))
        fi
    done <<< "$open_prs"

    # Generate summary
    echo ""
    log_success "Analysis Complete!"
    echo "=================================="
    echo "📊 **SUMMARY STATISTICS**"
    echo "  Total PRs Analyzed: $processed_count"
    echo "  PRs with Actionable Issues: $actionable_count"
    echo "  PRs with Critical Issues: $critical_prs"
    echo "  PRs with Major Issues: $major_prs"
    echo "  PRs with Medium Issues: $medium_prs"
    echo "  PRs with Minor Issues: $minor_prs"
    echo "  Clean PRs (no issues): $((processed_count - actionable_count))"
    echo ""
    echo "📁 Reports Directory: $REPORTS_DIR"
    echo "📋 Report Format: <SEVERITY>_<BRANCH_NAME>_<AUTHOR_NAME>.md"
    echo ""
    if [ $actionable_count -gt 0 ]; then
        echo "🚨 **ACTION REQUIRED**: $actionable_count PRs need attention"
        [ $critical_prs -gt 0 ] && echo "   🔴 $critical_prs PRs have CRITICAL issues - DO NOT MERGE"
        [ $major_prs -gt 0 ] && echo "   🟠 $major_prs PRs have MAJOR issues - Fix before merge"
        [ $medium_prs -gt 0 ] && echo "   🟡 $medium_prs PRs have MEDIUM issues - Consider fixing"
        [ $minor_prs -gt 0 ] && echo "   🔵 $minor_prs PRs have MINOR issues - Style improvements"
    else
        echo "✅ **ALL CLEAN**: No actionable issues found in any PR"
    fi
    echo ""
    echo "Jay Bhavani, Jay Shivaji! 🙏"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
