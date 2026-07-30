# MySQL Installation and Setup on Amazon EC2 (Ubuntu)

This guide explains how to install MySQL Server on an Ubuntu-based Amazon EC2 instance, configure the MySQL root account, create a test database, and create a user with access to one database.

## Prerequisites

- An Amazon EC2 instance running Ubuntu
- SSH access to the instance
- A user with `sudo` privileges

## 1. Update Ubuntu packages

Update the package index:

```bash
sudo apt update
```

Optionally, upgrade the installed packages:

```bash
sudo apt upgrade -y
```

## 2. Install MySQL Server

```bash
sudo apt install mysql-server -y
```

## 3. Check the MySQL service

Check whether MySQL is running:

```bash
sudo systemctl status mysql
```

Press `q` to exit the status screen.

If MySQL is not running, start it:

```bash
sudo systemctl start mysql
```

Enable MySQL to start automatically after a system reboot:

```bash
sudo systemctl enable mysql
```

## 4. Log in as the MySQL root user

On Ubuntu, the initial root login normally uses socket authentication:

```bash
sudo mysql
```

### Set a password for root

For newer MySQL versions, run the following inside the MySQL prompt:

```sql
ALTER USER 'root'@'localhost'
IDENTIFIED WITH caching_sha2_password BY 'YourStrongPassword';

EXIT;
```

After changing the authentication method, log in with the password:

```bash
mysql -u root -p
```

Enter the password when prompted.

> `FLUSH PRIVILEGES` is not required after commands such as `ALTER USER`, `CREATE USER`, or `GRANT`.

### Older MySQL installations

An older client may require `mysql_native_password`:

```sql
ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password BY 'YourStrongPassword';

EXIT;
```

Use `mysql_native_password` only when an older client requires it. Newer MySQL versions prefer `caching_sha2_password`.

## 5. Create a test database and table

Log in as root:

```bash
mysql -u root -p
```

Run these queries inside the MySQL prompt:

```sql
CREATE DATABASE mysql_test;

USE mysql_test;

CREATE TABLE table1 (
    id INT,
    name VARCHAR(45)
);

INSERT INTO table1 (id, name)
VALUES (1, 'Test1');

SELECT * FROM table1;
```

Expected result:

```text
+------+-------+
| id   | name  |
+------+-------+
|    1 | Test1 |
+------+-------+
```

## 6. Create a user with access to one database

Log in as root:

```bash
mysql -u root -p
```

Create a database for the user:

```sql
CREATE DATABASE new_user_db;
```

Create the user:

```sql
CREATE USER 'newuser'@'localhost'
IDENTIFIED BY 'YourStrongUserPassword';
```

Grant the user access to only `new_user_db`:

```sql
GRANT ALL PRIVILEGES
ON new_user_db.*
TO 'newuser'@'localhost';
```

Verify the permissions:

```sql
SHOW GRANTS FOR 'newuser'@'localhost';
```

Exit MySQL:

```sql
EXIT;
```

Test the new account:

```bash
mysql -u newuser -p
```

After logging in, test access to the assigned database:

```sql
USE new_user_db;
SHOW TABLES;
```

## 7. Delete the user

Log in as root and run:

```sql
DROP USER 'newuser'@'localhost';
```

To delete the database as well:

```sql
DROP DATABASE new_user_db;
```

> Dropping a MySQL user does not automatically delete the user's database.

## Security recommendations

- Replace all example passwords with long, unique passwords.
- Never commit real passwords, API keys, or private keys to GitHub.
- Keep the MySQL port (`3306`) closed to the public unless remote access is specifically required.
- Grant users only the permissions they need.
- Consider running MySQL's security configuration tool:

```bash
sudo mysql_secure_installation
```

## Useful service commands

```bash
# Start MySQL
sudo systemctl start mysql

# Stop MySQL
sudo systemctl stop mysql

# Restart MySQL
sudo systemctl restart mysql

# Check its status
sudo systemctl status mysql
```

## License

This documentation is available for learning and personal use.
