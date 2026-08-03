# Clone One Private GitHub Repository on Ubuntu EC2 Using a Deploy Key

This guide shows how to give an Ubuntu Amazon EC2 instance SSH access to **one private GitHub repository** by using a repository deploy key.

Deploy keys are attached to a single repository. Use a read-only deploy key when the EC2 instance only needs to clone and pull code.

## Quick setup with the interactive script

After logging in to the EC2 instance, copy [`setup-github-deploy-key.sh`](./setup-github-deploy-key.sh) to the server and run:

```bash
chmod +x setup-github-deploy-key.sh
./setup-github-deploy-key.sh
```

The script asks for:

- GitHub owner or organization
- GitHub repository name
- A deploy-key name (or press **Enter** to use the suggested name)

It then installs Git if needed, generates the key, configures SSH, displays the public key, and pauses while you add that key to GitHub. After you confirm, it verifies access and clones the repository.

> Run this script as the normal `ubuntu` user, not with `sudo`. The script requests `sudo` only if Git must be installed.

## Values you must replace

Search this document for `REPLACE_` to quickly find every value that needs to be changed.

| Placeholder | Replace it with | Example |
|---|---|---|
| `<REPLACE_EC2_KEY_PATH>` | Path to the EC2 `.pem` key on your local computer | `~/Downloads/my-server.pem` |
| `<REPLACE_EC2_PUBLIC_IP>` | Public IPv4 address or DNS name of the EC2 instance | `12.34.56.78` |
| `<REPLACE_REPO_KEY_NAME>` | Short filename for this repository's deploy key | `backend_api` |
| `<REPLACE_GITHUB_OWNER>` | GitHub username or organization that owns the repository | `my-company` |
| `<REPLACE_GITHUB_REPOSITORY>` | GitHub repository name | `backend-api` |

> Do not type the angle brackets (`<` and `>`) after replacing a placeholder.

## Prerequisites

- An Amazon EC2 instance running Ubuntu
- The EC2 `.pem` key and permission to connect to the instance
- Administrator access to the target GitHub repository
- EC2 security group inbound SSH access on port `22` from your IP address

## 1. Connect to the Ubuntu EC2 instance

Run these commands on your **local computer**, not on EC2:

```bash
chmod 400 <REPLACE_EC2_KEY_PATH>
ssh -i <REPLACE_EC2_KEY_PATH> ubuntu@<REPLACE_EC2_PUBLIC_IP>
```

Example:

```bash
chmod 400 ~/Downloads/my-server.pem
ssh -i ~/Downloads/my-server.pem ubuntu@12.34.56.78
```

All remaining terminal commands should be run on the EC2 instance.

## 2. Install Git

```bash
sudo apt update
sudo apt install -y git
git --version
```

## 3. Create the SSH directory

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

## 4. Generate a deploy key for this repository

Choose a descriptive value for `<REPLACE_REPO_KEY_NAME>`. Use only letters, numbers, hyphens, or underscores, and use the same value in every later command.

```bash
ssh-keygen -t ed25519 \
  -C "ec2-<REPLACE_REPO_KEY_NAME>-deploy-key" \
  -f ~/.ssh/github_<REPLACE_REPO_KEY_NAME>
```

When asked for a passphrase, press **Enter** twice to leave it empty. This permits unattended deployments and `git pull` operations. Protect access to the EC2 instance carefully.

For example, if the key name is `backend_api`, the command creates:

- `~/.ssh/github_backend_api` — private key; keep this secret on EC2
- `~/.ssh/github_backend_api.pub` — public key; add this to GitHub

Set safe file permissions:

```bash
chmod 600 ~/.ssh/github_<REPLACE_REPO_KEY_NAME>
chmod 644 ~/.ssh/github_<REPLACE_REPO_KEY_NAME>.pub
```

## 5. Display and copy the public key

```bash
cat ~/.ssh/github_<REPLACE_REPO_KEY_NAME>.pub
```

Copy the entire line, starting with `ssh-ed25519`.

> Only copy the file ending in `.pub`. Never share or upload the private-key file.

## 6. Add the public key to the GitHub repository

1. Open the target repository on GitHub.
2. Select **Settings**.
3. In the sidebar, select **Deploy keys**.
4. Select **Add deploy key**.
5. Enter a title such as `Production Ubuntu EC2`.
6. Paste the public key copied in the previous step.
7. Leave **Allow write access** unchecked when EC2 only needs to clone and pull.
8. Select **Add key**.

If **Deploy keys** is not visible, ask a repository administrator to add the key.

## 7. Configure SSH to use this deploy key

Open the SSH configuration file:

```bash
nano ~/.ssh/config
```

Add the following block. Replace `<REPLACE_REPO_KEY_NAME>` in both places with exactly the same key name used earlier:

```sshconfig
Host github-<REPLACE_REPO_KEY_NAME>
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_<REPLACE_REPO_KEY_NAME>
    IdentitiesOnly yes
```

Save and exit Nano:

1. Press `Ctrl+O`, then press `Enter`.
2. Press `Ctrl+X`.

Secure the configuration file:

```bash
chmod 600 ~/.ssh/config
```

The custom `Host` alias ensures that SSH uses this repository's deploy key, even when the server has other GitHub keys.

## 8. Test the GitHub SSH connection

```bash
ssh -T git@github-<REPLACE_REPO_KEY_NAME>
```

During the first connection, SSH may ask whether to trust GitHub's host key. Compare the displayed fingerprint with GitHub's official SSH key fingerprints. If it matches, enter:

```text
yes
```

A successful test displays a message similar to:

```text
Hi <owner>/<repository>! You've successfully authenticated, but GitHub does not provide shell access.
```

This command can still return exit status `1`; that is normal because GitHub provides Git access but not interactive shell access.

## 9. Clone the repository

Use the custom SSH host alias—not `github.com`—in the clone command:

```bash
git clone git@github-<REPLACE_REPO_KEY_NAME>:<REPLACE_GITHUB_OWNER>/<REPLACE_GITHUB_REPOSITORY>.git
```

Example:

```bash
git clone git@github-backend_api:my-company/backend-api.git
```

Enter the cloned directory and verify the remote:

```bash
cd <REPLACE_GITHUB_REPOSITORY>
git remote -v
```

## 10. Pull future updates

From inside the repository directory:

```bash
git pull
```

## Complete example

The following example uses:

- Key name: `backend_api`
- GitHub owner: `my-company`
- Repository: `backend-api`

```bash
ssh-keygen -t ed25519 \
  -C "ec2-backend_api-deploy-key" \
  -f ~/.ssh/github_backend_api

cat ~/.ssh/github_backend_api.pub
```

After adding the displayed public key to the repository's GitHub **Deploy keys**, configure SSH:

```sshconfig
Host github-backend_api
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_backend_api
    IdentitiesOnly yes
```

Then test and clone:

```bash
chmod 600 ~/.ssh/config ~/.ssh/github_backend_api
ssh -T git@github-backend_api
git clone git@github-backend_api:my-company/backend-api.git
```

## Troubleshooting

### `Permission denied (publickey)`

Confirm that the private key and SSH alias match the configuration:

```bash
ls -la ~/.ssh
ssh -vT git@github-<REPLACE_REPO_KEY_NAME>
```

Also confirm that:

- The `.pub` key was added to the correct GitHub repository.
- The clone URL uses `github-<REPLACE_REPO_KEY_NAME>`, not `github.com`.
- The `IdentityFile` path contains the correct private-key filename.
- The key files belong to the same Linux user running the Git command.

### `Repository not found`

Check the repository owner and repository name:

```bash
git clone git@github-<REPLACE_REPO_KEY_NAME>:<REPLACE_GITHUB_OWNER>/<REPLACE_GITHUB_REPOSITORY>.git
```

Repository names and owner names must match GitHub. Also verify that the deploy key is attached to that exact repository.

### `Host key verification failed`

Do not disable host-key checking. Verify GitHub's current SSH host-key fingerprints using GitHub's official documentation, then retry the SSH test.

### The repository was already cloned with the wrong URL

From inside the cloned repository, replace its remote URL:

```bash
git remote set-url origin git@github-<REPLACE_REPO_KEY_NAME>:<REPLACE_GITHUB_OWNER>/<REPLACE_GITHUB_REPOSITORY>.git
git remote -v
```

## Security notes

- Never add the private key to GitHub, source control, logs, or chat messages.
- Leave **Allow write access** disabled unless the EC2 instance must push changes.
- Use a separate deploy key for each repository.
- Restrict EC2 SSH access to trusted IP addresses.
- Remove the deploy key from GitHub when the EC2 instance is retired or access is no longer needed.
