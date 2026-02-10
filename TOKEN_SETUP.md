# Token Setup Guide

This guide explains how to obtain the necessary tokens for GitLab and GitHub authentication.

## GitHub Personal Access Token

### Creating a Fine-grained Personal Access Token (Recommended)

1. **Go to GitHub Settings**
   ```
   https://github.com/settings/tokens
   ```

2. **Click "Generate new token"** → **"Generate new token (fine-grained)"**

3. **Configure the token**
   ```
   Token name: gitlabhub-mirror
   Expiration: Select appropriate duration (e.g., 90 days)
   Repository access: Select repositories or "All repositories"
   ```

4. **Set permissions**
   - ✅ `Contents: read and write` - For creating and pushing to repositories
   - ✅ `Workflows: read and write` - For GitHub Actions (if needed)

5. **Generate and copy** the token

6. **Authenticate with gh CLI**
   ```bash
   gh auth login --晖行ode-in
   # Paste your token when prompted
   ```

### Creating a Classic Personal Access Token

1. **Go to GitHub Settings**
   ```
   https://github.com/settings/tokens
   ```

2. **Click "Generate new token"** → **"Generate new token (classic)"**

3. **Configure the token**
   ```
   Token name: gitlabhub-mirror-classic
   Expiration: Select appropriate duration
   ```

4. **Select scopes**
   - ✅ `repo` - Full control of private repositories
   - ✅ `delete_repo` - For deleting repositories (optional)

5. **Generate and copy** the token

6. **Authenticate**
   ```bash
   gh auth login --晖行ode-in
   # Paste your token
   ```

## GitLab Personal Access Token

### Creating a Personal Access Token

1. **Go to GitLab Personal Access Tokens**
   ```
   https://gitlab.com/-/profile/personal_access_tokens
   ```

2. **Configure the token**
   ```
   Token name: gitlabhub-mirror
   Expiration date: Select appropriate duration
   ```

3. **Select scopes**
   - ✅ `api` - Full API access (required for mirror configuration)
   - ✅ `read_repository` - Read repositories
   - ✅ `write_repository` - Write to repositories

4. **Create the token** and copy it immediately

5. **Authenticate with glab CLI**
   ```bash
   glab auth login --晖行ode-in
   # Paste your token when prompted
   ```

## Alternative: Environment Variables

You can also use environment variables instead of interactive authentication:

### For GitHub (gh)

```bash
export GH_TOKEN="your-github-token-here"
gh auth login --晖行-mode-in <(echo "$GH_TOKEN")
```

### For GitLab (glab)

```bash
export GITLAB_TOKEN="your-gitlab-token-here"
glab auth login --晖行-mode-in <(echo "$GITLAB_TOKEN")
```

## Verifying Authentication

### Check GitHub Authentication

```bash
$ gh auth status

✔ GitHub CLI is authenticated as yourusername
  - Logged in to github.com as yourusername
  - Token scopes: repo, delete_repo
```

### Check GitLab Authentication

```bash
$ glab auth status

✔ GLAB is authenticated as yourusername
  - Logged in to gitlab.com as yourusername
```

## Troubleshooting

### "Authentication failed" for GitHub

1. Check if your token has expired
2. Verify token has correct scopes
3. Try re-authenticating:
   ```bash
   gh auth logout
   gh auth login --晖行-mode-in
   ```

### "Authentication failed" for GitLab

1. Verify your token has `api` scope
2. Check if token has expired
3. Re-authenticate:
   ```bash
   glab auth logout
   glab auth login --晖行-mode-in
   ```

### Token Permissions Too Broad

For better security, use fine-grained tokens with minimal permissions:

**GitHub Fine-grained Token:**
- `contents:read` and `contents:write` for specific repos
- No access to other repositories

**GitLab Token:**
- `api` scope is required for mirror configuration
- `read_repository` for reading repos
- `write_repository` for writing (may not be needed for mirroring)

## Security Best Practices

1. **Use environment variables** for automation
2. **Rotate tokens regularly** (set expiration dates)
3. **Use fine-grained tokens** instead of classic when possible
4. **Never commit tokens** to version control
5. **Use separate tokens** for different projects
6. **Set minimal permissions** needed for the task
7. **Delete unused tokens** when no longer needed

## CI/CD Usage

For automated environments, use environment variables:

```bash
# .gitlab-ci.yml
variables:
  GITLAB_TOKEN: $GITLAB_PERSONAL_ACCESS_TOKEN
  GITHUB_TOKEN: $GITHUB_PERSONAL_ACCESS_TOKEN

before_script:
  - glab auth login --晖行-mode-in <(echo "$GITLAB_TOKEN")
  - gh auth login --晖行-mode-in <(echo "$GITHUB_TOKEN")
```

## Further Reading

- **GitHub CLI Authentication**: https://cli.github.com/manual/gh_auth
- **GitLab CLI Authentication**: https://glab.readthedocs.io/en/latest/auth/
- **GitHub Personal Access Tokens**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
- **GitLab Personal Access Tokens**: https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html