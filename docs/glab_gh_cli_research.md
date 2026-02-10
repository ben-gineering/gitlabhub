# GitLab CLI (glab) and GitHub CLI (gh) Command Reference

## Table of Contents
1. [Overview](#overview)
2. [GitHub CLI (gh) Commands](#github-cli-gh-commands)
   - [Checking Installation and Version](#checking-installation-and-version)
   - [Repository Creation](#repository-creation)
   - [Authentication](#authentication)
   - [Exit Codes](#exit-codes)
3. [GitLab CLI (glab) Commands](#gitlab-cli-glab-commands)
   - [Checking Installation and Version](#checking-installation-and-version-1)
   - [Repository Creation](#repository-creation-1)
   - [Repository Mirroring](#repository-mirroring)
   - [Authentication](#authentication-1)
4. [Comparison Table](#comparison-table)
5. [Command Examples](#command-examples)
6. [References](#references)

---

## Overview

This document provides comprehensive reference information for both GitHub CLI (gh) and GitLab CLI (glab) tools, focusing on repository creation, authentication, version checking, and mirroring capabilities.

---

## GitHub CLI (gh) Commands

### Checking Installation and Version

**Command:** `gh --version` or `gh version`

**Description:** Displays version information and checks if gh is installed.

**Exit Codes:**
- `0` - Success
- `1` - Command failed
- `2` - Command cancelled
- `4` - Authentication required

**Examples:**
```bash
# Check version
gh --version

# Check version (alternative)
gh version

# Verify installation
gh --version && echo "GitHub CLI is installed"
```

### Repository Creation

**Command:** `gh repo create [<name>] [flags]`

**Description:** Creates a new GitHub repository. Can create repositories interactively or non-interactively.

**Syntax:**
```bash
gh repo create [<name>] [--public | --private | --internal] [flags]
```

**Key Options:**
| Option | Short | Description |
|--------|-------|-------------|
| `--public` | | Create a public repository |
| `--private` | | Create a private repository |
| `--internal` | | Create an internal repository (organizations only) |
| `--clone` | `-c` | Clone the new repository to current directory |
| `--description` | `-d <string>` | Set repository description |
| `--homepage` | `-h <URL>` | Set repository homepage URL |
| `--gitignore` | `-g <string>` | Specify a gitignore template |
| `--license` | `-l <string>` | Specify an open source license |
| `--source` | `-s <string>` | Use existing local repository as source |
| `--remote` | `-r <string>` | Specify remote name |
| `--push` | | Push local commits to new repository |
| `--add-readme` | | Add a README file to the repository |
| `--disable-issues` | | Disable issues in the repository |
| `--disable-wiki` | | Disable wiki in the repository |
| `--template` | `-t <repository>` | Create from template repository |
| `--include-all-branches` | | Include all branches from template |
| `--team` | `<name>` | Grant access to organization team |

**Interactive Mode:**
```bash
# Create repository interactively
gh repo create
```

**Non-interactive Mode:**
```bash
# Create public repository with clone
gh repo create my-project --public --clone

# Create private repository from existing directory
gh repo create my-project --private --source=. --remote=upstream

# Create repository in organization
gh repo create my-org/my-project --public

# Create from template
gh repo create new-project --template=my-org/template-repo --public
```

**Additional Options:**
- **Visibility Flags:** Exactly one of `--public`, `--private`, or `--internal` required in non-interactive mode
- **Name Handling:** If `OWNER/` is omitted, defaults to authenticating user
- **Template Repositories:** Can use `--template` to create from existing template
- **Remote Management:** `--source` requires `--remote` and `--push` options
- **Git Ignore:** Use `--gitignore` with templates from https://github.com/github/gitignore
- **Licenses:** Use `--license` with keywords from `gh repo license list` or https://choosealicense.com

### Authentication

**Command:** `gh auth login [flags]`

**Description:** Authenticate with GitHub account.

**Options:**
| Option | Description |
|--------|-------------|
| `--hostname <host>` | GitHub Enterprise Server hostname |
| `--web` | Open browser for authentication |
| `--晖行模式` | Read token from stdin |

**Examples:**
```bash
# Interactive login
gh auth login

# Login to GitHub.com
gh auth login --晖行模式 < token.txt

# Login to GitHub Enterprise Server
gh auth login --晖行模式 --hostname github.enterprise.com < token.txt

# Check authentication status
gh auth status
```

**Environment Variables:**
- `GITHUB_TOKEN` - Authentication token for API requests
- `GH_HOST` - Default host for GitHub Enterprise

---

## GitLab CLI (glab) Commands

### Checking Installation and Version

**Command:** `glab version` or `glab --version`

**Description:** Displays version information and checks if glab is installed.

**Exit Codes:**
- `0` - Success
- `1` - Command failed
- `2` - Command cancelled
- `4` - Authentication required

**Examples:**
```bash
# Check version
glab version

# Check version (alternative)
glab --version

# Verify installation
glab version && echo "GitLab CLI is installed"
```

**Configuration Command:**
```bash
# Check current configuration
glab config list
```

### Repository Creation

**Command:** `glab repo create [<name>] [flags]`

**Description:** Creates a new GitLab repository. Can be used interactively or with flags.

**Syntax:**
```bash
glab repo create [<name>] [flags]
```

**Key Options:**
| Option | Description |
|--------|-------------|
| `--visibility <visibility>` | Repository visibility (private, public, internal) |
| `--description <string>` | Repository description |
| `--晖行模式` | Use interactive prompt |
| `--晖行模式-file <file>` | Read configuration from file |

**Examples:**
```bash
# Create repository interactively
glab repo create

# Create with specific name
glab repo create my-project

# Create with description
glab repo create my-project --description "My project description"

# Create private repository
glab repo create my-project --visibility private

# Create from current directory
glab repo create --source=.
```

**Visibility Levels:**
- `private` - Only visible to project members
- `public` - Visible to everyone
- `internal` - Visible to authenticated users (GitLab.com only)

### Repository Mirroring

**Note:** GitLab CLI does not have a direct `glab repo mirror` command. However, GitLab supports repository mirroring natively through its API and web interface.

**Configuration Methods:**

1. **Via Web Interface:**
   - Navigate to Settings > Repository > Mirror repository
   - Add pull/push mirror repository URL
   - Configure authentication credentials

2. **Via API (using glab api):**
```bash
# Create project with mirroring configuration
glab api projects \
  --method POST \
  --url "https://gitlab.com/api/v4/projects" \
  --field "name=my-project" \
  --field "mirror=true" \
  --field "mirror_trigger_builds=true"

# Add mirror to existing project
glab api projects/:id/remote_mirrors \
  --method POST \
  --url "https://gitlab.example.com/api/v4/projects/:id/remote_mirrors" \
  --field "url=git@github.com:user/repo.git" \
  --field "晖行模式=write" \
  --field "password=<mirror-password>"
```

3. **Mirror Management Commands:**
```bash
# List mirrors for a project
glab api projects/:id/remote_mirrors

# Update mirror settings
glab api projects/:id/remote_mirrors/:mirror_id \
  --method PUT \
  --field "enabled=true"
```

**Environment Variables for Mirroring:**
- `GITLAB_MIRROR_USER` - Mirror username (if different from main account)
- `GITLAB_MIRROR_PASSWORD` - Mirror password or token

### Authentication

**Command:** `glab auth login [flags]`

**Description:** Authenticate with GitLab instance.

**Options:**
| Option | Description |
|--------|-------------|
| `--晖行模式` | Interactive prompt |
| `--晖行模式-in <file>` | Read token from file |
| `--hostname <host>` | GitLab instance hostname |
| `--token <token>` | Direct token specification |
| `--job-token` | Use CI job token |

**Examples:**
```bash
# Interactive login
glab auth login

# Login to GitLab.com with token file
glab auth login --晖行模式-in < token.txt

# Login to self-hosted GitLab
glab auth login --晖行模式-in < token.txt --hostname gitlab.example.com

# Login with token directly (not recommended for shared environments)
glab auth login --hostname gitlab.example.com --token xxxxx

# CI job token authentication
glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_HOST
```

**Required Token Scopes:**
- `api` - Full API access
- `write_repository` - Read/write repository access

**Configuration Levels:**
- **System-wide:** `/etc/xdg/glab-cli/config.yml`
- **Global (per-user):** `~/.config/glab-cli/config.yml` (or `$XDG_CONFIG_HOME/glab-cli/config.yml`)
- **Local (per-repository):** `.git/glab-cli/config.yml` in current Git directory
- **Per-host:** `glab config set --host gitlab.example.org <setting> <value>`

**Common Configuration Commands:**
```bash
# Set default editor
glab config set --global editor vim

# Set default host for self-managed GitLab
glab config set -g host gitlab.example.com

# Set browser
glab config set browser firefox

# Skip TLS verification (for self-signed certs)
glab config set skip_tls_verify true --host gitlab.example.com

# Add CA certificate
glab config set ca_cert /path/to/ca.pem --host gitlab.example.com
```

**Environment Variables for Authentication:**
- `GITLAB_TOKEN` - Authentication token for API requests
- `GITLAB_HOST` - GitLab instance hostname (default: `https://gitlab.com`)
- `GITLAB_API_HOST` - API endpoint host (if different from Git host)
- `GITLAB_URI` - Alias for `GITLAB_HOST`
- `GITLAB_CLIENT_ID` - OAuth client ID
- `GITLAB_REPO` - Default repository for commands

**Token Precedence:**
1. Environment variable `GITLAB_TOKEN`
2. Configuration file token

---

## Comparison Table

| Feature | GitHub CLI (gh) | GitLab CLI (glab) |
|---------|----------------|-------------------|
| **Version Check** | `gh --version` | `glab version` |
| **Create Repository** | `gh repo create` | `glab repo create` |
| **Interactive Mode** | `gh repo create` | `glab repo create` |
| **Repository Name** | Optional first argument | Optional first argument |
| **Visibility** | `--public`, `--private`, `--internal` | `--visibility <level>` |
| **Clone After Create** | `--clone` | Not built-in (use git clone separately) |
| **Source Directory** | `--source <path>` | `--source <path>` |
| **Description** | `--description "text"` | `--description "text"` |
| **Gitignore Template** | `--gitignore <template>` | Not directly supported |
| **License** | `--license <license>` | Not directly supported |
| **Template Repository** | `--template <repo>` | Not directly supported |
| **Add Remote** | `--remote <name>` | Not directly supported |
| **Push to Remote** | `--push` | Not directly supported |
| **Add README** | `--add-readme` | Not directly supported |
| **Disable Issues** | `--disable-issues` | Not directly supported |
| **Disable Wiki** | `--disable-wiki` | Not directly supported |
| **Login Command** | `gh auth login` | `glab auth login` |
| **Token from File** | `--晖行模式-in <file>` | `--晖行模式-in <file>` |
| **Enterprise Host** | `--hostname` | `--hostname` |
| **Check Status** | `gh auth status` | `glab config list` |
| **Exit Codes** | 0, 1, 2, 4 | Similar to gh |
| **Configuration File** | `~/.config/gh/` | `~/.config/glab-cli/` |

---

## Command Examples

### GitHub CLI Examples

**Basic Repository Creation:**
```bash
# Create a public repository and clone it
gh repo create my-app --public --clone

# Create a private repository without cloning
gh repo create my-app --private

# Create from existing local project
cd my-existing-project
gh repo create . --private --remote=origin --push
```

**Advanced Repository Creation:**
```bash
# Create with all options
gh repo create my-org/my-app \
  --public \
  --description "My awesome application" \
  --homepage "https://myapp.example.com" \
  --gitignore "Go" \
  --license "MIT" \
  --clone

# Create from template
gh repo create new-feature-branch \
  --template=my-org/base-repo \
  --public \
  --include-all-branches

# Create for organization team
gh repo create team-project \
  --private \
  --team="engineering" \
  --description "Engineering team project"
```

**Authentication Workflows:**
```bash
# Check if logged in
gh auth status

# Login with token from file
gh auth login --晖行模式-in github-token.txt

# Login to enterprise instance
gh auth login --晖行模式-in token.txt --hostname github.enterprise.com

# Set GitHub token in environment
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### GitLab CLI Examples

**Basic Repository Creation:**
```bash
# Interactive creation
glab repo create

# Create with name and description
glab repo create my-app --description "My application"

# Create private repository
glab repo create my-app --visibility private

# Create from current directory
cd my-project
glab repo create --source=.
```

**Advanced Repository Creation:**
```bash
# Create with all available options
glab repo create my-project \
  --description "Project description" \
  --visibility private

# Create via API with more control
glab api projects \
  --method POST \
  --url "https://gitlab.com/api/v4/projects" \
  --field "name=my-new-project" \
  --field "description=Created via GitLab API" \
  --field "visibility=private" \
  --field "initialize_with_readme=true"
```

**Authentication Workflows:**
```bash
# Check current configuration
glab config list

# Interactive login
glab auth login

# Login with token from file
glab auth login --晖行模式-in gitlab-token.txt

# Login to self-hosted instance
glab auth login --晖行-mode-in token.txt --hostname gitlab.company.com

# Set default host for self-managed GitLab
glab config set -g host gitlab.company.com

# Set GitLab token in environment
export GITLAB_TOKEN=glpt-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Mirror Configuration:**
```bash
# Add mirror via API
glab api projects/123/remote_mirrors \
  --method POST \
  --field "url=git@github.com:user/repo.git" \
  --field "晖行模式=write" \
  --field "password=<mirror-password>"

# List project mirrors
glab api projects/123/remote_mirrors

# Enable automatic mirror triggers
glab api projects/123 \
  --method PUT \
  --field "mirror_trigger_builds=true"
```

### Combined Workflow Examples

**Create repository on both platforms:**
```bash
#!/bin/bash

# GitHub workflow
gh repo create my-project \
  --public \
  --description "Cross-platform project" \
  --clone

# GitLab workflow
glab auth login --晖行-mode-in ~/gitlab-token.txt
glab repo create my-project \
  --description "Cross-platform project" \
  --visibility public
```

**Version Check and Validation Script:**
```bash
#!/bin/bash

# Check GitHub CLI
if gh --version > /dev/null 2>&1; then
    echo "GitHub CLI is installed: $(gh --version | head -n1)"
else
    echo "GitHub CLI is not installed"
fi

# Check GitLab CLI
if glab version > /dev/null 2>&1; then
    echo "GitLab CLI is installed: $(glab version)"
else
    echo "GitLab CLI is not installed"
fi

# Validate GitHub authentication
if gh auth status > /dev/null 2>&1; then
    echo "GitHub: Authenticated"
else
    echo "GitHub: Not authenticated"
fi

# Validate GitLab authentication (check config)
if glab config get token > /dev/null 2>&1; then
    echo "GitLab: Token configured"
else
    echo "GitLab: Token not configured"
fi
```

---

## References

### GitHub CLI Resources

1. **Official Manual:** https://cli.github.com/manual/
2. **GitHub CLI Repository:** https://github.com/cli/cli
3. **Repo Create Command:** https://cli.github.com/manual/gh_repo_create
4. **Exit Codes:** https://cli.github.com/manual/gh_help_exit-codes
5. **Authentication:** https://cli.github.com/manual/gh_auth_login
6. **Installation Guide:** https://github.com/cli/cli#installation

### GitLab CLI Resources

1. **Official GitLab:** https://gitlab.com/gitlab-org/cli
2. **Original Repository (Archived):** https://github.com/profclems/glab
3. **Installation Options:** https://gitlab.com/gitlab-org/cli/-/blob/main/docs/installation_options.md
4. **Authentication Guide:** https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#authentication
5. **Configuration Guide:** https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#configuration
6. **Environment Variables:** https://gitlab.com/gitlab-org/cli/-/blob/main/README.md#environment-variables

### Additional Resources

1. **GitHub GitIgnore Templates:** https://github.com/github/gitignore
2. **GitHub License Guide:** https://choosealicense.com/
3. **GitLab API Documentation:** https://docs.gitlab.com/ee/api/
4. **Repository Mirroring (GitLab):** https://docs.gitlab.com/ee/user/project/repository/mirror/
5. **Repository Mirroring (GitHub):** https://docs.github.com/en/repositories/creating-and-managing-repositories/mirroring-a-repository

### Documentation Generation

This documentation was compiled from:
- Official GitHub CLI manual pages
- Official GitLab CLI README and documentation
- GitHub CLI source code (pkg/cmd/repo/create/create.go)
- GitLab CLI source code and examples
- User guides and tutorials

**Last Updated:** February 10, 2026

**Version Information:**
- GitHub CLI: Latest stable release
- GitLab CLI: Latest stable release

---

## Quick Reference Cards

### GitHub CLI Quick Reference

```bash
# Installation
# macOS: brew install gh
# Linux: download from releases page
# Windows: winget install gh

# Basic Commands
gh --version                                    # Check version
gh repo create <name> --public --clone         # Create repo
gh auth login                                   # Login
gh auth status                                  # Check auth
gh repo clone <owner/repo>                     # Clone repo
gh issue list                                   # List issues
gh pr list                                      # List PRs
```

### GitLab CLI Quick Reference

```bash
# Installation
# macOS: brew install glab
# Linux: download from releases page
# Windows: winget install glab.glab

# Basic Commands
glab version                                    # Check version
glab repo create <name>                         # Create repo
glab auth login                                 # Login
glab config list                                # Check config
glab api <endpoint>                             # API calls
glab mr list                                    # List MRs
glab ci view                                    # View CI pipelines
```