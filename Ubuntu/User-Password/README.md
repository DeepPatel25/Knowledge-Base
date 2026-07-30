# Ubuntu User Password on Amazon EC2

Amazon EC2 Ubuntu instances normally use an SSH key instead of a Linux account password. The default `ubuntu` user is usually allowed to run `sudo` commands without entering a password.

## Connect to the EC2 instance

Use the private key that belongs to the EC2 key pair:

```bash
ssh -i "your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

## Check sudo access

Run:

```bash
sudo -l
```

You can also refresh or verify the current sudo authorization:

```bash
sudo -v
```

On a standard EC2 Ubuntu instance, these commands normally do not request an Ubuntu password.

## Check the Ubuntu account password status

```bash
sudo passwd -S ubuntu
```

If the output contains `L`, the password is locked. This is normal because EC2 generally uses SSH-key authentication.

Linux passwords cannot be displayed or recovered. The system stores a cryptographic password hash rather than the original password.

## Set or change the Ubuntu user password

To assign a password to the `ubuntu` user, run:

```bash
sudo passwd ubuntu
```

You will be prompted to enter the new password twice:

```text
New password:
Retype new password:
passwd: password updated successfully
```

Characters are not displayed while entering a password. This is expected.

## Test the password locally

Switch to the `ubuntu` user from another privileged account:

```bash
su - ubuntu
```

Enter the new password when prompted.

> Setting an Ubuntu password does not necessarily enable password-based SSH access.

## Recommended EC2 security practice

- Continue using an EC2 SSH key or AWS Systems Manager to access the instance.
- Do not enable SSH password authentication unless it is specifically required.
- Use a long, unique password if you assign one.
- Never place passwords or private-key contents in a GitHub repository.
- Restrict SSH access in the EC2 security group to trusted IP addresses.

## Credential differences

| Credential           | Purpose                                        |
| -------------------- | ---------------------------------------------- |
| EC2 SSH private key  | Connect to the EC2 instance over SSH           |
| Ubuntu user password | Local Linux account authentication             |
| Sudo authorization   | Run administrative Linux commands              |
| MySQL root password  | Authenticate to MySQL using `mysql -u root -p` |

These credentials are separate and should not be confused with one another.
