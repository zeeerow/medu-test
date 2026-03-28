#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Medusa Development Environment — Ubuntu VM Quick Setup
# ============================================================
# Usage:
#   chmod +x quick-setup.sh
#   ./quick-setup.sh
#
# What it does:
#   1. System update
#   2. Install git, curl, build tools
#   3. Install Node.js 20 via NodeSource
#   4. Install PostgreSQL + create user/database
#   5. Install Redis
#   6. Install Medusa CLI + scaffold project
#   7. Scaffold storefront + pin dependencies
#   8. Install Kilo CLI + VS Code extension
# ============================================================

# ---------- Configuration (edit these) ----------
DB_USER="medusa_user"
DB_PASS="medusa_pass"
DB_NAME="medusa_store"
BACKEND_DIR="my-medusa-store"
STOREFRONT_DIR="my-medusa-store-storefront"
JWT_SECRET="change-me-jwt-secret"
COOKIE_SECRET="change-me-cookie-secret"
# ------------------------------------------------

LOG_FILE="setup-$(date +%Y%m%d-%H%M%S).log"
log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

log "=== Starting Medusa dev environment setup ==="

# ---------- Step 1: System update ----------
log "Updating system packages..."
sudo apt-get update -qq && sudo apt-get upgrade -qq -y

# ---------- Step 2: Core tools ----------
log "Installing core tools (git, curl, build-essential)..."
sudo apt-get install -qq -y \
  git \
  curl \
  wget \
  build-essential \
  ca-certificates \
  gnupg \
  lsb-release

# ---------- Step 3: Node.js 20 ----------
if ! command -v node &>/dev/null || [[ "$(node -v)" != v20* ]]; then
  log "Installing Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null 2>&1
  sudo apt-get install -qq -y nodejs
else
  log "Node.js $(node -v) already installed, skipping."
fi

# ---------- Step 4: PostgreSQL ----------
if ! command -v psql &>/dev/null; then
  log "Installing PostgreSQL..."
  sudo apt-get install -qq -y postgresql postgresql-contrib
  sudo systemctl enable postgresql
  sudo systemctl start postgresql
else
  log "PostgreSQL already installed, skipping."
fi

# Create user and database (idempotent)
log "Configuring PostgreSQL user and database..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null || true

# ---------- Step 5: Redis ----------
if ! command -v redis-cli &>/dev/null; then
  log "Installing Redis..."
  sudo apt-get install -qq -y redis-server
  sudo systemctl enable redis-server
  sudo systemctl start redis-server
else
  log "Redis already installed, skipping."
fi

# Verify Redis
redis-cli ping | grep -q PONG && log "Redis is running." || log "WARNING: Redis not responding."

# ---------- Step 6: npm cache & global packages ----------
log "Configuring npm..."
npm config set prefer-offline true
npm config set fund false
npm config set audit false

log "Installing global CLI tools..."
npm install -g @medusajs/cli @kilocode/cli 2>/dev/null || true

# ---------- Step 7: Scaffold Medusa backend ----------
if [ ! -d "$BACKEND_DIR" ]; then
  log "Scaffolding Medusa backend in ./$BACKEND_DIR ..."
  # Use the CLI directly instead of interactive create-medusa-app
  mkdir "$BACKEND_DIR" && cd "$BACKEND_DIR"
  npm init -y >/dev/null 2>&1
  npm install @medusajs/medusa @medusajs/cli @medusajs/framework @medusajs/admin-sdk 2>&1 | tail -3
  npm install -D @medusajs/test-utils @swc/core @swc/jest jest ts-node typescript vite 2>&1 | tail -3

  # medusa-config.ts
  cat > medusa-config.ts << 'BACKENDEOF'
import { loadEnv, defineConfig } from "@medusajs/framework/utils"
loadEnv(process.env.NODE_ENV || "development", process.cwd())

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    http: {
      storeCors: process.env.STORE_CORS!,
      adminCors: process.env.ADMIN_CORS!,
      authCors: process.env.AUTH_CORS!,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret",
    },
  },
})
BACKENDEOF

  # .env
  cat > .env << ENVEOF
STORE_CORS=http://localhost:8000
ADMIN_CORS=http://localhost:5173,http://localhost:9000
AUTH_CORS=http://localhost:5173,http://localhost:9000,http://localhost:8000
REDIS_URL=redis://localhost:6379
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET
DATABASE_URL=postgres://$DB_USER:$DB_PASS@localhost/$DB_NAME
ENVEOF

  cd ..
  log "Backend scaffolded."
else
  log "Backend directory $BACKEND_DIR already exists, skipping."
fi

# ---------- Step 8: Scaffold storefront ----------
if [ ! -d "$STOREFRONT_DIR" ]; then
  log "Scaffolding storefront in ./$STOREFRONT_DIR ..."
  npx @medusajs/next-starter@latest "$STOREFRONT_DIR" 2>&1 | tail -5

  cd "$STOREFRONT_DIR"

  # Pin Medusa packages to installed versions (reduces future install time)
  log "Pinning Medusa package versions..."
  for pkg in @medusajs/icons @medusajs/js-sdk @medusajs/ui @medusajs/types @medusajs/ui-preset; do
    installed=$(node -e "try{console.log(require('./node_modules/$pkg/package.json').version)}catch{console.log('')" 2>/dev/null)
    if [ -n "$installed" ]; then
      sed -i "s/\"$pkg\": \"latest\"/\"$pkg\": \"$installed\"/" package.json
      log "  Pinned $pkg -> $installed"
    fi
  done

  # Create .npmrc for faster reinstalls
  cat > .npmrc << NPMRC
prefer-offline=true
fund=false
audit=false
NPMRC

  # Remove unused resolutions block (npm uses overrides, not resolutions)
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
    if (pkg.resolutions) { delete pkg.resolutions; fs.writeFileSync('package.json', JSON.stringify(pkg,null,2)+'\n'); }
  "

  # .env.local
  cat > .env.local << STOREENVEOF
MEDUSA_BACKEND_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_placeholder_replace_me
NEXT_PUBLIC_BASE_URL=http://localhost:8000
NEXT_PUBLIC_DEFAULT_REGION=us
STOREENVEOF

  cd ..
  log "Storefront scaffolded with pinned dependencies."
else
  log "Storefront directory $STOREFRONT_DIR already exists, skipping."
fi

# ---------- Done ----------
log ""
log "=== Setup complete ==="
log ""
log "Next steps:"
log "  1. Start the backend:  cd $BACKEND_DIR && npm run dev"
log "  2. Get a publishable key from http://localhost:9000/app"
log "  3. Update NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY in $STOREFRONT_DIR/.env.local"
log "  4. Start the storefront: cd $STOREFRONT_DIR && npm run dev"
log ""
log "  Backend:    http://localhost:9000"
log "  Admin:      http://localhost:9000/app"
log "  Storefront: http://localhost:8000"
