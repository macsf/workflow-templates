# workflow-templates

Reusable GitHub Actions templates for macsf / BrandBaker projects.

## Tiers

| Tier | Description | Files | Example |
|------|-------------|-------|---------|
| **library** | CI only: typecheck, lint, test, build | `ci.yml` | the-date-picker, CLI tools |
| **static-app** | CI + static deploy (SCP dist, symlink, reload) | `ci.yml`, `deploy.yml` | vent-astro |
| **docker-hostinger** | CI + GHCR image + Hostinger VPS (Traefik) | `ci.yml`, `deploy.yml`, `deploy-gate.sh` | money-manager, probation-evaluation |
| **docker-compose** | CI only. Dokploy, Coolify, or any Compose host builds the image | `ci.yml` | meridian-insights, influencer_db, social-media-perf-charting |

Dependabot (`dependabot.yml`) is offered for every tier.

## Usage

```bash
git clone git@github.com:macsf/workflow-templates.git
cd my-project
../workflow-templates/scaffold.sh
```

Or from any directory:

```bash
/path/to/workflow-templates/scaffold.sh /path/to/my-project
```

The script prompts for project name, pnpm / Node version, and tier.

## Docker schemes

Two production shapes. Pick one; do not mix Traefik labels with a platform that injects its own.

### Hostinger (`docker-hostinger`)

GitHub Actions builds and pushes `ghcr.io/<owner>/<repo>:<sha>` (and `:latest`), then `hostinger/deploy-on-vps@v2` deploys `docker-compose.yml` on the VPS.

- Compose **pulls** the GHCR image (`APP_IMAGE`). No `build:` key (Hostinger does not build).
- Publish the app on `127.0.0.1` only. Traefik on the VPS uses host networking and reads Docker labels.
- GitHub environment: `deploy`.
- Push to `main` deploys only when a commit subject in the push starts with `release:` or `fix:` (including `fix(scope):`). `workflow_dispatch` always deploys. `[skip deploy]` in any commit message of the push skips it.
- Hostinger `project-name` must be at least 3 characters (use the repo name).

### Dokploy / Coolify / generic Compose (`docker-compose`)

The platform clones the repo and builds `Dockerfile` / `docker-compose.yml`. GitHub Actions only verifies (CI).

- Compose has `build:` and `expose:`. No Traefik labels (the platform owns routing / TLS).
- Local ports go in `docker-compose.override.yml` (not used in production).
- SQLite (if any) must use a **named volume**. Bind-mounting `./data` is wiped when Dokploy recreates the compose directory.
- Set secrets in the platform Environment tab. Never bake them into the image.

## GitHub environment `deploy` (Hostinger)

| Kind | Name | Purpose |
| --- | --- | --- |
| Secret | `HOSTINGER_API_KEY` | Hostinger API (hPanel → API) |
| Variable | `HOSTINGER_VM_ID` | Target VPS (from the VPS overview URL) |
| Variable | `TRAEFIK_HOST` | Public hostname |
| Variable | `TRAEFIK_ROUTER` / `TRAEFIK_ENTRYPOINT` / `TRAEFIK_CERTRESOLVER` | Traefik labels |
| Variable | `PORT` | Host loopback publish port (container still listens on 8080) |
| Variable | `HOST_UID` / `HOST_GID` | Container user (default 0) |
| Secret | `DATABASE_URL` | Prisma / app database |
| Secret | `NEXTAUTH_SECRET` / `SESSION_SECRET` | Auth (use the one your app needs) |
| Secret | `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth |
| Variable | `GOOGLE_WORKSPACE_DOMAIN` | Optional login domain restriction |

App-specific secrets go on the same environment. The VPS must be able to pull GHCR (`docker login ghcr.io`, or a public package). Private GitHub repos need a VPS SSH deploy key under **Settings → Deploy keys**.

## Conventional commits

Branch off `main` (`feat/...`, `fix/...`, `chore/...`). Do not commit to `main` directly.

```
feat:, fix:, hotfix:, chore:, refactor:, docs:, test:, perf:, style:, release:
```

Hostinger deploys only for `release:` and `fix:` / `fix(scope):` subjects. `workflow_dispatch` always deploys.

## Dependabot

Copied as `.github/dependabot.yml`:

- npm: weekly on Monday, Asia/Bangkok, grouped prod/dev, majors ignored
- github-actions: monthly
- docker: monthly

Ecosystem is `npm` even for pnpm projects (Dependabot does not have a `pnpm` ecosystem).

## Placeholders

| Placeholder | Default | Used by |
|-------------|---------|---------|
| `{{PROJECT_NAME}}` | — | All |
| `{{PNPM_VERSION}}` | 10 | All |
| `{{NODE_VERSION}}` | 24 | All |
| `{{APP_DIR}}` | /opt/{{PROJECT_NAME}} | static-app deploy |

## Templates

```
templates/
  library/ci.yml
  static-app/ci.yml
  static-app/deploy.yml
  docker-hostinger/ci.yml
  docker-hostinger/deploy.yml
  docker-compose/ci.yml
  dependabot.yml
  scripts/deploy-gate.sh
```
