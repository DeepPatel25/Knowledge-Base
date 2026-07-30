#!/usr/bin/env bash

set -Eeuo pipefail

MYSQL_CONFIG=""
MYSQL_COMMAND=(sudo mysql)

cleanup() {
    if [[ -n "$MYSQL_CONFIG" && -f "$MYSQL_CONFIG" ]]; then
        rm -f -- "$MYSQL_CONFIG"
    fi
}

error_handler() {
    local exit_code=$?
    printf '\nPassword update failed near line %s (exit code %s).\n' \
        "${BASH_LINENO[0]:-unknown}" "$exit_code" >&2
    exit "$exit_code"
}

trap cleanup EXIT
trap error_handler ERR

sql_escape_string() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\'/\'\'}
    printf '%s' "$value"
}

if ! command -v mysql >/dev/null 2>&1; then
    printf 'MySQL is not installed. Run install_mysql.sh first.\n' >&2
    exit 1
fi

if ! sudo systemctl is-active --quiet mysql; then
    printf 'MySQL is not running. Start it with: sudo systemctl start mysql\n' >&2
    exit 1
fi

printf 'MySQL root password configuration\n\n'

# A new Ubuntu MySQL installation normally permits administrative access through
# `sudo mysql`. If that is no longer available, authenticate with the current
# MySQL root password through a protected temporary option file.
if ! sudo mysql --batch --skip-column-names --execute='SELECT 1;' >/dev/null 2>&1; then
    read -r -s -p 'Current MySQL root password: ' current_password
    printf '\n'

    MYSQL_CONFIG=$(mktemp)
    chmod 600 "$MYSQL_CONFIG"
    printf '[client]\nuser=root\npassword=%s\nhost=localhost\nprotocol=socket\n' \
        "$current_password" >"$MYSQL_CONFIG"
    unset current_password

    MYSQL_COMMAND=(mysql "--defaults-extra-file=$MYSQL_CONFIG")

    if ! "${MYSQL_COMMAND[@]}" --batch --execute='SELECT 1;' >/dev/null 2>&1; then
        printf 'Authentication failed. The current root password is incorrect.\n' >&2
        exit 1
    fi
fi

while true; do
    read -r -s -p 'New MySQL root password: ' new_password
    printf '\n'

    if (( ${#new_password} < 12 )); then
        printf 'Use a password containing at least 12 characters.\n' >&2
        continue
    fi

    read -r -s -p 'Confirm new password: ' confirmed_password
    printf '\n'

    if [[ "$new_password" == "$confirmed_password" ]]; then
        break
    fi

    printf 'Passwords did not match. Try again.\n' >&2
done

escaped_password=$(sql_escape_string "$new_password")

"${MYSQL_COMMAND[@]}" --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${escaped_password}';"

# Re-create the temporary configuration with the new password for verification.
cleanup
MYSQL_CONFIG=$(mktemp)
chmod 600 "$MYSQL_CONFIG"
printf '[client]\nuser=root\npassword=%s\nhost=localhost\nprotocol=socket\n' \
    "$new_password" >"$MYSQL_CONFIG"
unset new_password confirmed_password escaped_password

if ! mysql --defaults-extra-file="$MYSQL_CONFIG" --batch --skip-column-names \
    --execute="SELECT CONCAT('Authenticated as: ', CURRENT_USER());"; then
    printf 'The password was changed, but password-login verification failed.\n' >&2
    exit 1
fi

printf '\nMySQL root password changed and verified successfully.\n'
printf 'Future login command: mysql -u root -p\n'
printf 'The password was not saved permanently by this script.\n'
