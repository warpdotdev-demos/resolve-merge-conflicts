#!/usr/bin/env bash
# Creates two branches with intentional merge conflicts so you can
# immediately test the resolve-merge-conflicts skill with Oz.
#
# Usage:
#   ./setup.sh          # creates branches and starts the merge
#   ./setup.sh --reset  # tears down and re-creates everything

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

# ── Reset mode ───────────────────────────────────────────────────────
if [[ "${1:-}" == "--reset" ]]; then
  echo "Resetting demo state..."
  git merge --abort 2>/dev/null || true
  git checkout main 2>/dev/null || true
  git branch -D feature/add-auth feature/add-logging 2>/dev/null || true
  rm -f src/config.ts src/auth.ts src/logger.ts src/utils.ts
  rmdir src 2>/dev/null || true
  git checkout -- . 2>/dev/null || true
  echo "Reset complete. Run ./setup.sh again to recreate the demo."
  exit 0
fi

# ── Guard: don't run if conflicts already exist ──────────────────────
if git ls-files -u 2>/dev/null | grep -q .; then
  echo "Merge conflicts already present. Resolve them or run ./setup.sh --reset first."
  exit 1
fi

# ── Create sample source files on main ───────────────────────────────
echo "Setting up demo files on main..."
mkdir -p src

cat > src/config.ts << 'EOF'
export const config = {
  appName: "MyApp",
  version: "1.0.0",
  apiUrl: "https://api.example.com",
  timeout: 5000,
  retries: 3,
};
EOF

cat > src/utils.ts << 'EOF'
export function formatDate(date: Date): string {
  return date.toISOString().split("T")[0];
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}
EOF

git add src/
git commit -m "Add initial source files" --quiet

# ── Branch A: feature/add-auth ───────────────────────────────────────
echo "Creating feature/add-auth branch..."
git checkout -b feature/add-auth --quiet

# Modify config with auth settings
cat > src/config.ts << 'EOF'
export const config = {
  appName: "MyApp",
  version: "2.0.0",
  apiUrl: "https://api.example.com/v2",
  timeout: 10000,
  retries: 5,
  auth: {
    provider: "oauth2",
    tokenEndpoint: "/auth/token",
    refreshInterval: 300,
  },
};
EOF

# Modify utils with auth helper
cat > src/utils.ts << 'EOF'
export function formatDate(date: Date): string {
  return date.toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "")
    .replace(/--+/g, "-");
}

export function isTokenExpired(expiresAt: number): boolean {
  return Date.now() >= expiresAt * 1000;
}
EOF

# Add a new file (will conflict as add/add)
cat > src/auth.ts << 'EOF'
import { config } from "./config";

export async function authenticate(username: string, password: string) {
  const response = await fetch(`${config.apiUrl}${config.auth.tokenEndpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username, password }),
  });

  if (!response.ok) {
    throw new Error(`Authentication failed: ${response.status}`);
  }

  return response.json();
}
EOF

git add src/
git commit -m "Add OAuth2 authentication support" --quiet

# ── Branch B: feature/add-logging ────────────────────────────────────
echo "Creating feature/add-logging branch..."
git checkout main --quiet
git checkout -b feature/add-logging --quiet

# Modify config with logging settings (conflicts with auth branch)
cat > src/config.ts << 'EOF'
export const config = {
  appName: "MyApp",
  version: "2.0.0-beta",
  apiUrl: "https://api.example.com/v2",
  timeout: 8000,
  retries: 3,
  logging: {
    level: "info",
    destination: "stdout",
    structured: true,
  },
};
EOF

# Modify utils differently (conflicts with auth branch)
cat > src/utils.ts << 'EOF'
export function formatDate(date: Date): string {
  const pad = (n: number) => n.toString().padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}

export function createLogger(module: string) {
  return {
    info: (msg: string) => console.log(`[${module}] INFO: ${msg}`),
    warn: (msg: string) => console.warn(`[${module}] WARN: ${msg}`),
    error: (msg: string) => console.error(`[${module}] ERROR: ${msg}`),
  };
}
EOF

# Add a different auth.ts (add/add conflict)
cat > src/auth.ts << 'EOF'
import { config } from "./config";

const logger = {
  info: (msg: string) => console.log(`[auth] INFO: ${msg}`),
  error: (msg: string) => console.error(`[auth] ERROR: ${msg}`),
};

export async function authenticate(credentials: {
  username: string;
  password: string;
}) {
  logger.info(`Authenticating user: ${credentials.username}`);

  const response = await fetch(`${config.apiUrl}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(credentials),
  });

  if (!response.ok) {
    logger.error(`Auth failed for ${credentials.username}: ${response.status}`);
    throw new Error("Authentication failed");
  }

  logger.info(`Successfully authenticated: ${credentials.username}`);
  return response.json();
}
EOF

git add src/
git commit -m "Add structured logging support" --quiet

# ── Start the merge ──────────────────────────────────────────────────
echo ""
echo "Starting merge of feature/add-auth into feature/add-logging..."
echo ""

if git merge feature/add-auth --no-edit 2>/dev/null; then
  echo "Unexpected: merge completed without conflicts. Run ./setup.sh --reset and try again."
  exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Demo ready! Merge conflicts have been created."
echo ""
echo "  You're on branch: feature/add-logging"
echo "  Merging in:       feature/add-auth"
echo ""
echo "  Ask Oz to resolve the conflicts:"
echo "    \"Resolve the merge conflicts in this repo\""
echo ""
echo "  Or run the extraction script directly:"
echo "    python3 .agents/skills/resolve-merge-conflicts/scripts/extract_conflict_context.py"
echo ""
echo "  To reset and start over:"
echo "    ./setup.sh --reset"
echo "════════════════════════════════════════════════════════════════"
