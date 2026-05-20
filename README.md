# workflow-templates

Reusable GitHub Actions workflow templates for macsf projects.

## Tiers

| Tier | Description | Files | Example project |
|------|-------------|-------|-----------------|
| **library** | CI only — typecheck, lint, test, build | `ci.yml` | the-date-picker |
| **static-app** | CI + static deploy — SCP dist, symlink, reload | `ci.yml`, `deploy.yml` | vent-astro |
| **fullstack** | CI + blue-green deploy — pm2, rollback, health check | `ci.yml`, `deploy.yml` | money-manager, seeurl |

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
- Whether to include version bump (fullstack only)

## Secrets to configure

These GitHub secrets must be set in the target repo for deploy workflows:

| Secret | Required for | Description |
|--------|-------------|-------------|
| `DO_HOST` | deploy | DigitalOcean server IP |
| `DO_SSH_PORT` | deploy | SSH port (default 22) |
| `DO_SSH_USER` | deploy | SSH username (default deploy) |
| `DO_SSH_KEY` | deploy | SSH private key |
| `DO_SSH_PASSPHRASE` | deploy | SSH key passphrase |
| `PORT` | fullstack | App listen port (default 3001) |

## Deployment Notes

- For `appleboy/ssh-action`, prefer writing remote `.env` files with direct `${{ secrets.NAME }}` interpolation inside the `script:` block.
- Avoid forwarding app secrets through the action's `env` and `envs` inputs unless there is a specific need. In practice, direct interpolation is simpler and avoids shell-wrapper leakage from the underlying `drone-ssh` runner.

## Templates

All templates use `{{PLACEHOLDER}}` syntax replaced by the scaffold script:

| Placeholder | Default | Used by |
|-------------|---------|---------|
| `{{PROJECT_NAME}}` | — | All |
| `{{PNPM_VERSION}}` | 10 | All |
| `{{NODE_VERSION}}` | 22 | All |
| `{{API_DIR}}` | server | Fullstack |
| `{{APP_DIR}}` | /opt/{{PROJECT_NAME}} | Deploy |
| `{{PM2_APP_NAME}}` | {{PROJECT_NAME}} | Fullstack |
