#!/bin/bash
#
# gitmirror.sh
# Creates a Forgejo repository with automatic push mirroring to GitHub and GitLab.
#
# Architecture:
#   Forgejo (primary) → GitHub (push mirror)
#   Forgejo (primary) → GitLab (push mirror)
#
# Forgejo is the source of truth. All pushes go to Forgejo first,
# which automatically mirrors to GitHub and GitLab.
#
# Usage:
#   ./gitmirror.sh my-project                        # public repos, creates folder
#   ./gitmirror.sh --private my-project              # private repos
#   ./gitmirror.sh --public my-project               # explicitly public
#   ./gitmirror.sh --no-github my-project            # skip GitHub mirror
#   ./gitmirror.sh --no-gitlab my-project            # skip GitLab mirror
#   ./gitmirror.sh --help                            # show help
#
# Environment variables:
#   FORGEJO_URL   — base URL of Forgejo instance (default: http://10.20.2.3:3000)
#   FORGEJO_TOKEN — API token for Forgejo (required, or will prompt)
#
# Prerequisites:
#   - gh (GitHub CLI) authenticated: gh auth login
#   - glab (GitLab CLI) authenticated: glab auth login
#   - Forgejo API token with write access (Settings → Applications → Generate New Token)
#

set -e

SCRIPT_VERSION="2.0.0"

# Source .env if it exists (looks in script's directory and current directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for envfile in "${SCRIPT_DIR}/.env" "./.env"; do
    if [ -f "$envfile" ]; then
        # shellcheck disable=SC1090
        set -a
        source "$envfile"
        set +a
        break
    fi
done

# Defaults
FORGEJO_URL="${FORGEJO_URL:-http://10.20.2.3:3000}"
FORGEJO_TOKEN="${FORGEJO_TOKEN:-}"
VISIBILITY="public"
MIRROR_GITHUB=true
MIRROR_GITLAB=true
REPO_NAME=""

usage() {
    cat << EOF
gitmirror.sh v${SCRIPT_VERSION}

Creates a Forgejo repository with automatic push mirroring to GitHub and GitLab.

USAGE:
    $0 [OPTIONS] <PROJECT_NAME>

OPTIONS:
    --public       Create public repositories (default)
    --private      Create private repositories
    --no-github    Skip GitHub mirror
    --no-gitlab    Skip GitLab mirror
    --help, -h     Show this help message

EXAMPLES:
    # Create a new public project mirrored to both GitHub and GitLab
    $0 my-project

    # Create a private project
    $0 --private my-secret-project

    # Create a project mirrored only to GitHub
    $0 --no-gitlab my-project

ENVIRONMENT:
    FORGEJO_URL    Base URL of Forgejo instance (default: http://10.20.2.3:3000)
    FORGEJO_TOKEN  API token for Forgejo (required)

PREREQUISITES:
    # Install CLIs (if needed)
    sudo apt install gh glab                        # Debian/Ubuntu
    sudo pacman -S github-cli glab                  # Arch

    # Authenticate with GitHub (needs 'repo' scope)
    gh auth login

    # Authenticate with GitLab
    glab auth login

    # Create a Forgejo API token:
    #   1. Log into Forgejo
    #   2. Go to Settings → Applications → Generate New Token
    #   3. Grant 'write:repository' and 'read:user' scopes
    #   4. Export it: export FORGEJO_TOKEN=your_token_here

NOTES:
    - Forgejo is the primary repository (source of truth)
    - Push commits to Forgejo; they mirror to GitHub and GitLab automatically
    - The Forgejo instance must be able to reach github.com and gitlab.com
    - Mirror interval defaults to sync on every commit
    - Both 'gh' and 'glab' credentials are reused (no separate tokens needed)
    - A Forgejo API token is required for push mirror configuration

ARCHITECTURE:
    Your machine → Forgejo (primary)
                    ├── GitHub (push mirror)
                    └── GitLab (push mirror)
EOF
}

log_info()    { echo "  $1"; }
log_success() { echo "  $1"; }
log_error()   { echo "  $1" >&2; }
log_warn()    { echo "  $1"; }
log_section() { echo ""; echo "  --- $1 ---"; }

check_dependencies() {
    log_section "Checking dependencies"

    local missing=0

    for cmd in git curl jq; do
        if command -v "$cmd" &> /dev/null; then
            log_success "  $cmd: $(command -v "$cmd")"
        else
            log_error "  $cmd: NOT FOUND"
            ((missing++))
        fi
    done

    if [ "$MIRROR_GITHUB" = true ]; then
        if command -v gh &> /dev/null; then
            log_success "  gh: $(gh --version | head -1)"
        else
            log_error "  gh: NOT FOUND (install with: sudo apt install gh)"
            ((missing++))
        fi
    fi

    if [ "$MIRROR_GITLAB" = true ]; then
        if command -v glab &> /dev/null; then
            log_success "  glab: $(glab version 2>&1 | head -1)"
        else
            log_error "  glab: NOT FOUND (install with: sudo apt install glab)"
            ((missing++))
        fi
    fi

    if [ "$missing" -gt 0 ]; then
        log_error "  Missing $missing dependency(ies)"
        exit 1
    fi

    log_success "  All dependencies installed"
}

check_auth() {
    log_section "Checking authentication"

    # Forgejo token
    if [ -z "$FORGEJO_TOKEN" ]; then
        log_error "  FORGEJO_TOKEN is not set"
        log_info "  Create a token at: ${FORGEJO_URL}/user/settings/applications"
        log_info "  Then: export FORGEJO_TOKEN=your_token"
        exit 1
    fi

    # Verify Forgejo token
    local forgejo_user
    forgejo_user=$(curl -sf -H "Authorization: token ${FORGEJO_TOKEN}" \
        "${FORGEJO_URL}/api/v1/user" 2>/dev/null | jq -r '.login' 2>/dev/null || echo "")

    if [ -z "$forgejo_user" ] || [ "$forgejo_user" = "null" ]; then
        log_error "  Forgejo: authentication failed (invalid token?)"
        exit 1
    fi
    log_success "  Forgejo: authenticated as @${forgejo_user}"
    FORGEJO_USER="$forgejo_user"

    # GitHub
    if [ "$MIRROR_GITHUB" = true ]; then
        if ! gh auth status &> /dev/null; then
            log_error "  GitHub: not authenticated (run: gh auth login)"
            exit 1
        fi
        GH_USER=$(gh api user 2>/dev/null | jq -r '.login')
        log_success "  GitHub: authenticated as @${GH_USER}"
    fi

    # GitLab
    if [ "$MIRROR_GITLAB" = true ]; then
        if ! glab auth status &> /dev/null; then
            log_error "  GitLab: not authenticated (run: glab auth login)"
            exit 1
        fi
        GLAB_USER=$(glab api user 2>/dev/null | jq -r '.username')
        log_success "  GitLab: authenticated as @${GLAB_USER}"
    fi
}

create_project_folder() {
    log_section "Creating project folder"

    if [ -d "$REPO_NAME" ]; then
        if [ -d "$REPO_NAME/.git" ]; then
            log_warn "  Folder '$REPO_NAME' already exists and is a git repository"
        else
            log_warn "  Folder '$REPO_NAME' already exists (no .git directory)"
        fi
        log_info "  Using existing folder: $REPO_NAME"
    else
        log_info "  Creating: $REPO_NAME"
        mkdir -p "$REPO_NAME"
    fi

    cd "$REPO_NAME"
    log_success "  Working directory: $(pwd)"
}

create_forgejo_repo() {
    log_section "Creating Forgejo repository"

    local private_flag="false"
    [ "$VISIBILITY" = "private" ] && private_flag="true"

    # Check if repo already exists
    local existing
    existing=$(curl -sf -H "Authorization: token ${FORGEJO_TOKEN}" \
        "${FORGEJO_URL}/api/v1/repos/${FORGEJO_USER}/${REPO_NAME}" 2>/dev/null || echo "")

    if [ -n "$existing" ] && [ "$(echo "$existing" | jq -r '.full_name' 2>/dev/null)" != "null" ]; then
        log_warn "  Repository '${FORGEJO_USER}/${REPO_NAME}' already exists on Forgejo"
        log_info "  URL: ${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}"
        return 0
    fi

    # Create repo via API
    local response
    response=$(curl -sf -X POST \
        -H "Authorization: token ${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"${REPO_NAME}\", \"private\": ${private_flag}, \"description\": \"Primary repository with mirrors\", \"auto_init\": false}" \
        "${FORGEJO_URL}/api/v1/user/repos" 2>&1)

    if echo "$response" | jq -e '.full_name' &>/dev/null; then
        log_success "  Created: ${FORGEJO_USER}/${REPO_NAME}"
        log_info "  URL: ${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}"
    else
        log_error "  Failed to create Forgejo repository"
        log_error "  Response: $response"
        exit 1
    fi
}

create_github_repo() {
    [ "$MIRROR_GITHUB" = true ] || return 0
    log_section "Creating GitHub repository"

    if gh repo view "${GH_USER}/${REPO_NAME}" &> /dev/null; then
        log_warn "  Repository '${REPO_NAME}' already exists on GitHub"
        log_info "  URL: https://github.com/${GH_USER}/${REPO_NAME}"
        return 0
    fi

    local visibility_flag="--public"
    [ "$VISIBILITY" = "private" ] && visibility_flag="--private"

    if gh repo create "$REPO_NAME" \
        $visibility_flag \
        --description "Mirror of Forgejo repository" 2>&1; then
        log_success "  Created: ${GH_USER}/${REPO_NAME}"
        log_info "  URL: https://github.com/${GH_USER}/${REPO_NAME}"
    else
        if gh repo view "${GH_USER}/${REPO_NAME}" &> /dev/null; then
            log_warn "  Repository appears to exist now"
            log_info "  URL: https://github.com/${GH_USER}/${REPO_NAME}"
        else
            log_error "  Failed to create GitHub repository"
            exit 1
        fi
    fi
}

create_gitlab_repo() {
    [ "$MIRROR_GITLAB" = true ] || return 0
    log_section "Creating GitLab repository"

    local encoded_path="${GLAB_USER}%2F${REPO_NAME}"

    if glab api "projects/${encoded_path}" >/dev/null 2>&1; then
        log_warn "  Repository '${REPO_NAME}' already exists on GitLab"
        log_info "  URL: https://gitlab.com/${GLAB_USER}/${REPO_NAME}"
        return 0
    fi

    local visibility_flag="--public"
    [ "$VISIBILITY" = "private" ] && visibility_flag="--private"

    if glab repo create "$REPO_NAME" \
        $visibility_flag \
        --description "Mirror of Forgejo repository" \
        --skipGitInit 2>&1; then
        log_success "  Created: ${GLAB_USER}/${REPO_NAME}"
        log_info "  URL: https://gitlab.com/${GLAB_USER}/${REPO_NAME}"
    else
        if glab api "projects/${encoded_path}" >/dev/null 2>&1; then
            log_warn "  Repository appears to exist now"
        else
            log_error "  Failed to create GitLab repository"
            exit 1
        fi
    fi
}

init_local_git() {
    log_section "Initializing local git"

    if [ ! -d .git ]; then
        git init
        git commit --allow-empty -m "Initial commit"
        log_success "  Initialized with empty commit"
    else
        log_info "  Existing git repository detected; not re-initializing"
    fi

    # Set Forgejo as origin
    local forgejo_url="${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}.git"
    # For SSH, use the forgejo SSH host alias from ~/.ssh/config if available
    local forgejo_ssh="git@${FORGEJO_URL#http://}:${FORGEJO_USER}/${REPO_NAME}.git"
    # Use SSH if port 22 is available, otherwise use HTTP with token
    local desired_origin="${forgejo_ssh}"

    local current_origin
    current_origin=$(git remote get-url origin 2>/dev/null || true)

    if [ -z "$current_origin" ]; then
        git remote add origin "$desired_origin"
        log_success "  Added Forgejo as 'origin': $desired_origin"
    elif [ "$current_origin" = "$desired_origin" ]; then
        log_info "  'origin' already points to Forgejo"
    else
        log_warn "  'origin' exists and points to: $current_origin"
        log_info "  Intended Forgejo origin: $desired_origin"
        printf "  Overwrite 'origin' with Forgejo remote? [y/N] "
        read -r answer
        case "$answer" in
            [yY][eE][sS]|[yY])
                git remote set-url origin "$desired_origin"
                log_success "  Updated 'origin' to Forgejo"
                ;;
            *)
                log_error "  Aborting: existing 'origin' left unchanged"
                exit 1
                ;;
        esac
    fi
}

push_to_forgejo() {
    log_section "Pushing to Forgejo"

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

    if git push -u origin "$current_branch" 2>&1; then
        log_success "  Pushed to Forgejo (origin/${current_branch})"
    else
        log_error "  Failed to push to Forgejo"
        log_info "  Check that your SSH key is added to Forgejo"
        exit 1
    fi
}

configure_github_push_mirror() {
    [ "$MIRROR_GITHUB" = true ] || return 0
    log_section "Configuring push mirror: Forgejo → GitHub"

    local github_token
    github_token=$(gh auth token 2>/dev/null || true)

    if [ -z "$github_token" ]; then
        log_error "  Failed to obtain GitHub token from 'gh auth token'"
        return 1
    fi

    local mirror_url="https://${GH_USER}:${github_token}@github.com/${GH_USER}/${REPO_NAME}.git"

    local response
    response=$(curl -sf -X POST \
        -H "Authorization: token ${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"remote_address\": \"${mirror_url}\", \"remote_username\": \"${GH_USER}\", \"remote_password\": \"${github_token}\", \"interval\": \"\", \"sync_on_commit\": true}" \
        "${FORGEJO_URL}/api/v1/repos/${FORGEJO_USER}/${REPO_NAME}/push_mirrors" 2>&1)

    if echo "$response" | jq -e '.remote_address' &>/dev/null; then
        log_success "  Push mirror configured: Forgejo → GitHub"
        log_info "  Commits will sync to GitHub automatically"
    else
        log_warn "  Failed to configure push mirror via API"
        log_error "  Response: $response"
        log_info "  To configure manually:"
        log_info "    1. Go to: ${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}/settings"
        log_info "    2. Find 'Mirror Settings'"
        log_info "    3. Add push mirror: https://github.com/${GH_USER}/${REPO_NAME}.git"
        log_info "    4. Authenticate with GitHub username + token"
    fi
}

configure_gitlab_push_mirror() {
    [ "$MIRROR_GITLAB" = true ] || return 0
    log_section "Configuring push mirror: Forgejo → GitLab"

    local gitlab_token
    gitlab_token=$(glab auth status 2>&1 | grep -oP 'token: \K\S+' || true)

    # Try alternative method to get glab token
    if [ -z "$gitlab_token" ]; then
        # glab stores token in config
        gitlab_token=$(grep -oP 'token:\s*\K\S+' ~/.config/glab-cli/config.yml 2>/dev/null | head -1 || true)
    fi

    if [ -z "$gitlab_token" ]; then
        log_error "  Failed to obtain GitLab token from glab"
        log_info "  Ensure you are logged in with: glab auth login"
        return 1
    fi

    local mirror_url="https://${GLAB_USER}:${gitlab_token}@gitlab.com/${GLAB_USER}/${REPO_NAME}.git"

    local response
    response=$(curl -sf -X POST \
        -H "Authorization: token ${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"remote_address\": \"${mirror_url}\", \"remote_username\": \"${GLAB_USER}\", \"remote_password\": \"${gitlab_token}\", \"interval\": \"\", \"sync_on_commit\": true}" \
        "${FORGEJO_URL}/api/v1/repos/${FORGEJO_USER}/${REPO_NAME}/push_mirrors" 2>&1)

    if echo "$response" | jq -e '.remote_address' &>/dev/null; then
        log_success "  Push mirror configured: Forgejo → GitLab"
        log_info "  Commits will sync to GitLab automatically"
    else
        log_warn "  Failed to configure push mirror via API"
        log_error "  Response: $response"
        log_info "  To configure manually:"
        log_info "    1. Go to: ${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}/settings"
        log_info "    2. Find 'Mirror Settings'"
        log_info "    3. Add push mirror: https://gitlab.com/${GLAB_USER}/${REPO_NAME}.git"
        log_info "    4. Authenticate with GitLab username + token"
    fi
}

show_summary() {
    echo ""
    echo "  =========================================="
    echo "  Setup Complete!"
    echo "  =========================================="
    echo ""
    echo "  Project: $REPO_NAME"
    echo ""
    echo "  Primary:"
    echo "    origin  → ${FORGEJO_URL}/${FORGEJO_USER}/${REPO_NAME}.git"
    echo ""
    echo "  Mirrors:"
    if [ "$MIRROR_GITHUB" = true ]; then
        echo "    GitHub  → https://github.com/${GH_USER}/${REPO_NAME}"
    fi
    if [ "$MIRROR_GITLAB" = true ]; then
        echo "    GitLab  → https://gitlab.com/${GLAB_USER}/${REPO_NAME}"
    fi
    echo ""
    echo "  Architecture:"
    echo "    Your machine → Forgejo (primary)"
    [ "$MIRROR_GITHUB" = true ] && echo "                    ├── GitHub (push mirror)"
    [ "$MIRROR_GITLAB" = true ] && echo "                    └── GitLab (push mirror)"
    echo ""
    echo "  Workflow:"
    echo "    1. Work in your local repository"
    echo "    2. Commit and push to Forgejo (origin)"
    echo "    3. Changes mirror to GitHub/GitLab automatically"
    echo ""
    echo "  Commands:"
    echo "    git add ."
    echo "    git commit -m 'Your commit message'"
    echo "    git push origin main"
    echo ""
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --private)
                VISIBILITY="private"
                shift
                ;;
            --public)
                VISIBILITY="public"
                shift
                ;;
            --no-github)
                MIRROR_GITHUB=false
                shift
                ;;
            --no-gitlab)
                MIRROR_GITLAB=false
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
                if [ -z "$REPO_NAME" ]; then
                    REPO_NAME="$1"
                else
                    log_error "Unexpected argument: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$REPO_NAME" ]; then
        log_error "Repository name is required"
        echo ""
        usage
        exit 1
    fi

    if ! [[ "$REPO_NAME" =~ ^[a-zA-Z][a-zA-Z0-9_.-]*$ ]]; then
        log_error "Invalid repository name: $REPO_NAME"
        log_info "Must start with a letter, contain only letters, numbers, hyphens, underscores, dots"
        exit 1
    fi

    echo ""
    echo "  gitmirror v${SCRIPT_VERSION}"
    echo "  Forgejo → GitHub + GitLab push mirroring"
    echo "  =========================================="
    echo ""

    check_dependencies
    check_auth
    create_project_folder
    create_forgejo_repo
    create_github_repo
    create_gitlab_repo
    init_local_git
    push_to_forgejo
    configure_github_push_mirror
    configure_gitlab_push_mirror
    show_summary
}

main "$@"
