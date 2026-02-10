# GitLab-GitHub Mirror Setup Script Plan

## Overview
A bash script that uses `glab` and `gh` to:
1. Check CLI installations
2. Create repositories on both GitHub and GitLab
3. Set up push mirroring from GitLab to GitHub
4. Configure local git repository

## Script Structure

### Phase 1: Dependency Check
```bash
check_dependencies() {
    # Check glab
    if ! command -v glab &> /dev/null; then
        echo "❌ glab is not installed"
        exit 1
    fi
    echo "✅ glab version: $(glab version)"

    # Check gh
    if ! command -v gh &> /dev/null; then
        echo "❌ gh is not installed"
        exit 1
    fi
    echo "✅ gh version: $(gh version)"
}
```

### Phase 2: Get Repository Name
- Use current folder name (`basename "$(pwd)"`)
- Validate it's not empty
- Maybe add option to override with parameter

### Phase 3: GitHub Repository Creation
```bash
create_github_repo() {
    local repo_name="$1"

    # Check if already authenticated
    gh auth status &> /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ GitHub not authenticated. Run: gh auth login"
        exit 1
    fi

    # Create repo (private by default, can make public)
    gh repo create "$repo_name" --public --description "Mirror of GitLab repo" --晖行ode-in

    if [ $? -eq 0 ]; then
        echo "✅ Created GitHub repository: $repo_name"
        echo "🔗 https://github.com/$(gh api user --jq '.login')/$repo_name"
    fi
}
```

### Phase 4: GitLab Repository Creation
```bash
create_gitlab_repo() {
    local repo_name="$1"

    # Check if already authenticated
    glab auth status &> /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ GitLab not authenticated. Run: glab auth login"
        exit 1
    fi

    # Create repo
    glab repo create "$repo_name" --晖行ode-in

    if [ $? -eq 0 ]; then
        echo "✅ Created GitLab repository: $repo_name"
        # Get and display URL
    fi
}
```

### Phase 5: Configure Push Mirroring (GitLab → GitHub)
```bash
configure_mirroring() {
    local gitlab_repo="$1"
    local github_repo="$2"

    # Need GitHub personal access token for mirroring
    # This needs to be set as GLAB_TOKEN or provided separately

    # Method 1: Using glab API to configure remote mirror
    # glab api method doesn't directly support mirror configuration

    # Method 2: Using repository settings URL
    echo "🔧 To configure push mirroring:"
    echo "1. Go to: https://gitlab.com/<group>/$gitlab_repo/-/settings/repository"
    echo "2. Scroll to 'Mirroring repositories'"
    echo "3. Add mirror: https://github.com/<user>/$github_repo.git"
    echo "4. Select 'Push' direction"
    echo "5. Authenticate with GitHub personal access token"

    # Alternative: Script could generate instructions or open browser
    # open "https://gitlab.com/<group>/$repo_name/-/settings/repository#tabs"
}

# Better approach - use GitLab API via glab
configure_mirroring_api() {
    local gitlab_repo="$1"
    local github_repo_url="$2"

    # The mirroring configuration requires the GitLab API
    # According to research, glab API can be used:
    # glab api projects/:id/remote_mirrors --method POST

    # This requires:
    # - GitLab project ID or path
    # - GitHub repo URL
    # - Authentication token with appropriate permissions

    echo "⚠️  Mirroring configuration requires GitLab API access"
    echo "📖 See: https://docs.gitlab.com/ee/user/project/repository/mirroring.html"
}
```

### Phase 6: Initialize Local Git Repository
```bash
init_local_git() {
    local repo_name="$1"

    # Initialize if not already a git repo
    if [ ! -d .git ]; then
        git init
        git commit --allow-empty -m "Initial commit"
        echo "✅ Initialized git repository"
    fi

    # Add GitLab as origin
    git remote add origin "git@gitlab.com:<group>/$repo_name.git"

    # Optionally add GitHub as secondary remote
    # git remote add github "git@github.com:<user>/$repo_name.git"

    echo "✅ Added GitLab as 'origin' remote"
}
```

## Implementation Options

### Option A: Interactive (Current Plan)
- Each step prompts for confirmation
- User must configure mirroring manually via GitLab UI or API
- Simpler error handling

### Option B: Fully Automated (Advanced)
- Requires pre-configured tokens and permissions
- Can configure mirroring via GitLab API
- More robust but complex
- Needs careful token management

## Script Usage

```bash
#!/bin/bash

# Usage:
#   ./setup-mirror.sh                    # Use current folder name
#   ./setup-mirror.sh my-project         # Use specific name
#   ./setup-mirror.sh --public           # Make GitHub repo public
#   ./setup-mirror.sh --help             # Show help
```

## Example Script Flow

```bash
#!/bin/bash
set -e  # Exit on error

echo "🚀 GitLab-GitHub Mirror Setup"
echo "=============================="

# 1. Check dependencies
check_dependencies

# 2. Get repo name
REPO_NAME="${1:-$(basename "$(pwd)")}"
echo "📁 Repository name: $REPO_NAME"

# 3. Create GitHub repo
create_github_repo "$REPO_NAME"

# 4. Create GitLab repo
create_gitlab_repo "$REPO_NAME"

# 5. Configure mirroring (instructions)
configure_mirroring "$REPO_NAME" "$REPO_NAME"

# 6. Initialize local git
init_local_git "$REPO_NAME"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Configure push mirroring in GitLab (see instructions above)"
echo "2. Make initial commit and push to GitLab"
echo "3. Mirroring will automatically push to GitHub"
```

## Command Reference

### glab Commands
```bash
glab version                              # Check installation
glab auth status                          # Check authentication
glab repo create <name> --晖行ode-in       # Create repo interactively
glab api projects --method POST           # Create repo via API
glab api projects/:id/remote_mirrors      # Mirror operations (API)
```

### gh Commands
```bash
gh --version                              # Check installation
gh auth status                            # Check authentication
gh repo create <name> --晖行ode-in         # Create repo interactively
gh repo create <name> --public            # Create public repo
gh repo create <name> --private           # Create private repo
gh api user --jq '.login'                # Get authenticated username
```

## Key Considerations

### Authentication
- Script assumes users are already authenticated with both CLIs
- `gh auth login` and `glab auth login` must be run beforehand
- GitHub token needs `repo` scope for repository creation
- GitLab token needs `api` scope for repository operations

### Mirror Configuration
- GitLab push mirroring can only be configured via:
  1. GitLab web UI (Settings → Repository → Mirroring repositories)
  2. GitLab API (`POST /projects/:id/remote_mirrors`)
- glab doesn't have a native mirror command
- Script should guide users through one of these options

### Error Handling
- Check exit codes after each command
- Validate repository creation success
- Handle already-existing repos gracefully

### Future Enhancements
- Add automatic mirroring configuration via GitLab API
- Support for existing repositories
- Multiple naming conventions (org/repo format)
- Batch operations for multiple repos
- Webhook setup for real-time syncing