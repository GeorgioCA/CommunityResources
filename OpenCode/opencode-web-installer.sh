#!/usr/bin/env bash
set -e

CONFIG_DIR="/root/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
ENV_FILE="/etc/opencode.env"
SERVICE_FILE="/etc/systemd/system/opencode.service"
BINARY="/root/.opencode/bin/opencode"

echo "=== OpenCode Setup Script ==="

# -----------------------------
# Inputs
# -----------------------------
read -rp "Port [4096]: " PORT
PORT=${PORT:-4096}

read -rp "Hostname [0.0.0.0]: " HOSTNAME
HOSTNAME=${HOSTNAME:-0.0.0.0}

read -rp "CORS domain (e.g. https://dev.example.com): " CORS

read -rp "Server username [opencode]: " USERNAME
USERNAME=${USERNAME:-opencode}

read -rp "Server password (leave blank to keep existing): " PASSWORD

# -----------------------------
# Install check
# -----------------------------
if [ ! -f "$BINARY" ]; then
  echo "Installing OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
fi

# -----------------------------
# Config file (no auth here)
# -----------------------------
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "server": {
    "port": $PORT,
    "hostname": "$HOSTNAME",
    "cors": ["$CORS"]
  }
}
EOF

# -----------------------------
# Environment file (AUTH lives here)
# -----------------------------
touch "$ENV_FILE"

# update username
grep -v "^OPENCODE_SERVER_USERNAME=" "$ENV_FILE" > "${ENV_FILE}.tmp" || true
echo "OPENCODE_SERVER_USERNAME=$USERNAME" >> "${ENV_FILE}.tmp"
mv "${ENV_FILE}.tmp" "$ENV_FILE"

# update password only if provided
if [ -n "$PASSWORD" ]; then
  grep -v "^OPENCODE_SERVER_PASSWORD=" "$ENV_FILE" > "${ENV_FILE}.tmp" || true
  echo "OPENCODE_SERVER_PASSWORD=$PASSWORD" >> "${ENV_FILE}.tmp"
  mv "${ENV_FILE}.tmp" "$ENV_FILE"
fi

# -----------------------------
# Systemd service
# -----------------------------
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=OpenCode Web Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root

EnvironmentFile=$ENV_FILE
ExecStart=$BINARY web

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# -----------------------------
# Apply
# -----------------------------
systemctl daemon-reload
systemctl enable opencode
systemctl restart opencode

echo ""
echo "=== DONE ==="
systemctl status opencode --no-pager
