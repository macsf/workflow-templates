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
      -e "s/{{PM2_APP_NAME}}/$PM2_APP_NAME/g" \
      -e "s|{{API_DIR}}|$API_DIR|g" \
      "$src" > "$dest"
  echo "  wrote $dest"
}

# ── collect values ────────────────────────────

echo ""
echo "== workflow-templates scaffold =="
echo ""

PROJECT_NAME=$(prompt "PROJECT_NAME" "Project name (kebab-case)" "")
[ -z "$PROJECT_NAME" ] && { echo "PROJECT_NAME is required"; exit 1; }

PNPM_VERSION=$(prompt "PNPM_VERSION" "pnpm version" "10")
NODE_VERSION=$(prompt "NODE_VERSION" "Node version" "22")

echo ""
echo "Select project tier:"
echo "  1) library     — CI only (typecheck, lint, test, build)"
echo "  2) static-app  — CI + static deploy (SCP dist, symlink, reload)"
echo "  3) fullstack   — CI + blue-green deploy (pm2, rollback, health check)"
read -r -p "Tier [2]: " TIER_INPUT
TIER="${TIER_INPUT:-2}"

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

  3|fullstack)
    API_DIR=$(prompt "API_DIR" "API subdirectory (e.g. server, api)" "server")
    PM2_APP_NAME=$(prompt "PM2_APP_NAME" "PM2 process name" "$PROJECT_NAME")

    echo ""
    echo "Install fullstack CI + deploy workflows..."
    render "$TEMPLATES_DIR/fullstack-app/ci.yml" "$TARGET/.github/workflows/ci.yml"

    if confirm "Include version bump on deploy?"; then
      render "$TEMPLATES_DIR/fullstack-app/deploy-with-bump.yml" "$TARGET/.github/workflows/deploy.yml"
    else
      render "$TEMPLATES_DIR/fullstack-app/deploy.yml" "$TARGET/.github/workflows/deploy.yml"
    fi
    ;;

  *)
    echo "Unknown tier: $TIER"
    exit 1
    ;;
esac

# ── dependabot ────────────────────────────────
echo ""
if confirm "Add dependabot.yml?"; then
  cat > "$TARGET/.github/dependabot.yml" << 'EOF'
version: 2
updates:
  - package-ecosystem: "pnpm"
    directory: "/"
    schedule:
      interval: "daily"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
EOF
  echo "  wrote .github/dependabot.yml"
fi

echo ""
echo "Done. Workflows scaffolded in $TARGET/.github/workflows/"
echo "Review them and commit before pushing."
