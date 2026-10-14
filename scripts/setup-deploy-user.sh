#!/usr/bin/env bash
# Prepare a server to receive deployments from the pipeline.
# Run once per server as root:  sudo ./setup-deploy-user.sh /var/www/app
set -euo pipefail

APP_DIR="${1:?usage: $0 /path/to/app}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
fi

install -d -m 755 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$APP_DIR"
install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"

KEY_FILE="/home/$DEPLOY_USER/.ssh/gitlab_deploy"
if [[ ! -f "$KEY_FILE" ]]; then
  sudo -u "$DEPLOY_USER" ssh-keygen -q -t ed25519 -N "" -C "gitlab-deploy@$(hostname)" -f "$KEY_FILE"
  cat "$KEY_FILE.pub" >> "/home/$DEPLOY_USER/.ssh/authorized_keys"
  chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh/authorized_keys"
  chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
fi

cat <<EOF

Server is ready. Add these GitLab CI/CD variables, scoped to this environment:

  DEPLOY_USER      $DEPLOY_USER
  DEPLOY_HOST      $(hostname -I | awk '{print $1}')   (or the server's DNS name)
  APP_DIR          $APP_DIR
  SSH_PRIVATE_KEY  contents of $KEY_FILE  (type: Variable, Protected)
  SSH_KNOWN_HOSTS  output of: ssh-keyscan <DEPLOY_HOST>
  HEALTH_URL       https://<this environment's URL>/

Then delete the private key from the server:  shred -u $KEY_FILE
EOF
