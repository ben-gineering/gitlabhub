# GitLab-GitHub Mirror Setup

Creates a GitLab repository with automatic push mirroring to GitHub.

## Usage

```bash
./setup-mirror.sh my-project           # public repos
./setup-mirror.sh --private my-project # private repos
./setup-mirror.sh --help
```

## Prerequisites

- [glab](https://glab.readthedocs.io/en/latest/install.html) (GitLab CLI)
- [gh](https://cli.github.com/manual/installation) (GitHub CLI)
- Both CLIs authenticated: `glab auth login` && `gh auth login`

## What It Does

1. Creates project folder and enters it
2. Creates GitLab repository (origin)
3. Creates GitHub repository (mirror)
4. Initializes local git with remotes configured
5. Pushes initial commit to GitLab
6. Configures push mirroring (GitLab → GitHub) via GitLab API

## Remotes

- `origin` → GitLab (main repo)
- `mirror` → GitHub (public mirror)

## Mirroring

- Direction: GitLab → GitHub (push mirror)
- Frequency: Automatic within 5 minutes of push
- All branches mirrored

## Support

- [GitHub CLI docs](https://cli.github.com/manual/)
- [GitLab CLI docs](https://glab.readthedocs.io/)
- [GitLab mirror docs](https://docs.gitlab.com/ee/user/project/repository/mirroring.html)