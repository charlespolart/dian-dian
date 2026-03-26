#!/bin/bash
set -e

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

SERVICE_NAME="diandian"
WORKING_DIR="/root/dian-dian"
BACKEND_DIR="$WORKING_DIR/backend"
FRONTEND_DIR="$WORKING_DIR/frontend"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
NODE_VERSION=$(nvm current)
NODE_PATH="$HOME/.nvm/versions/node/$NODE_VERSION/bin/node"
NPX_PATH="$HOME/.nvm/versions/node/$NODE_VERSION/bin/npx"

if [ -z "$NODE_VERSION" ]; then
    echo "Error: Node.js not found. Install it via nvm."
    exit 1
fi

echo "Using Node.js $NODE_VERSION"
cd "$WORKING_DIR" || exit 1

# ── Pull latest code ──
echo ""
echo "=== Pulling latest code ==="
git pull origin master

# ── Stop service ──
echo ""
echo "=== Stopping service ==="
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true

# ── Backend ──
echo ""
echo "=== Building backend ==="
cd "$BACKEND_DIR"
npm ci
npm run build

# ── Database migrations ──
echo ""
echo "=== Running migrations ==="
$NPX_PATH drizzle-kit migrate

# Remove devDependencies for production
npm prune --omit=dev

# ── Frontend ──
echo ""
echo "=== Building frontend ==="
cd "$FRONTEND_DIR"
npm ci
$NPX_PATH expo export --platform web

# ── Inject PWA meta tags into dist/index.html ──
echo "Injecting PWA meta tags..."
sed -i 's|</head>|<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="default"><meta name="apple-mobile-web-app-title" content="Dian Dian"><meta name="theme-color" content="#f5f0d0"></head>|' "$FRONTEND_DIR/dist/index.html"

# ── Systemd service ──
echo ""
echo "=== Setting up service ==="
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Dian Dian API + Frontend
After=network.target postgresql.service

[Service]
WorkingDirectory=$BACKEND_DIR
ExecStart=$NODE_PATH $BACKEND_DIR/dist/index.js
Restart=always
RestartSec=5
User=root
Group=root
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo ""
echo "=== Deploy complete ==="
sudo systemctl status $SERVICE_NAME --no-pager
