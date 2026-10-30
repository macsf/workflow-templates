# workflow-templates — Agent Guidelines

Scaffolding library for GitHub Actions. Not a runnable application.

## Tiers

| Folder | When to use |
| --- | --- |
| `library` | npm package, CLI, or shared lib. CI only. |
| `static-app` | Static site (Astro, Vite SPA without an API). SCP + symlink. |
| `docker-hostinger` | App on the Hostinger VPS. GHCR + `hostinger/deploy-on-vps@v2` + Traefik labels. |
| `docker-compose` | App on Dokploy, Coolify, or any Compose host. CI only; the platform builds. |

Do not add a PM2 / DigitalOcean tarball deploy. That path is retired.

## Template variable convention

- Format: `{{DOUBLE_BRACES}}` — no spaces inside braces.
- `scaffold.sh` substitutes with `sed`. Never use single braces `{VAR}`.
- Leave GitHub and Docker expressions alone (`${{ github.sha }}`, `{{is_default_branch}}`).

## Hostinger requirements

- `project-name` minimum 3 characters. Use the repo name, not a 2-letter abbreviation.
- Project dir on the VPS is `/docker/<project-name>/`.
- Traefik uses host networking; publish app ports on `127.0.0.1` only.
- Secrets live in GitHub environment `deploy`, injected via `environment-variables`.
- Compose for Hostinger **pulls** `APP_IMAGE`. Do not put a `build:` key in that file.

## Dokploy / Coolify requirements

- Compose has `build:` + `expose:`. No Traefik labels (the platform adds routing).
- Local port publish belongs in `docker-compose.override.yml`.
- SQLite: named volume, never `./data` on Dokploy (the compose directory is recreated each deploy).

## Adding a template

1. Add `templates/<tier>/` with the workflow YAML.
2. Add a case in `scaffold.sh`.
3. Update `README.md` and this file.
