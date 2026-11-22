#!/usr/bin/env bash
# EyeGo backend on the macOS runner, next to the simulators (they share its
# network, so the apps reach it at localhost:5020). Fresh DB every run.
# Expects the EyeGo repo checked out at ./eyego. Logs go to results/ (encrypted).
set -euo pipefail
RUN_DIR="results/${RUN:?}"
mkdir -p "$RUN_DIR"

brew install -q postgresql@17 redis >/dev/null
brew services start postgresql@17 >/dev/null
brew services start redis >/dev/null
PG_BIN="$(brew --prefix postgresql@17)/bin"
export PATH="$PG_BIN:$PATH"
for _ in $(seq 1 30); do pg_isready -q && break; sleep 1; done
createdb eyego

cd eyego/eyego-api
# Zod in src/config/env.js wants these non-empty even in dev; the real keys
# come from secrets, the rest are inert placeholders (SMS = dev OTP, payments = mock).
cat > .env <<EOF
NODE_ENV=development
PORT=5020
APP_URL=http://localhost:5020
DATABASE_URL=postgresql://$(whoami)@localhost:5432/eyego
DIRECT_URL=postgresql://$(whoami)@localhost:5432/eyego
REDIS_URL=redis://localhost:6379
JWT_ACCESS_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
ADMIN_SECRET_KEY=$(openssl rand -hex 16)
PAYMENT_PROVIDER=mock
PAYSTACK_SECRET_KEY=sk_test_placeholder
PAYSTACK_PUBLIC_KEY=pk_test_placeholder
AT_API_KEY=placeholder
AT_USERNAME=sandbox
MAPBOX_SECRET_TOKEN=${MAPBOX_SECRET_TOKEN:?secret MAPBOX_SECRET_TOKEN missing}
MAPBOX_PUBLIC_TOKEN=${MAPBOX_PUBLIC_TOKEN:-}
CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME:-placeholder}
CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY:-placeholder}
CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET:-placeholder}
DRIVER_REQUIRED_WALLET_TO_GO_ONLINE=0
DRIVER_REQUIRED_WALLET_TO_GO_ONLINE_PESEWAS=0
EOF
npm ci --no-audit --no-fund >/dev/null 2>&1   # postinstall = prisma generate
npx prisma migrate deploy >/dev/null
nohup npm start > "$GITHUB_WORKSPACE/$RUN_DIR/api.log" 2>&1 &
for _ in $(seq 1 60); do curl -sf http://localhost:5020/health >/dev/null && { echo "API up"; exit 0; }; sleep 2; done
echo "::error::API did not come up (see api.log in the encrypted results)"; exit 1
