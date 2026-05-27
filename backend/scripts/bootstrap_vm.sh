#!/usr/bin/env bash
# One-shot bootstrap for the XPulse backend on an Oracle Linux 8/9 VM.
# Idempotent — safe to re-run.
#
# Usage on the VM (as the `opc` user):
#   curl -fsSL https://raw.githubusercontent.com/Unexplo/XPulse/main/backend/scripts/bootstrap_vm.sh | bash
# or:
#   scp backend/scripts/bootstrap_vm.sh opc@<vm-ip>:~ && ssh opc@<vm-ip> bash ~/bootstrap_vm.sh

set -euo pipefail

REPO_URL="https://github.com/Unexplo/XPulse.git"
APP_DIR="/opt/xpulse/app"
BACKEND_DIR="${APP_DIR}/backend"
VENV_DIR="${BACKEND_DIR}/.venv"
SERVICE_NAME="xpulse"
SERVICE_USER="opc"

echo "==> [1/6] Installing system packages"
sudo dnf install -y --quiet git python3.12 python3.12-pip

echo "==> [2/6] Preparing ${APP_DIR}"
sudo mkdir -p /opt/xpulse
sudo chown "${SERVICE_USER}:${SERVICE_USER}" /opt/xpulse

if [ -d "${APP_DIR}/.git" ]; then
  echo "    repo already present — pulling latest"
  git -C "${APP_DIR}" fetch --all
  git -C "${APP_DIR}" reset --hard origin/main
else
  echo "    cloning ${REPO_URL}"
  git clone "${REPO_URL}" "${APP_DIR}"
fi

echo "==> [3/6] Creating venv and installing deps"
if [ ! -d "${VENV_DIR}" ]; then
  python3.12 -m venv "${VENV_DIR}"
fi
"${VENV_DIR}/bin/pip" install --quiet --upgrade pip
"${VENV_DIR}/bin/pip" install --quiet -r "${BACKEND_DIR}/requirements.txt"

echo "==> [4/6] Writing systemd unit /etc/systemd/system/${SERVICE_NAME}.service"
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<EOF
[Unit]
Description=XPulse FastAPI backend
After=network.target

[Service]
User=${SERVICE_USER}
WorkingDirectory=${BACKEND_DIR}
ExecStart=${VENV_DIR}/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "==> [5/6] Granting passwordless restart via /etc/sudoers.d/${SERVICE_NAME}-deploy"
sudo tee "/etc/sudoers.d/${SERVICE_NAME}-deploy" >/dev/null <<EOF
${SERVICE_USER} ALL=(root) NOPASSWD: /bin/systemctl restart ${SERVICE_NAME}
EOF
sudo chmod 440 "/etc/sudoers.d/${SERVICE_NAME}-deploy"

echo "==> [6/6] Enabling and starting ${SERVICE_NAME}"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}" >/dev/null
sudo systemctl restart "${SERVICE_NAME}"

sleep 2
echo "==> Smoke-testing http://127.0.0.1:8000/health"
curl -fsS http://127.0.0.1:8000/health && echo
echo "==> Done. Service status:"
sudo systemctl --no-pager --lines=0 status "${SERVICE_NAME}" | head -5
