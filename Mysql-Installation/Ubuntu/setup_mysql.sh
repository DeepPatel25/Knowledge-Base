#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="${0##*/}"
MYSQL_CLIENT_CONFIG=""

cleanup() {
    if [[ -n "${MYSQL_CLIENT_CONFIG}" && -f "${MYSQL_CLIENT_CONFIG}" ]]; then
        rm -f -- "${MYSQL_CLIENT_CONFIG}"
    fi
}

on_error() {
    local exit_code=$?
    printf '\nError: %s failed near line %s (exit code %s).\n' \
        "${SCRIPT_NAME}" "${BASH_LINENO[0]:-unknown}" "${exit_code}" >&2
    exit "${exit_code}"
}

trap cleanup EXIT
trap on_error ERR

log() {
    printf '\n==> %s\n' "$1"
}

require_ubuntu() {
    if [[ ! -r /etc/os-release ]]; then
        printf 'Error: Cannot identify this operating system. This script supports Ubuntu.\n' >&2
        exit 1
    fi

    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
        printf 'Error: This script supports Ubuntu, but detected: %s\n' "${PRETTY_NAME:-unknown}" >&2
        exit 1
    fi
}

prompt_identifier() {
    local prompt=$1
    local default_value=$2
    local value

    while true; do
        read -r -p "${prompt} [${default_value}]: " value
        value=${value:-$default_value}

        if [[ "$value" =~ ^[A-Za-z][A-Za-z0-9_]{0,63}$ ]]; then
            printf '%s' "$value"
            return
        fi

        printf 'Use 1-64 characters: letters, numbers, and underscores; start with a letter.\n' >&2
    done
}

prompt_password() {
    local first second

    while true; do
        read -r -s -p 'Password for the new MySQL user: ' first
        printf '\n' >&2

        if (( ${#first} < 12 )); then
            printf 'Use a password containing at least 12 characters.\n' >&2
            continue
        fi

        read -r -s -p 'Confirm password: ' second
        printf '\n' >&2

        if [[ "$first" == "$second" ]]; then
            MYSQL_USER_PASSWORD=$first
            return
        fi

        printf 'The passwords did not match. Try again.\n' >&2
    done
}

sql_escape_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\'/\'\'}
    printf '%s' "$value"
}

if [[ "${EUID}" -eq 0 ]]; then
    printf 'Run this script as a normal Ubuntu user with sudo access, not directly as root.\n' >&2
    exit 1
fi

require_ubuntu

printf 'MySQL database and user automation for Ubuntu\n'
printf 'You may be asked for your Ubuntu sudo password.\n\n'

DATABASE_NAME=$(prompt_identifier 'Database name' 'new_user_db')
MYSQL_USERNAME=$(prompt_identifier 'MySQL username' 'newuser')
prompt_password

printf '\nConfiguration:\n'
printf '  Database: %s\n' "$DATABASE_NAME"
printf '  User:     %s@localhost\n' "$MYSQL_USERNAME"
read -r -p 'Continue? [Y/n]: ' CONFIRM
if [[ "${CONFIRM:-Y}" =~ ^[Nn]$ ]]; then
    printf 'Cancelled. No changes were made by this script.\n'
    exit 0
fi

log 'Refreshing sudo credentials'
sudo -v

log 'Updating the Ubuntu package index'
sudo apt-get update

log 'Installing MySQL Server'
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

log 'Starting and enabling MySQL'
sudo systemctl enable --now mysql

if ! sudo systemctl is-active --quiet mysql; then
    printf 'Error: MySQL is not active. Check: sudo systemctl status mysql\n' >&2
    exit 1
fi

ESCAPED_PASSWORD=$(sql_escape_string "$MYSQL_USER_PASSWORD")

log 'Creating the database, user, permissions, and test table'
sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS \`${DATABASE_NAME}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY '${ESCAPED_PASSWORD}';
ALTER USER '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY '${ESCAPED_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DATABASE_NAME}\`.* TO '${MYSQL_USERNAME}'@'localhost';

USE \`${DATABASE_NAME}\`;
CREATE TABLE IF NOT EXISTS table1 (
    id INT PRIMARY KEY,
    name VARCHAR(45) NOT NULL
);
INSERT INTO table1 (id, name)
VALUES (1, 'Test1')
ON DUPLICATE KEY UPDATE name = VALUES(name);
SQL

log 'Creating a protected temporary client configuration for verification'
MYSQL_CLIENT_CONFIG=$(mktemp)
chmod 600 "$MYSQL_CLIENT_CONFIG"
cat >"$MYSQL_CLIENT_CONFIG" <<EOF
[client]
user=${MYSQL_USERNAME}
password=${MYSQL_USER_PASSWORD}
host=localhost
protocol=socket
EOF

log 'Verifying login, database access, permissions, and test data'
mysql --defaults-extra-file="$MYSQL_CLIENT_CONFIG" --database="$DATABASE_NAME" \
    --batch --skip-column-names \
    --execute="SELECT CONCAT('MySQL version: ', VERSION()); SELECT CONCAT('Database: ', DATABASE()); SELECT CONCAT('Test row: ', id, ', ', name) FROM table1 WHERE id = 1;"

GRANTS=$(sudo mysql --batch --skip-column-names \
    --execute="SHOW GRANTS FOR '${MYSQL_USERNAME}'@'localhost';")

if [[ "$GRANTS" != *"${DATABASE_NAME}"* ]]; then
    printf 'Error: Could not verify access to database %s.\n' "$DATABASE_NAME" >&2
    exit 1
fi

printf '\nSetup completed successfully.\n'
printf 'Database: %s\n' "$DATABASE_NAME"
printf 'User:     %s@localhost\n' "$MYSQL_USERNAME"
printf 'Login:    mysql -u %s -p %s\n' "$MYSQL_USERNAME" "$DATABASE_NAME"
printf '\nThe database and user were retained. No delete operations were performed.\n'
