# MySQL Installation and Setup on Amazon EC2 (Amazon Linux 2023)

This guide explains how to install Oracle MySQL Community Server on an Amazon Linux 2023 EC2 instance, configure the MySQL root account, create a test database and table, and create a user with access to one database.

## Prerequisites

- An Amazon EC2 instance running Amazon Linux 2023
- SSH or EC2 Instance Connect access
- The default `ec2-user`, or another user with `sudo` privileges
- Internet access from the instance to `repo.mysql.com`
- At least enough free disk space for MySQL and its future data

Record the following details for your environment, but do not save real passwords in this README:

| Detail            | Example                                      |
| ----------------- | -------------------------------------------- |
| AWS Region        | `ap-south-1`                                 |
| CPU architecture  | `x86_64` or `aarch64`                        |
| Database name     | `new_user_db`                                |
| Database user     | `newuser`                                    |
| Connection source | `localhost` or an application security group |

## 1. Verify Amazon Linux and architecture

```bash
cat /etc/os-release
uname -m
```

The operating-system output should contain values similar to:

```text
NAME="Amazon Linux"
VERSION="2023"
ID="amzn"
VERSION_ID="2023"
PLATFORM_ID="platform:al2023"
```

## 2. Update Amazon Linux packages

```bash
sudo dnf update -y
```

Reboot if the update installed a new kernel or important system components:

```bash
sudo reboot
```

Reconnect to the instance after it reboots.

## 3. Add the MySQL Community repository

Install Oracle's MySQL repository configuration package:

```bash
sudo dnf install -y https://repo.mysql.com/mysql84-community-release-el9.rpm
```

Check the enabled MySQL repositories:

```bash
sudo dnf repolist enabled | grep mysql
```

The repository package may enable Oracle's current LTS release. Confirm the enabled release before installing if your application requires a specific MySQL major version.

## 4. Fix the repository URL for Amazon Linux 2023

Amazon Linux 2023 uses a date-based `$releasever`, such as `2023.12.20260727`. Oracle's repository expects an Enterprise Linux version such as `9`. Without this correction, DNF may return HTTP `404` for a URL containing `/el/2023.../`.

Back up the repository configuration:

```bash
sudo cp /etc/yum.repos.d/mysql-community.repo \
  /etc/yum.repos.d/mysql-community.repo.backup
```

Change `/el/$releasever/` to `/el/9/` in only the MySQL repository files:

```bash
sudo sed -i 's|/el/\$releasever/|/el/9/|g' \
  /etc/yum.repos.d/mysql-community*.repo
```

Verify the new repository URLs:

```bash
grep -n 'baseurl' /etc/yum.repos.d/mysql-community*.repo
```

The MySQL repository URLs should now contain `/el/9/` and not `/el/2023.../`.

Refresh the repository metadata:

```bash
sudo dnf clean all
sudo dnf makecache --refresh
```

## 5. Install MySQL Server

```bash
sudo dnf install -y mysql-community-server
```

Check the installed version:

```bash
mysql --version
```

## 6. Start and check the MySQL service

Oracle's RPM package uses the service name `mysqld`, not `mysql`:

```bash
sudo systemctl enable --now mysqld
sudo systemctl status mysqld --no-pager
```

The status should show `active (running)`.

If MySQL is not running, inspect its logs:

```bash
sudo journalctl -u mysqld --no-pager -n 100
sudo tail -n 100 /var/log/mysqld.log
```

## 7. Retrieve the temporary root password

On first initialization, MySQL writes a temporary root password to its log:

```bash
sudo grep 'temporary password' /var/log/mysqld.log
```

Copy the password shown at the end of the line. Do not store it in GitHub, shell scripts, screenshots, or this README.

## 8. Log in and change the MySQL root password

Log in using the temporary password:

```bash
mysql -u root -p
```

Enter the temporary password when prompted. Then run:

```sql
ALTER USER 'root'@'localhost'
IDENTIFIED BY 'YourUniqueStrongRootPassword';

EXIT;
```

The new password must satisfy MySQL's active password policy. Test the new password:

```bash
mysql -u root -p
```

> `FLUSH PRIVILEGES` is not required after `ALTER USER`, `CREATE USER`, `GRANT`, or `DROP USER`.

## 9. Create a test database and table

Log in as root:

```bash
mysql -u root -p
```

Run these queries:

```sql
CREATE DATABASE mysql_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE mysql_test;

CREATE TABLE table1 (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(45) NOT NULL
);

INSERT INTO table1 (name)
VALUES ('Test1');

SELECT * FROM table1;
```

Expected result:

```text
+----+-------+
| id | name  |
+----+-------+
|  1 | Test1 |
+----+-------+
```

## 10. Create a user with access to one database

Create a database for the user:

```sql
CREATE DATABASE new_user_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
```

Create a local user:

```sql
CREATE USER 'newuser'@'localhost'
IDENTIFIED BY 'YourUniqueStrongUserPassword';
```

Grant access to only `new_user_db`:

```sql
GRANT ALL PRIVILEGES
ON new_user_db.*
TO 'newuser'@'localhost';
```

Verify the permissions:

```sql
SHOW GRANTS FOR 'newuser'@'localhost';

EXIT;
```

Test the new account:

```bash
mysql -u newuser -p new_user_db
```

After logging in, test the assigned database:

```sql
SELECT USER(), CURRENT_USER(), DATABASE(), VERSION();
SHOW TABLES;
EXIT;
```

## 11. Delete the user or test databases

Log in as root:

```bash
mysql -u root -p
```

Delete the user only:

```sql
DROP USER 'newuser'@'localhost';
```

Delete the databases only when their data is no longer needed:

```sql
DROP DATABASE new_user_db;
DROP DATABASE mysql_test;
```

> Dropping a MySQL user does not automatically delete databases or their data. `DROP DATABASE` permanently deletes that database.

## 12. Run MySQL's security configuration tool

```bash
sudo mysql_secure_installation
```

Review every prompt carefully. For a normal standalone server:

- Remove anonymous users.
- Remove the test database.
- Disable remote login for `root`.
- Keep the password validation policy appropriate for your environment.

## Remote database access (only when required)

Keep the user restricted to `localhost` if the application runs on the same EC2 instance.

If an application on another private server must connect, use a narrow host or private subnet instead of `%`. For example:

```sql
CREATE USER 'app_user'@'10.0.1.%'
IDENTIFIED BY 'YourUniqueStrongAppPassword';

GRANT ALL PRIVILEGES
ON app_database.*
TO 'app_user'@'10.0.1.%';
```

You must also configure MySQL to listen on the required private interface and add an EC2 security-group inbound rule:

| Setting  | Value                                                    |
| -------- | -------------------------------------------------------- |
| Protocol | TCP                                                      |
| Port     | `3306`                                                   |
| Source   | Application server security group or narrow private CIDR |

Never expose MySQL to `0.0.0.0/0` or `::/0`, and never enable remote login for the MySQL `root` user.

Confirm which address and port MySQL is listening on:

```bash
sudo ss -lntp | grep 3306
```

## Security recommendations

- Replace every example password with a long, unique password.
- Never commit passwords, keys, or other secrets to GitHub.
- Keep TCP port `3306` closed unless remote access is required.
- Use private networking for remote database connections.
- Grant users only the permissions they require.
- Use a separate MySQL account for each application.
- Back up databases and test restoration before production use.
- Keep Amazon Linux and MySQL security updates current.
- Consider AWS Secrets Manager instead of storing application passwords in files.

## Useful service commands

```bash
# Start MySQL
sudo systemctl start mysqld

# Stop MySQL
sudo systemctl stop mysqld

# Restart MySQL
sudo systemctl restart mysqld

# Enable MySQL at boot
sudo systemctl enable mysqld

# Check its status
sudo systemctl status mysqld --no-pager

# View recent service logs
sudo journalctl -u mysqld --no-pager -n 100
```

## Troubleshooting the repository 404 error

If installation fails with a URL containing `/el/2023.../repodata/repomd.xml`, apply the repository correction again:

```bash
sudo sed -i 's|/el/\$releasever/|/el/9/|g' \
  /etc/yum.repos.d/mysql-community*.repo
sudo dnf clean all
sudo dnf makecache --refresh
sudo dnf install -y mysql-community-server
```

## Compatibility note

Amazon Linux 2023 is not Enterprise Linux 9. This setup uses Oracle's EL9 RPM repository because Oracle's repository configuration does not understand Amazon Linux's date-based `$releasever`. Test application compatibility and the upgrade process before using this setup in production. For a managed production database, consider Amazon RDS for MySQL. For a self-managed database, an operating system explicitly supported by Oracle MySQL can reduce package-compatibility risk.

## References

- [Oracle MySQL installation documentation](https://dev.mysql.com/doc/refman/8.4/en/linux-installation.html)
- [Oracle MySQL Yum repository](https://dev.mysql.com/downloads/repo/yum/)
- [Amazon Linux 2023 package management](https://docs.aws.amazon.com/linux/al2023/ug/package-management.html)

## License

This documentation is available for learning and personal use.
