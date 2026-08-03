#!/usr/bin/env bash

set -Eeuo pipefail

readonly SSH_DIR="$HOME/.ssh"

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

prompt_required() {
    local prompt="$1"
    local value=''

    while [[ -z "$value" ]]; do
        read -r -p "$prompt" value
    done

    printf '%s' "$value"
}

validate_github_name() {
    local label="$1"
    local value="$2"

    [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || \
        die "$label may contain only letters, numbers, dots, underscores, and hyphens."
}

printf '\nGitHub Deploy Key Setup for Ubuntu EC2\n'
printf '%s\n\n' '======================================='

github_owner="$(prompt_required 'GitHub owner or organization: ')"
repository_name="$(prompt_required 'GitHub repository name: ')"
default_key_name="${repository_name//-/_}"
read -r -p "Deploy-key name [$default_key_name]: " key_name
key_name="${key_name:-$default_key_name}"

validate_github_name 'GitHub owner' "$github_owner"
validate_github_name 'Repository name' "$repository_name"
validate_github_name 'Deploy-key name' "$key_name"

key_file="$SSH_DIR/github_$key_name"
host_alias="github-$key_name"
clone_url="git@$host_alias:$github_owner/$repository_name.git"

printf '\nConfiguration\n'
printf '  GitHub owner:  %s\n' "$github_owner"
printf '  Repository:    %s\n' "$repository_name"
printf '  Private key:   %s\n' "$key_file"
printf '  SSH alias:     %s\n' "$host_alias"
printf '  Clone URL:     %s\n\n' "$clone_url"

read -r -p 'Continue? [y/N]: ' confirmation
[[ "$confirmation" =~ ^[Yy]$ ]] || die 'Setup cancelled.'

if ! command -v git >/dev/null 2>&1; then
    printf '\nInstalling Git...\n'
    sudo apt update
    sudo apt install -y git
else
    printf '\nGit is already installed: %s\n' "$(git --version)"
fi

command -v ssh-keygen >/dev/null 2>&1 || die 'ssh-keygen is not installed.'

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ -e "$key_file" || -e "$key_file.pub" ]]; then
    die "A key already exists at $key_file. Choose another deploy-key name or reuse the existing key manually."
fi

printf '\nGenerating the repository deploy key...\n'
ssh-keygen -t ed25519 -C "ec2-$key_name-deploy-key" -f "$key_file" -N ''
chmod 600 "$key_file"
chmod 644 "$key_file.pub"

config_file="$SSH_DIR/config"
touch "$config_file"
chmod 600 "$config_file"

if grep -Eq "^[[:space:]]*Host[[:space:]]+$host_alias([[:space:]]|$)" "$config_file"; then
    die "SSH alias '$host_alias' already exists in $config_file. The new key remains at $key_file."
fi

{
    printf '\nHost %s\n' "$host_alias"
    printf '    HostName github.com\n'
    printf '    User git\n'
    printf '    IdentityFile %s\n' "$key_file"
    printf '    IdentitiesOnly yes\n'
} >> "$config_file"

printf '\n============================================================\n'
printf 'COPY THIS PUBLIC KEY AND ADD IT TO THE GITHUB REPOSITORY:\n'
printf 'Repository: https://github.com/%s/%s/settings/keys\n' "$github_owner" "$repository_name"
printf 'Leave "Allow write access" unchecked for clone/pull access.\n'
printf '============================================================\n\n'
cat "$key_file.pub"
printf '\n============================================================\n'

read -r -p 'Press Enter after you have added the deploy key to GitHub...'

printf '\nTesting the GitHub SSH connection...\n'
printf 'On the first connection, verify GitHub’s fingerprint and enter "yes".\n\n'

set +e
ssh -T "git@$host_alias"
ssh_status=$?
set -e

# GitHub normally returns status 1 after successful authentication because it
# does not provide shell access. Confirm repository access with ls-remote.
if [[ $ssh_status -gt 1 ]]; then
    die 'SSH authentication failed. Confirm that the public key was added to the correct repository.'
fi

printf '\nVerifying repository access...\n'
git ls-remote "$clone_url" HEAD >/dev/null || \
    die 'GitHub authentication worked, but this key cannot access the repository. Check the owner, repository name, and deploy key.'

if [[ -e "$repository_name" ]]; then
    die "A file or directory named '$repository_name' already exists. Repository access is working, but cloning was skipped."
fi

printf '\nCloning %s/%s...\n' "$github_owner" "$repository_name"
git clone "$clone_url"

printf '\nSetup complete.\n'
printf 'Repository directory: %s/%s\n' "$PWD" "$repository_name"
printf 'To enter it, run: cd %q\n' "$repository_name"
printf 'To pull future updates, run: git pull\n'
