#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# workflow-templates scaffold
# Generates .github/workflows/ for a project
# ──────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"
TARGET="${1:-.}"

# ── helpers ───────────────────────────────────

prompt() {
  local var="$1" msg="$2" default="$3"
  local val
  if [ -n "$default" ]; then
    read -r -p "$msg [$default]: " val
    echo "${val:-$default}"
  else
    read -r -p "$msg: " val
    echo "$val"
  fi
}

confirm() {
  local msg="$1" default="${2:-y}"
  local val
  read -r -p "$msg (Y/n) " val
  case "${val:-$default}" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

render() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  sed -e "s/{{PNPM_VERSION}}/$PNPM_VERSION/g" \
      -e "s/{{NODE_VERSION}}/$NODE_VERSION/g" \
      -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
      -e "s|{{APP_DIR}}|$APP_DIR|g" \
      "$src" > "$dest"
  echo "  wrote $dest"
}

copy_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "  wrote $dest"
}

# ── collect values ────────────────────────────

echo ""
echo "== workflow-templates scaffold =="
echo ""

PROJECT_NAME=$(prompt "PROJECT_NAME" "Project name (kebab-case, min 3 chars)" "")
[ -z "$PROJECT_NAME" ] && { echo "PROJECT_NAME is required"; exit 1; }
if [ "${#PROJECT_NAME}" -lt 3 ]; then
  echo "PROJECT_NAME must be at least 3 characters (Hostinger rejects shorter names)"
  exit 1
fi

PNPM_VERSION=$(prompt "PNPM_VERSION" "pnpm version" "10")
NODE_VERSION=$(prompt "NODE_VERSION" "Node version" "22")

echo ""
echo "Select project tier:"
echo "  1) library           — CI only (typecheck, lint, test, build)"
echo "  2) static-app        — CI + static deploy (SCP dist, symlink, reload)"
echo "  3) docker-hostinger  — CI + GHCR + Hostinger VPS (Traefik)"
echo "  4) docker-compose    — CI only; Dokploy / Coolify / Compose host builds"
read -r -p "Tier [4]: " TIER_INPUT
TIER="${TIER_INPUT:-4}"

APP_DIR="/opt/$PROJECT_NAME"

case "$TIER" in
  1|library)
    echo ""
    echo "Installing library CI workflow..."
    render "$TEMPLATES_DIR/library/ci.yml" "$TARGET/.github/workflows/ci.yml"
    ;;

  2|static-app)
    echo ""
    echo "Installing static-app CI + deploy workflows..."
    render "$TEMPLATES_DIR/static-app/ci.yml" "$TARGET/.github/workflows/ci.yml"
    render "$TEMPLATES_DIR/static-app/deploy.yml" "$TARGET/.github/workflows/deploy.yml"
    ;;

  3|docker-hostinger)
    echo ""
    echo "Installing docker-hostinger CI + deploy workflows..."
    render "$TEMPLATES_DIR/docker-hostinger/ci.yml" "$TARGET/.github/workflows/ci.yml"
    render "$TEMPLATES_DIR/docker-hostinger/deploy.yml" "$TARGET/.github/workflows/deploy.yml"
    copy_file "$TEMPLATES_DIR/scripts/deploy-gate.sh" "$TARGET/.github/scripts/deploy-gate.sh"
    chmod +x "$TARGET/.github/scripts/deploy-gate.sh"
    ;;

  4|docker|docker-compose|dokploy|coolify)
    echo ""
    echo "Installing docker-compose CI workflow (platform builds the image)..."
    render "$TEMPLATES_DIR/docker-compose/ci.yml" "$TARGET/.github/workflows/ci.yml"
    ;;

  *)
    echo "Unknown tier: $TIER"
    exit 1
    ;;
esac

# ── dependabot ────────────────────────────────
echo ""
if confirm "Add dependabot.yml?"; then
  copy_file "$TEMPLATES_DIR/dependabot.yml" "$TARGET/.github/dependabot.yml"
fi

echo ""
echo "Done. Workflows scaffolded in $TARGET/.github/"
echo "Review them and commit before pushing."

case "$TIER" in
  3|docker-hostinger)
    echo ""
    echo "Hostinger next steps:"
    echo "  1. Create GitHub environment 'deploy' with HOSTINGER_* / TRAEFIK_* / app secrets"
    echo "  2. Add a VPS SSH deploy key on the GitHub repo (private repos)"
    echo "  3. Ensure the VPS can pull ghcr.io/<owner>/<repo>"
    echo "  4. Ship docker-compose.yml with Traefik labels and image: \${APP_IMAGE}"
    ;;
  4|docker|docker-compose|dokploy|coolify)
    echo ""
    echo "Compose-host next steps:"
    echo "  1. Point Dokploy/Coolify at this repo, compose path docker-compose.yml"
    echo "  2. Set secrets in the platform Environment tab"
    echo "  3. Map the public domain to service 'web', container port 8080"
    ;;
esac
