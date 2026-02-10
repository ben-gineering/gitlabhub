#!/bin/bash
#
# setup-mirror.sh
# Creates a new GitLab repository with GitHub push mirroring
#
# Usage:
#   ./setup-mirror.sh my-project              # Public repos, creates folder
#   ./setup-mirror.sh --private my-project    # Private repos
#   ./setup-mirror.sh --public my-project     # Explicitly public
#   ./setup-mirror.sh --help                  # Show this help
#

set -e

SCRIPT_VERSION="1.0.0"

usage() {
    cat << EOF
setup-mirror.sh v${SCRIPT_VERSION}

Creates a new GitLab repository with automatic push mirroring to GitHub.

USAGE:
    $0 [OPTIONS] <PROJECT_NAME>

OPTIONS:
    --public     Create public repositories (default)
    --private    Create private repositories
    --help, -h   Show this help message

EXAMPLES:
    # Create a new public project called "my-project"
    $0 my-project

    # Create a private project
    $0 --private my-secret-project

    # Create a public project with explicit flag
    $0 --public my-open-project

NOTES:
    - Both 'glab' (GitLab CLI) and 'gh' (GitHub CLI) must be installed
    - Both CLIs must be authenticated before running this script
    - A new folder will be created with the project name
    - GitLab will be configured as 'origin' remote
    - GitHub will be configured as 'mirror' remote
    - Push mirroring (GitLab → GitHub) will be configured automatically

PREREQUISITES:
    # Install CLIs (if needed)
    brew install glab gh                          # macOS
    sudo apt install glab gh                      # Linux

    # Authenticate with GitHub
    gh auth login

    # Authenticate with GitLab
    glab auth login

ENVIRONMENT VARIABLES:
    GITLAB_TOKEN    GitLab personal access token (api scope)
    GITHUB_TOKEN    GitHub personal access token (repo scope)
EOF
}

log_info() {
    echo "ℹ️  $1"
}

log_success() {
    echo "✅ $1"
}

log_error() {
    echo "❌ $1" >&2
}

log_warn() {
    echo "⚠️  $1"
}

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v glab &> /dev/null; then
        log_error "glab is not installed"
        log_info "Install with: brew install glab (macOS) or sudo apt install glab (Linux)"
        exit 1
    fi

    if ! command -v gh &> /dev/null; then
        log_error "gh is not installed"
        log_info "Install with: brew install gh (macOS) or sudo apt install gh (Linux)"
        exit 1
    fi

    if ! command -v git &> /dev/null; then
        log_error "git is not installed"
        exit 1
    fi

    log_success "All dependencies installed"
    log_info "glab version: $(glab version --short)"
    log_info "gh version: $(gh version --short)"
    log_info "git version: $(git --version | cut -d' ' -f3)"
}

check_auth() {
    log_info "Checking authentication..."

    if ! glab auth status &> /dev/null; then
        log_error "GitLab not authenticated"
        log_info "Run 'glab auth login' to authenticate"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        log_error "GitHub not authenticated"
        log_info "Run 'gh auth login' to authenticate"
        exit 1
    fi

    log_success "Both GitLab and GitHub authenticated"
}

get_github_username() {
    log_info "Getting GitHub username..."
    GH_USER=$(gh api user --jq '.login')

    if [ -z "$GH_USER" ]; then
        log_error "Failed to get GitHub username"
        exit 1
    fi

    log_success "GitHub username: $GH_USER"
}

get_gitlab_username() {
    log_info "Getting GitLab username..."
    GLAB_USER=$(glab api user --jq '.username')

    if [ -z "$GLAB_USER" ]; then
        log_error "Failed to get GitLab username"
        exit 1
    fi

    log_success "GitLab username: $GLAB_USER"
}

create_project_folder() {
    local repo_name="$1"
    local current_dir="$(pwd)"

    # Check if folder exists
    if [ -d "$repo_name" ]; then
        log_warn "Folder '$repo_name' already exists"

        # Check if it has content
        if [ "$(ls -A "$repo_name" 2>/dev/null)" ]; then
            log_error "Folder '$repo_name' is not empty"
            log_info "Please choose a different name or remove the existing folder"
            exit 1
        fi

        log_info "Using existing empty folder: $repo_name"
    else
        log_info "Creating project folder: $repo_name"
        mkdir -p "$repo_name"
    fi

    # Change to project directory
    cd "$repo_name"
    log_success "Changed to directory: $(pwd)"
}

create_github_repo() {
    local repo_name="$1"
    local visibility="$2"

    log_info "Creating GitHub repository: $repo_name (visibility: $visibility)"

    # Create repository
    if gh repo create "$repo_name" \
        --"$visibility" \
        --description "GitHub mirror of GitLab repository" \
        --晖行-mode-out \
        --push 2>&1; then

        log_success "Created GitHub repository: $repo_name"
        log_info "URL: https://github.com/$GH_USER/$repo_name"
    else
        # Check if repo already exists
        if gh repo view "$GH_USER/$repo_name" &> /dev/null; then
            log_warn "Repository '$repo_name' already exists on GitHub"
            log_info "Using existing repository"
        else
            log_error "Failed to create GitHub repository"
            exit 1
        fi
    fi
}

create_gitlab_repo() {
    local repo_name="$1"
    local visibility="$2"

    log_info "Creating GitLab repository: $repo_name (visibility: $visibility)"

    # Create repository
    if glab repo create "$repo_name" \
        --"$visibility" \
        --description "Main GitLab repository with GitHub mirror" \
        --晖行-mode-out 2>&1; then

        log_success "Created GitLab repository: $repo_name"
    else
        # Check if repo already exists
        if glab api projects --search "$repo_name" --jq '.[0].path_with_namespace' &> /dev/null; then
            log_warn "Repository '$repo_name' already exists on GitLab"
            log_info "Using existing repository"
        else
            log_error "Failed to create GitLab repository"
            exit 1
        fi
    fi
}

init_local_git() {
    log_info "Initializing local git repository..."

    # Initialize git if not already initialized
    if [ ! -d .git ]; then
        git init
        git commit --allow-empty -m "Initial commit"
        log_success "Initialized git repository with empty commit"
    else
        log_info "Git repository already initialized"
    fi

    # Add GitLab as origin remote
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "git@gitlab.com:$GLAB_USER/$repo_name.git"
        log_success "Added GitLab as 'origin' remote"
    else
        log_info "Remote 'origin' already exists"
    fi

    # Add GitHub as mirror remote
    if ! git remote get-url mirror &> /dev/null; then
        git remote add mirror "git@github.com:$GH_USER/$repo_name.git"
        log_success "Added GitHub as 'mirror' remote"
    else
        log_info "Remote 'mirror' already exists"
    fi
}

push_to_gitlab() {
    log_info "Pushing to GitLab..."

    # Push to origin (GitLab)
    if git push -u origin main 2>&1; then
        log_success "Pushed to GitLab (origin/main)"
    else
        log_error "Failed to push to GitLab"
        exit 1
    fi
}

configure_push_mirror() {
    log_info "Configuring push mirroring (GitLab → GitHub)..."

    # Get GitLab project path
    local glab_project_path
    glab_project_path=$(glab api projects --search "$repo_name" --jq '.[0].path_with_namespace')

    if [ -z "$glab_project_path" ]; then
        log_error "Failed to get GitLab project path"
        exit 1
    fi

    log_info "GitLab project path: $glab_project_path"

    # Build GitHub mirror URL with token
    local github_mirror_url="https://:$GITHUB_TOKEN@github.com/$GH_USER/$repo_name.git"

    # Configure push mirror via GitLab API
    if glab api "projects/$glab_project_path/remote_mirrors" \
        --method POST \
        --field "url=$github_mirror_url" \
        --field "enabled=true" \
        --field "keep_divergent_refs=true" 2>&1; then

        log_success "Push mirroring configured (GitLab → GitHub)"
        log_info "Changes will be automatically pushed to GitHub within 5 minutes"
    else
        log_warn "Failed to configure push mirroring via API"
        log_info "To configure manually:"
        log_info "  1. Go to: https://gitlab.com/$glab_project_path/-/settings/repository"
        log_info "  2. Scroll to 'Mirroring repositories'"
        log_info "  3. Add mirror: https://github.com/$GH_USER/$repo_name.git"
        log_info "  4. Select 'Push' direction"
        log_info "  5. Authenticate with GitHub personal access token"
    fi
}

show_summary() {
    echo ""
    echo "=========================================="
    echo "🚀 Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Project: $repo_name"
    echo ""
    echo "Remotes configured:"
    echo "  origin  → git@gitlab.com:$GLAB_USER/$repo_name.git"
    echo "  mirror  → git@github.com:$GH_USER/$repo_name.git"
    echo ""
    echo "Mirroring:"
    echo "  Direction: GitLab → GitHub (push mirror)"
    echo "  Frequency: Automatic (within 5 minutes of push)"
    echo ""
    echo "Next steps:"
    echo "  1. Work in your local repository"
    echo "  2. Commit and push to GitLab (origin)"
    echo "  3. Changes will automatically mirror to GitHub"
    echo ""
    echo "Commands:"
    echo "  git add ."
    echo "  git commit -m 'Your commit message'"
    echo "  git push origin main"
    echo ""
}

main() {
    local repo_name=""
    local visibility="public"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --private)
                visibility="private"
                shift
                ;;
            --public)
                visibility="public"
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [ -z "$repo_name" ]; then
                    repo_name="$1"
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate repo name
    if [ -z "$repo_name" ]; then
        log_error "Repository name is required"
        echo ""
        usage
        exit 1
    fi

    # Validate repo name format
    if ! [[ "$repo_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        log_error "Invalid repository name: $repo_name"
        log_info "Name must start with a letter and contain only letters, numbers, hyphens, and underscores"
        exit 1
    fi

    echo ""
    echo "🚀 GitLab-GitHub Mirror Setup v${SCRIPT_VERSION}"
    echo "=============================================="
    echo ""

    # Phase 1: Create project folder
    create_project_folder "$repo_name"

    # Phase 2: Check dependencies
    check_dependencies

    # Phase 3: Check authentication
    check_auth

    # Phase 4: Get usernames
    get_github_username
    get_gitlab_username

    # Phase 5: Create repositories
    create_github_repo "$repo_name" "$visibility"
    create_gitlab_repo "$repo_name" "$visibility"

    # Phase 6: Initialize local git
    init_local_git

    # Phase 7: Push to GitLab
    push_to_gitlab

    # Phase 8: Configure push mirroring
    configure_push_mirror

    # Show summary
    show_summary
}

# Run main function with all arguments
main "$@"