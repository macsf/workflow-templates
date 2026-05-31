# workflow-templates

Reusable GitHub Actions workflow templates for macsf projects.

## Tiers

| Tier | Description | Files | Example project |
|------|-------------|-------|-----------------|
| **library** | CI only — typecheck, lint, test, build | `ci.yml` | the-date-picker |
| **static-app** | CI + static deploy — SCP dist, symlink, reload | `ci.yml`, `deploy.yml` | vent-astro |
| **fullstack** | CI + release + blue-green deploy — pm2, rollback, health check | `ci.yml`, `release.yml`, `deploy.yml` | money-manager, seeurl |

## Usage

```bash
# Clone the templates
git clone git@github.com:macsf/workflow-templates.git

# Run the scaffold in your project root
cd my-project
../workflow-templates/scaffold.sh
```

Or run from any directory:

```bash
/path/to/workflow-templates/scaffold.sh /path/to/my-project
```

The script will prompt for:
- Project name
- pnpm / Node version
- Tier (library, static-app, or fullstack)
- API subdirectory and PM2 name (fullstack only)

## Secrets to configure

These GitHub secrets must be set in the target repo for deploy workflows:

| Secret | Required for | Description |
|--------|-------------|-------------|
| `DO_HOST` | deploy | DigitalOcean server IP |
| `DO_SSH_PORT` | deploy | SSH port (default 22) |
| `DO_SSH_USER` | deploy | SSH username (default `deploy`) |
| `DO_SSH_KEY` | deploy | SSH private key |
| `APP_PORT` | fullstack | App listen port (default 3001) |
| `FRONTEND_URL` | fullstack | Public URL of the frontend |
| `DATABASE_URL` | fullstack | Database connection string |
| `SESSION_SECRET` | fullstack | HMAC session secret (min 32 chars) |
| `GOOGLE_CLIENT_ID` | fullstack | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | fullstack | Google OAuth client secret |
| `ALLOWED_EMAILS` | fullstack | Comma-separated allowed emails (optional) |
| `VITE_GOOGLE_CLIENT_ID` | fullstack build | Google client ID exposed to frontend |

## Deployment Notes

- For `appleboy/ssh-action`, prefer writing remote `.env` files with direct `${{ secrets.NAME }}` interpolation inside the `script:` block.
- Avoid forwarding app secrets through the action's `env` and `envs` inputs unless there is a specific need. In practice, direct interpolation is simpler and avoids shell-wrapper leakage from the underlying `drone-ssh` runner.

## Release Versioning (fullstack)

The fullstack tier uses two chained workflows:

1. **`release.yml`** — runs on push to main, bumps version, commits `chore(release): vX.Y.Z`, creates a git tag `vX.Y.Z`, and pushes.
2. **`deploy.yml`** — triggered when `release.yml` completes successfully. Checks out the bumped commit, builds, and deploys.

This means the deployed code always matches the version in `package.json`, and deploy can be re-run independently via `workflow_dispatch` without bumping again.

### Trigger filter

`release.yml` only fires on conventional commits, skipping `chore(release):` to avoid an infinite loop:

```
feat:, fix:, hotfix:, chore:, refactor:, docs:, test:, perf:, style:
```

Commits that start with `chore(release):`, or any other prefix not in the list (e.g. `wip:`, `tmp:`), will not trigger a release.

### Bump type

Controlled by a flag in the commit message:

| Flag in message | Result |
|-----------------|--------|
| _(none)_ | patch |
| `#minor` | minor |
| `#major` | major |
| `#none` | skip bump |

Examples:

```bash
git commit -m "fix: correct session expiry"           # → patch bump
git commit -m "feat: add dashboard #minor"            # → minor bump
git commit -m "feat!: new auth model #major"          # → major bump
git commit -m "chore: update deps #none"              # → no bump, no deploy
```

Via `workflow_dispatch`, select the bump type manually in the GitHub Actions UI.

### Tags

Every release creates a git tag (`v1.2.3`) visible in GitHub's Releases / Tags page. Tags are pushed with `--follow-tags` alongside the version bump commit.

## Templates

All templates use `{{PLACEHOLDER}}` syntax replaced by the scaffold script:

| Placeholder | Default | Used by |
|-------------|---------|---------|
| `{{PROJECT_NAME}}` | — | All |
| `{{PNPM_VERSION}}` | 10 | All |
| `{{NODE_VERSION}}` | 22 | All |
| `{{APP_DIR}}` | /opt/{{PROJECT_NAME}} | Deploy |
| `{{PM2_APP_NAME}}` | {{PROJECT_NAME}} | Fullstack |
