#!/bin/bash

# Load NVM (Fix for "nvm: command not found" in non-interactive shell)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

SERVICE_NAME="year-checker"
WORKING_DIR="/root/year-checker"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
NODE_VERSION=$(nvm current)
NODE_PATH="$HOME/.nvm/versions/node/$NODE_VERSION/bin/node"

# Ensure Node.js version is detected
if [ -z "$NODE_VERSION" ]; then
    echo "Error: Node.js is not installed or not managed by nvm."
    exit 1
fi

# Move to working directory
echo "Moving to $WORKING_DIR..."
cd "$WORKING_DIR" || exit 1

# Stop the service if it's running
echo "Stopping $SERVICE_NAME service (if running)..."
sudo systemctl stop $SERVICE_NAME 2>/dev/null || true

# Install dependencies
echo "Installing dependencies..."
npm install

# Create the systemd service file
echo "Creating systemd service file at $SERVICE_FILE..."
cat <<EOF | sudo tee $SERVICE_FILE
[Unit]
Description=Year Checker Service
After=network.target

[Service]
EnvironmentFile=/etc/environment
WorkingDirectory=$WORKING_DIR
ExecStart=$NODE_PATH $WORKING_DIR/server.js
Restart=always
User=root
Group=root
Environment=NODE_ENV=production
ExecReload=/bin/kill -USR2 \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new service
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Enable the service to start on boot
echo "Enabling $SERVICE_NAME service..."
sudo systemctl enable $SERVICE_NAME

# Start the service
echo "Starting $SERVICE_NAME..."
sudo systemctl start $SERVICE_NAME

# Show service status
echo "Checking service status..."
sudo systemctl status $SERVICE_NAME --no-pager
