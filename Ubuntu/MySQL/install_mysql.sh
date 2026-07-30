#!/usr/bin/env bash

set -Eeuo pipefail

error_handler() {
    local exit_code=$?
    printf '\nInstallation failed near line %s (exit code %s).\n' \
        "${BASH_LINENO[0]:-unknown}" "$exit_code" >&2
    exit "$exit_code"
}

trap error_handler ERR

if [[ "$EUID" -eq 0 ]]; then
    printf 'Run this script as a normal Ubuntu user with sudo access, not as root.\n' >&2
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    printf 'Unable to identify the operating system. This script supports Ubuntu.\n' >&2
    exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    printf 'This script supports Ubuntu. Detected: %s\n' "${PRETTY_NAME:-unknown}" >&2
    exit 1
fi

printf 'This script will update the package index and install MySQL Server.\n'
read -r -p 'Continue? [Y/n]: ' confirmation

if [[ "${confirmation:-Y}" =~ ^[Nn]$ ]]; then
    printf 'Installation cancelled.\n'
    exit 0
fi

printf '\n==> Checking sudo access\n'
sudo -v

printf '\n==> Updating the Ubuntu package index\n'
sudo apt-get update

printf '\n==> Installing MySQL Server\n'
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

printf '\n==> Starting and enabling MySQL\n'
sudo systemctl enable --now mysql

printf '\n==> Verifying the MySQL service\n'
if ! sudo systemctl is-active --quiet mysql; then
    printf 'MySQL is not active. Run: sudo systemctl status mysql\n' >&2
    exit 1
fi

MYSQL_VERSION=$(mysql --version)

printf '\nMySQL installation completed successfully.\n'
printf '%s\n' "$MYSQL_VERSION"
printf 'Service status: active\n'
printf '\nInitial administrative login:\n  sudo mysql\n'
printf '\nTo configure the root password, run change_mysql_root_password.sh next.\n'

