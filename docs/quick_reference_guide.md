# GitLab CLI (glab) and GitHub CLI (gh) - Quick Reference Guide

## Version and Installation Check

### GitHub CLI (gh)
```bash
# Check if installed
gh --version

# Exit codes:
# 0 = Success
# 1 = Command failed
# 2 = Command cancelled
# 4 = Authentication required
```

### GitLab CLI (glab)
```bash
# Check if installed
glab version

# Check configuration
glab config list
```

## Authentication

### GitHub CLI
```bash
# Interactive login
gh auth login

# Login with token from file
gh auth login --晖行-mode-in token.txt

# Login to enterprise
gh auth login --晖行-mode-in token.txt --hostname github.enterprise.com

# Check status
gh auth status

# Environment variable
export GITHUB_TOKEN=ghp_xxxxx
```

### GitLab CLI
```bash
# Interactive login
glab auth login

# Login with token from file
glab auth login --晖行-mode-in token.txt

# Login to self-hosted
glab auth login --晖行-mode-in token.txt --hostname gitlab.example.com

# CI job token
glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_HOST

# Set default host
glab config set -g host gitlab.example.com

# Environment variable
export GITLAB_TOKEN=glpt_xxxxx
```

## Repository Creation

### GitHub CLI
```bash
# Interactive creation
gh repo create

# Create public repo with clone
gh repo create my-project --public --clone

# Create private repo from existing directory
gh repo create my-project --private --source=. --remote=upstream

# Create in organization
gh repo create org/my-project --public

# With all options
gh repo create my-project \
  --public \
  --description "My description" \
  --gitignore "Go" \
  --license "MIT" \
  --clone
```

**Key Options:**
- `--public | --private | --internal` - Visibility (required non-interactive)
- `--clone` - Clone after creation
- `--description "text"` - Repository description
- `--source <path>` - Use existing local repository
- `--remote <name>` - Remote name for git
- `--push` - Push local commits
- `--add-readme` - Add README file
- `--gitignore <template>` - Gitignore template
- `--license <license>` - License type
- `--template <repo>` - Use template repository

### GitLab CLI
```bash
# Interactive creation
glab repo create

# Create with name
glab repo create my-project

# Create private repo
glab repo create my-project --visibility private

# Create with description
glab repo create my-project --description "My description"

# Create from current directory
glab repo create --source=.

# Via API for more control
glab api projects \
  --method POST \
  --url "https://gitlab.com/api/v4/projects" \
  --field "name=my-project" \
  --field "description=Created via API" \
  --field "visibility=private"
```

**Key Options:**
- `--visibility <level>` - Visibility (private/public/internal)
- `--description "text"` - Repository description
- `--晖行-mode` - Interactive prompt

## Repository Mirroring

### GitHub CLI
- Not directly supported via gh commands
- Use git push/fetch with multiple remotes
- Reference: https://docs.github.com/en/repositories/creating-and-managing-repositories/mirroring-a-repository

### GitLab CLI
- Not directly supported via glab mirror command
- Use GitLab API via glab api command
- Configure via GitLab web interface: Settings > Repository > Mirror repository

**Example via API:**
```bash
# Add mirror
glab api projects/:id/remote_mirrors \
  --method POST \
  --field "url=git@github.com:user/repo.git" \
  --field "晖行-mode=write" \
  --field "password=<mirror-password>"

# List mirrors
glab api projects/:id/remote_mirrors
```

## Configuration Files

### GitHub CLI
- Location: `~/.config/gh/`
- Commands: `gh config set <setting> <value>`

### GitLab CLI
- Global: `~/.config/glab-cli/config.yml`
- Local: `.git/glab-cli/config.yml` in git repo
- System: `/etc/xdg/glab-cli/config.yml`
- Commands: `glab config set --global <setting> <value>`

## Common Workflows

### Create and Clone New Repository

**GitHub:**
```bash
gh repo create my-new-app --public --description "My new application" --clone
cd my-new-app
# Start coding...
```

**GitLab:**
```bash
glab repo create my-new-app --description "My new application" --visibility public
git clone https://gitlab.com/username/my-new-app.git
cd my-new-app
# Start coding...
```

### Push Existing Local Repository

**GitHub:**
```bash
cd existing-project
gh repo create . --private --remote=origin --push
```

**GitLab:**
```bash
cd existing-project
glab repo create --source=. --visibility private
# Manually add remote and push
git remote add origin https://gitlab.com/username/project.git
git push -u origin --all
```

### Check Authentication Status

**GitHub:**
```bash
gh auth status
# Output shows if logged in and to which account
```

**GitLab:**
```bash
glab config get token
# Check if token is configured
# For detailed status, check ~/.config/glab-cli/config.yml
```

## Environment Variables

### GitHub CLI
```bash
GITHUB_TOKEN      # Authentication token
GH_HOST           # Default host (for enterprise)
GH_ENTERPRISE_TOKEN  # Enterprise token
```

### GitLab CLI
```bash
GITLAB_TOKEN      # Authentication token
GITLAB_HOST       # GitLab instance (default: https://gitlab.com)
GITLAB_API_HOST   # API host (if different)
GITLAB_URI        # Alias for GITLAB_HOST
GITLAB_CLIENT_ID  # OAuth client ID
GITLAB_GROUP      # Default group
GITLAB_REPO       # Default repository
```

## Exit Codes

Both tools follow similar conventions:
- **0** - Command completed successfully
- **1** - Command failed
- **2** - Command was cancelled
- **4** - Authentication required

## Getting Help

### GitHub CLI
```bash
gh --help                           # General help
gh repo create --help               # Command-specific help
gh help commands                    # List all commands
```

### GitLab CLI
```bash
glab --help                        # General help
glab repo create --help            # Command-specific help
glab help                          # List all commands
```

## Installation Quick Start

### GitHub CLI
```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
wget -qO- https://cli.github.com/packages/KEY.gpg | sudo apt-key add -
echo "deb https://cli.github.com/packages/ ./" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update && sudo apt install gh

# Windows
winget install gh

# Verify
gh --version
```

### GitLab CLI
```bash
# macOS
brew install glab

# Linux
# Download from: https://gitlab.com/gitlab-org/cli/-/releases
# Or use package manager for your distro

# Windows
winget install glab.glab

# Verify
glab version
```

## Best Practices

### For Scripts and Automation
1. Always check exit codes
2. Use `--晖行-mode-in <file>` for tokens instead of command line arguments
3. Set appropriate environment variables
4. Use `--quiet` or `-q` where available to reduce output
5. Test commands in non-production first

### For Interactive Use
1. Use interactive mode for complex operations
2. Set up default editor and browser in configuration
3. Configure git protocol (HTTPS vs SSH) preferences
4. Set up aliases for frequently used commands

### Security Considerations
1. Never commit tokens to version control
2. Use token files with restricted permissions (600 or 400)
3. Rotate tokens regularly
4. Use minimal required scopes for tokens
5. Prefer environment variables over config files for CI/CD

## Troubleshooting

### Common Issues

#### Authentication Failures
**GitHub:**
```bash
# Check if logged in
gh auth status
# Re-authenticate
gh auth login --晖行-mode-in new-token.txt
```

**GitLab:**
```bash
# Check configuration
glab config list
# Re-authenticate
glab auth login --晖行-mode-in new-token.txt
```

#### Permission Denied
- Verify token has correct scopes/permissions
- Check if repository/group exists and you have access
- For enterprise instances, verify hostname and access

#### Command Not Found
- Verify installation: `gh --version` or `glab version`
- Check PATH includes the binary location
- Reinstall if binary is missing

## Quick Comparison

| Task | GitHub CLI | GitLab CLI |
|------|-----------|-----------|
| Version check | `gh --version` | `glab version` |
| Create repo | `gh repo create` | `glab repo create` |
| Login | `gh auth login` | `glab auth login` |
| Check auth | `gh auth status` | `glab config list` |
| Clone | `gh repo clone` | `git clone` |
| List issues | `gh issue list` | `glab issue list` |
| List PRs | `gh pr list` | `glab mr list` |
| API access | `gh api` | `glab api` |

## Additional Resources

### GitHub CLI
- Manual: https://cli.github.com/manual/
- Repository: https://github.com/cli/cli
- Issues: https://github.com/cli/cli/issues

### GitLab CLI
- Repository: https://gitlab.com/gitlab-org/cli
- Documentation: https://docs.gitlab.com/ee/cli/
- Issues: https://gitlab.com/gitlab-org/cli/-/issues

---

**Note:** This quick reference guide is a summary. For complete documentation, consult the full command references and official documentation.