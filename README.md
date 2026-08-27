# gitmirror

Creates a Forgejo repository with automatic push mirroring to GitHub and GitLab.

## Architecture

```
Your machine → Forgejo (primary)
                ├── GitHub (push mirror)
                └── GitLab (push mirror)
```

Forgejo is the source of truth. All pushes go to Forgejo first, which
automatically mirrors to GitHub and GitLab via push mirroring.

## Why Forgejo as primary?

- **Self-hosted**: You control availability, no rate limits
- **Network access**: Forgejo can reach github.com and gitlab.com; the reverse is not true for a private network Forgejo
- **Push mirror support**: Native API for configuring push mirrors
- **No token exposure to third parties**: Mirror tokens stay on your Forgejo instance

## Usage

```bash
./gitmirror.sh my-project                        # public repos, mirrors to both
./gitmirror.sh --private my-project              # private repos
./gitmirror.sh --no-github my-project            # only GitLab mirror
./gitmirror.sh --no-gitlab my-project            # only GitHub mirror
./gitmirror.sh --help
```

## Prerequisites

### CLI tools

```bash
sudo apt install gh glab                         # Debian/Ubuntu
sudo pacman -S github-cli glab                   # Arch Linux
```

### Authentication

```bash
# GitHub (needs 'repo' scope)
gh auth login

# GitLab
glab auth login
```

### Forgejo API token

1. Log into your Forgejo instance
2. Go to **Settings → Applications → Generate New Token**
3. Grant `write:repository` and `read:user` scopes
4. Export it:
   ```bash
   export FORGEJO_TOKEN=your_token_here
   ```

### Forgejo URL (optional)

Defaults to `http://10.20.2.3:3000`. Override with:

```bash
export FORGEJO_URL=https://forgejo.example.com
```

## What It Does

1. Creates a local project folder
2. Creates a Forgejo repository (origin/primary)
3. Creates a GitHub repository (mirror)
4. Creates a GitLab repository (mirror)
5. Initializes local git with Forgejo as `origin` remote
6. Pushes initial commit to Forgejo
7. Configures push mirroring (Forgejo → GitHub) via Forgejo API
8. Configures push mirroring (Forgejo → GitLab) via Forgejo API

## Remotes

- `origin` → Forgejo (primary, push here)

GitHub and GitLab are configured as push mirrors on the Forgejo side.
You do not push to them directly.

## Mirroring

- Direction: Forgejo → GitHub, Forgejo → GitLab (push mirrors)
- Trigger: Syncs on every commit (`sync_on_commit: true`)
- All branches and tags mirrored
- Mirrors are one-directional: do not push to mirrors directly

## Adding SSH keys

Ensure your SSH public key is added to all three platforms:

- **Forgejo**: Settings → SSH/GPG Keys → Add Key
- **GitHub**: https://github.com/settings/ssh/new
- **GitLab**: https://gitlab.com/-/user_settings/ssh_keys

## Future platforms

The script is designed to be extensible. Planned support:

- [ ] Codeberg (Forgejo-hosted, same API)
- [ ] Gitea (same API as Forgejo)
- [ ] Bitbucket

## License

MIT
