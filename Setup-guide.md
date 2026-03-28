# Medusa Storefront Setup Guide

Based on the setup document (`00 Setup.pdf`) and the current project configuration.

---

## Step 1: Update and Upgrade the System

Ensure your system packages are up to date before installing any dependencies.

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Step 2: Update Installed Software (VS Code, etc.)

Update VS Code and any other development tools you already have installed.

```bash
# VS Code — update via the built-in updater (Help > Check for Updates)
# Or reinstall from the latest .deb:
sudo apt install ./code_latest_amd64.deb
```

Verify your versions:

```bash
code --version
```

---

## Step 3: Install VS Code Kilo Extension and Kilo CLI

### 3a. Kilo CLI

```bash
# Install globally via npm
npm install -g @anthropic-ai/kilo
```

Verify:

```bash
kilo --version
```

### 3b. VS Code Kilo Extension

1. Open VS Code
2. Go to **Extensions** (`Ctrl+Shift+X`)
3. Search for **Kilo**
4. Click **Install**

---

## Step 4: Install Required Skills for Medusa and Frontend Development

Inside a Kilo session, install the relevant skills:

```
/install building-with-medusa
/install building-storefronts
/install building-admin-dashboard-customizations
/install storefront-best-practices
/install db-generate
/install db-migrate
/install new-user
```

These skills provide domain-specific patterns for Medusa backend modules, storefront SDK usage, admin widgets, and database migrations.

---

## Step 5: Install Git, Node.js, PostgreSQL, and Redis

### 5a. Git

```bash
sudo apt install git -y
git --version
```

Configure your identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 5b. Node.js (v20+)

Medusa v2 requires Node.js 20 or higher. Install via NodeSource:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y
node --version
npm --version
```

### 5c. PostgreSQL

Install and configure:

```bash
sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Create a database user and database:

```bash
sudo -u postgres psql

# Inside the psql shell:
CREATE USER medusa_user WITH PASSWORD 'your_password';
CREATE DATABASE medusa_my_medusa_store OWNER medusa_user;
GRANT ALL PRIVILEGES ON DATABASE medusa_my_medusa_store TO medusa_user;
\q
```

Your connection string will be:

```
DATABASE_URL=postgres://medusa_user:your_password@localhost/medusa_my_medusa_store
```

### 5d. Redis

```bash
sudo apt install redis-server -y
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

Verify:

```bash
redis-cli ping
# Should return: PONG
```

---

## Step 6: Install MedusaJS with Storefront

### 6a. Install Medusa CLI

```bash
npm install -g @medusajs/cli
```

### 6b. Create the Backend

```bash
npx create-medusa-app@latest my-medusa-store
```

During setup, you will be prompted for:
- **Database URL** — use the connection string from Step 5c
- **Project name** — accept default or customize

Navigate into the backend:

```bash
cd my-medusa-store
```

Create a `.env` file with the required environment variables:

```env
STORE_CORS=http://localhost:8000
ADMIN_CORS=http://localhost:5173,http://localhost:9000
AUTH_CORS=http://localhost:5173,http://localhost:9000,http://localhost:8000
REDIS_URL=redis://localhost:6379
JWT_SECRET=your_jwt_secret
COOKIE_SECRET=your_cookie_secret
DATABASE_URL=postgres://medusa_user:your_password@localhost/medusa_my_medusa_store
```

Start the backend:

```bash
npm run dev
```

The backend runs at `http://localhost:9000`.

### 6c. Create the Storefront

From the project root (not inside the backend directory):

```bash
npx @medusajs/next-starter@latest my-medusa-store-storefront
```

This scaffolds a Next.js 15 storefront using the Medusa JS SDK.

Navigate into the storefront:

```bash
cd my-medusa-store-storefront
```

Create a `.env.local` file:

```env
MEDUSA_BACKEND_URL=http://localhost:9000
NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_your_publishable_key_here
NEXT_PUBLIC_BASE_URL=http://localhost:8000
NEXT_PUBLIC_DEFAULT_REGION=us
```

> **Getting the publishable key:** Log in to the Medusa Admin at `http://localhost:9000/app`, go to **Settings > Publishable API Keys**, and copy the key.

Install dependencies and start the storefront:

```bash
npm install
npm run dev
```

The storefront runs at `http://localhost:8000`.

---

## Step 7: Verify the Setup

1. **Backend** — open `http://localhost:9000/app` and log in to the admin dashboard
2. **Storefront** — open `http://localhost:8000` and verify the homepage loads
3. **API test** — run `curl http://localhost:9000/store/products` to confirm the API responds

---

## Project Structure

```
Project/
├── my-medusa-store/              # Medusa v2 backend (port 9000)
│   ├── src/
│   │   ├── api/                  # Custom API routes
│   │   ├── modules/              # Custom modules
│   │   └── scripts/              # Seed and utility scripts
│   ├── medusa-config.ts          # Backend configuration
│   └── .env                      # Backend environment variables
│
├── my-medusa-store-storefront/   # Next.js 15 storefront (port 8000)
│   ├── src/
│   │   ├── app/                  # Next.js App Router pages
│   │   ├── lib/                  # SDK config and data fetching
│   │   └── modules/              # UI components
│   ├── tailwind.config.js        # Tailwind CSS configuration
│   └── .env.local                # Storefront environment variables
```

---

## Reducing Dependency Install Time

The storefront's `npm install` can take ~30 minutes due to `latest` version specifiers on Medusa packages. See `reduced-install.md` for the full analysis. The fix:

1. Pin `@medusajs/*` packages to exact versions in `package.json`
2. Create `.npmrc` with `prefer-offline=true`, `fund=false`, `audit=false`
3. Remove the unused `resolutions` block
