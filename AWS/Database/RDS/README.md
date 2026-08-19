# Amazon RDS (Relational Database Service)

[← Back to AWS Databases](../README.md) · [AWS learning path](../../README.md)

Amazon Relational Database Service (Amazon RDS) is a managed relational
database service that simplifies database setup, operation, monitoring,
backups, patching, recovery, and scaling.

This guide covers the core RDS concepts from the AWS database learning
section, including supported database engines, a practical MySQL setup,
Amazon Aurora, Multi-AZ deployments, Read Replicas, backups, monitoring,
security, and common use cases.

> Use a sandbox/non-production AWS account while learning. Database
> instances, storage, backups, and cross-Region resources can incur
> charges.

## Table of Contents

-   [Learning objectives](#learning-objectives)
-   [Prerequisites](#prerequisites)
-   [What is Amazon RDS?](#what-is-amazon-rds)
-   [Why use RDS?](#why-use-rds)
-   [Supported database engines](#supported-database-engines)
-   [Core RDS features](#core-rds-features)
-   [RDS architecture concepts](#rds-architecture-concepts)
    -   [Multi-AZ deployment](#multi-az-deployment)
    -   [Read Replicas](#read-replicas)
    -   [Multi-AZ vs Read Replicas](#multi-az-vs-read-replicas)
-   [Amazon Aurora](#amazon-aurora)
-   [Practical lab: EC2 application with RDS
    MySQL](#practical-lab-ec2-application-with-rds-mysql)
-   [Connecting to RDS MySQL](#connecting-to-rds-mysql)
-   [Backups and recovery](#backups-and-recovery)
-   [Monitoring](#monitoring)
-   [Security](#security)
-   [Scaling](#scaling)
-   [Common use cases](#common-use-cases)
-   [Verification checklist](#verification-checklist)
-   [Troubleshooting](#troubleshooting)
-   [Cleanup](#cleanup)
-   [Key takeaways](#key-takeaways)
-   [Knowledge check](#knowledge-check)
-   [References](#references)
-   [Related AWS topics](#related-aws-topics)

------------------------------------------------------------------------

## Learning objectives

After completing this guide, you should be able to:

- Explain the shared-responsibility boundary between AWS and an RDS customer.
- Choose an RDS database engine and basic instance configuration for a workload.
- Distinguish Multi-AZ deployments, Read Replicas, backups, and snapshots.
- Place an RDS database in a VPC and restrict connectivity with security groups.
- Connect an EC2-hosted application to a private RDS for MySQL database.
- Monitor, scale, back up, restore, troubleshoot, and safely delete an RDS instance.
- Explain when Amazon Aurora may be appropriate.

## Prerequisites

Use a sandbox account with billing alerts enabled. Before starting the lab, you
should understand VPCs, subnets, route tables, security groups, EC2, IAM roles,
and basic MySQL administration. Use non-production data and choose the smallest
database class suitable for learning after reviewing current regional pricing.

------------------------------------------------------------------------

## What is Amazon RDS?

Amazon RDS is a managed database service for relational databases.

Instead of manually managing database infrastructure, RDS handles many
operational tasks such as:

-   Database provisioning
-   Backups
-   Patching
-   Monitoring
-   Recovery
-   Scaling
-   High-availability configuration

You still manage your application data, database schema, queries, users,
and access rules, while AWS manages much of the underlying database
infrastructure.

AWS operates the managed service infrastructure, but you remain responsible
for engine selection and configuration, schemas, users, query design, data
classification, network access, backup and recovery objectives, monitoring,
and validating application behavior during maintenance or failover.

------------------------------------------------------------------------

## Why use RDS?

RDS is useful when an application requires a relational database but you
do not want to manage the complete database server lifecycle yourself.

Key benefits include:

-   High availability and fault tolerance
-   Vertical and read-oriented horizontal scaling
-   Automated backups and recovery
-   Read Replicas for read-heavy workloads
-   Multi-AZ deployments for disaster recovery and availability
-   Managed monitoring
-   Network isolation using VPCs and security groups
-   Encryption and access-control options
-   Reduced operational overhead

------------------------------------------------------------------------

## Supported database engines

Amazon RDS supports multiple relational database engines, including:

| Engine | Typical use |
| --- | --- |
| Amazon Aurora MySQL-Compatible Edition | AWS-designed, MySQL-compatible workloads |
| Amazon Aurora PostgreSQL-Compatible Edition | AWS-designed, PostgreSQL-compatible workloads |
| MySQL | General-purpose open-source relational workloads |
| PostgreSQL | Advanced open-source relational workloads |
| MariaDB | MySQL-compatible open-source workloads |
| Oracle Database | Enterprise Oracle workloads |
| Microsoft SQL Server | Microsoft SQL Server applications |
| IBM Db2 | Enterprise Db2 workloads |

The exact engine versions and features available can vary by AWS Region.

------------------------------------------------------------------------

## Core RDS features

| Feature | How it works | Purpose |
| --- | --- | --- |
| **Multi-AZ deployment** | Maintains database capacity in more than one Availability Zone and supports failover | High availability and fault tolerance |
| **Read Replicas** | Replicates data to readable database instances | Scale read-heavy workloads |
| **Automated backups** | Creates backups and captures transaction logs | Point-in-time recovery |
| **Manual snapshots** | Retains user-created database snapshots until explicitly deleted | Long-term recovery points and migration |
| **VPC and security groups** | Controls network placement and permitted connectivity | Network isolation and restricted access |
| **CloudWatch, Enhanced Monitoring, and database insights** | Provides database, operating-system, and query-related telemetry depending on configuration | Performance analysis and troubleshooting |
| **Encryption and IAM controls** | Protects storage and connections and controls AWS API access | Data protection and service administration |

------------------------------------------------------------------------

## RDS architecture concepts

### Multi-AZ deployment

A Multi-AZ deployment is primarily designed for **high availability**.

A typical setup contains:

``` text
                 AWS Region
        ┌───────────────────────────┐
        │                           │
        │  Availability Zone A      │
        │  ┌─────────────────────┐  │
Client ───▶│ Primary DB Instance │  │
        │  └──────────┬──────────┘  │
        │             │             │
        │     Synchronous           │
        │      replication          │
        │             │             │
        │  Availability Zone B      │
        │  ┌──────────▼──────────┐  │
        │  │ Standby DB Instance │  │
        │  └─────────────────────┘  │
        │                           │
        └───────────────────────────┘
```

The standby instance exists to improve availability. In the standard
Multi-AZ DB instance model, application traffic uses the primary
database endpoint and the standby is not used as a normal read-scaling
target.

Use Multi-AZ when the main requirement is:

-   High availability
-   Fault tolerance
-   Automatic failover
-   Disaster-recovery readiness within a Region

### Read Replicas

Read Replicas are primarily designed to **scale read traffic**.

``` text
        Primary RDS DB
       Read / Write traffic
              │
              │ Asynchronous replication
              ▼
       RDS Read Replica
         Read-only traffic
```

A Read Replica can serve read-only queries so that reporting, analytics,
or other read-heavy operations do not place all load on the primary
database.

Depending on the engine and configuration, replicas can be placed in
another Availability Zone or Region.

Use Read Replicas when the main requirement is:

-   Read scaling
-   Reducing read load on the primary database
-   Serving geographically distributed read workloads

### Multi-AZ vs Read Replicas

| Topic | Multi-AZ deployment | Read Replica |
| --- | --- | --- |
| Primary goal | High availability | Read scalability |
| Replication | Typically synchronous for standby capacity | Typically asynchronous |
| Read traffic | A standby in the standard Multi-AZ DB instance model does not serve normal reads | A replica serves read traffic |
| Failover | Designed for automatic failover | Promotion is possible, but automatic HA failover is not its primary purpose |
| Cross-Region | Normally an in-Region HA design | Supported configurations can use cross-Region replicas |
| Best for | Production availability | Read-heavy workloads |

A production system can use both approaches when it needs high
availability **and** additional read capacity.

------------------------------------------------------------------------

## Amazon Aurora

Amazon Aurora is an AWS relational database engine compatible with MySQL
or PostgreSQL.

The learning material highlights Aurora features such as:

-   Higher throughput compared with standard community database engines
-   Automatically scaling distributed storage
-   Replication across multiple Availability Zones
-   Multiple Read Replicas
-   Low replica lag
-   Automatic monitoring and failover

Aurora is useful when an application needs a managed relational database
with AWS-designed storage, replication, availability, and scaling
capabilities.

------------------------------------------------------------------------

## Practical lab: EC2 application with RDS MySQL

The practical architecture is:

``` text
┌──────────────────────────┐
│ EC2 Instance             │
│                          │
│ Docker                   │
│ └── Node.js Application  │
└────────────┬─────────────┘
             │
             │ TCP 3306
             ▼
┌──────────────────────────┐
│ Amazon RDS               │
│ MySQL                    │
└──────────────────────────┘
```

### 1. Create an RDS MySQL database

From the AWS Management Console:

1.  Open **RDS**.
2.  Choose **Create database**.
3.  Select **MySQL**.
4.  Choose a template appropriate for your learning environment.
5.  Configure the DB instance identifier.
6.  Configure the master username and use RDS-managed credentials in AWS
    Secrets Manager when suitable; otherwise store the password securely.
7.  Select the VPC and a DB subnet group covering subnets in at least two
    Availability Zones.
8.  Set **Public access** to **No** for the EC2-to-RDS architecture.
9.  Configure the database security group and enable storage encryption.
10. Configure backup retention, maintenance, monitoring, and deletion
    protection deliberately. Deletion protection can be disabled for a
    disposable lab only if you understand the cleanup risk.
11. Create the database.
12. Wait until the DB instance status becomes **Available**.
13. Copy the RDS **endpoint** and note the port.

For MySQL, the default port is:

``` text
3306
```

### 2. Configure network access

Prefer keeping the RDS database private when the application runs inside
the same VPC.

For an EC2-to-RDS setup, configure the RDS security group to allow MySQL
traffic from the **EC2 instance's security group**:

``` text
Type:        MySQL/Aurora
Protocol:    TCP
Port:        3306
Source:      <EC2_SECURITY_GROUP_ID>
```

For temporary local learning access, restrict the source to your own
public IP rather than exposing port `3306` to the entire internet.

> Do not use `0.0.0.0/0` for database access in a normal setup. Restrict
> database connectivity to the smallest trusted source possible.

### 3. Prepare the EC2 instance

Example commands for an Amazon Linux-based EC2 instance:

``` bash
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
```

After adding `ec2-user` to the Docker group, sign out and sign back in
before running Docker without `sudo`.

Pull the sample application image:

``` bash
docker pull philippaul/node-mysql-app:02
```

This is a third-party demonstration image. Inspect its source and image metadata
before running it, use only non-production credentials and data, and pin a
reviewed image digest when reproducibility matters.

### 4. Run the Node.js application

Replace the placeholders with your RDS values:

``` bash
docker run --rm \
  -p 80:3000 \
  -e DB_HOST="YOUR_RDS_ENDPOINT" \
  -e DB_USER="YOUR_DB_USERNAME" \
  -e DB_PASSWORD="YOUR_DB_PASSWORD" \
  -d philippaul/node-mysql-app:02
```

The flow is then:

``` text
Browser
   │
   ▼
EC2 :80
   │
   ▼
Docker / Node.js App :3000
   │
   ▼
RDS MySQL :3306
```

> Do not commit database passwords to this repository. For real
> applications, retrieve credentials at runtime from AWS Secrets Manager or
> another approved secrets system and rotate them. Environment variables can
> be exposed through shell history, process tooling, logs, or container
> inspection, so the command above is suitable only for a disposable lab.

------------------------------------------------------------------------

## Connecting to RDS MySQL

You can test database connectivity with a MySQL client.

Using the MySQL Docker image:

``` bash
docker run -it --rm mysql:8.0 \
  mysql \
  -h YOUR_RDS_ENDPOINT \
  -u YOUR_DB_USERNAME \
  -p
```

Enter the password interactively when prompted.

Once connected:

``` sql
SELECT VERSION();

SHOW DATABASES();
```

If the connection succeeds, the network path, security-group rule,
endpoint, credentials, and MySQL listener are working.

------------------------------------------------------------------------

## Backups and recovery

### Automated backups

Automated backups help with database recovery and point-in-time restore.

They are useful for:

-   Recovering accidentally modified or deleted data
-   Restoring a database to an earlier point in time
-   Operational disaster recovery

Set retention according to the recovery-point objective and test restores.
Point-in-time restore creates a new DB instance; it does not rewind the existing
instance in place.

### Manual snapshots

Manual snapshots are created explicitly by the user and are useful when
you want a recovery point that is independent of the normal
automated-backup lifecycle.

Common situations include:

-   Before a major schema migration
-   Before a risky application release
-   Before deleting or replacing a database
-   Keeping a known recovery point for a longer period

Manual snapshots remain until explicitly deleted and can continue incurring
storage charges after the source DB instance is gone.

------------------------------------------------------------------------

## Monitoring

RDS can be monitored using AWS database and observability features such
as:

-   Amazon CloudWatch
-   Enhanced Monitoring
-   CloudWatch Database Insights and engine-native database telemetry

Useful things to watch include:

-   CPU utilization
-   Database connections
-   Available storage
-   Read/write activity
-   Latency
-   Memory-related metrics
-   Query performance

Monitoring helps identify capacity problems, slow queries, connection
exhaustion, and unexpected workload changes.

------------------------------------------------------------------------

## Security

Use the following practices for RDS:

1.  **Keep databases private when possible.** Place application and
    database resources inside a VPC and avoid unnecessary public
    exposure.

2.  **Restrict security-group rules.** Allow port `3306` only from the
    application security group or trusted IP addresses.

3.  **Protect credentials.** Never commit usernames, passwords, tokens,
    or connection strings containing secrets.

4.  **Use encryption.** Use encryption at rest and encrypted connections
    in transit. Manage KMS key policies and certificate trust deliberately.

5.  **Apply least privilege.** Application database users should have
    only the permissions they need.

6.  **Enable backups.** Configure an appropriate backup-retention
    strategy for important environments.

7.  **Monitor the database.** Use CloudWatch and database monitoring
    features to detect operational problems.

8.  **Patch and maintain deliberately.** Understand the maintenance
    window and test significant database changes before production
    rollout.

9.  **Audit control-plane activity.** Use AWS CloudTrail for RDS API calls and
    export database logs supported by the selected engine to CloudWatch Logs
    when operational or audit requirements call for it.

------------------------------------------------------------------------

## Scaling

RDS supports different scaling approaches.

### Vertical scaling

Increase the capacity of the DB instance by selecting a larger DB
instance class.

This can provide more:

-   CPU
-   Memory
-   Network capacity

### Read scaling

Add Read Replicas to distribute read-only workloads.

Example:

``` text
                 ┌───────────────┐
Writes ─────────▶│ Primary RDS   │
                 └───────┬───────┘
                         │
                  Replication
                  ┌──────┴──────┐
                  ▼             ▼
             Read Replica  Read Replica
                  ▲             ▲
                  └──── Reads ──┘
```

Read Replicas do not automatically solve write-scaling requirements;
application architecture still needs to account for where writes are
sent.

------------------------------------------------------------------------

## Common use cases

### Web applications

RDS works well for applications that require structured relational data
and transactional queries.

Examples:

-   User accounts
-   Application settings
-   Content metadata
-   Transactional application data

### E-commerce platforms

Relational databases are useful for:

-   Product inventory
-   Customer information
-   Orders
-   Payments metadata
-   Transaction records

### Business applications

RDS can support systems such as:

-   ERP applications
-   CRM applications
-   Financial applications
-   Internal business systems

These workloads often benefit from relational constraints, transactions,
backups, and strong data-integrity requirements.

------------------------------------------------------------------------

## Verification checklist

After completing the lab, verify:

-   [ ] RDS DB instance status is **Available**
-   [ ] Correct database engine is selected
-   [ ] RDS endpoint and port are known
-   [ ] EC2 and RDS networking allows the required traffic
-   [ ] RDS security group does not unnecessarily expose port `3306`
-   [ ] MySQL client can connect to the RDS endpoint
-   [ ] Application container starts successfully
-   [ ] Application can read/write expected database data
-   [ ] Backups are configured as intended
-   [ ] Monitoring metrics are visible
-   [ ] No database credentials are committed to Git

------------------------------------------------------------------------

## Troubleshooting

### Connection timeout

Check:

-   RDS status is **Available**
-   Correct endpoint is being used
-   Correct port is being used
-   Security group allows traffic from the client
-   EC2 and RDS VPC/subnet routing is valid
-   Public accessibility is configured correctly if connecting from
    outside the VPC

### Access denied

Check:

-   Database username
-   Password
-   User privileges
-   Database engine authentication settings

Example error:

``` text
Access denied for user
```

This usually indicates an authentication or authorization problem rather
than a network timeout.

### Application cannot reach RDS

Test the database independently from the application:

``` bash
docker run -it --rm mysql:8.0 \
  mysql \
  -h YOUR_RDS_ENDPOINT \
  -u YOUR_DB_USERNAME \
  -p
```

If this fails, fix database connectivity before debugging the
application.

### Docker permission denied

If `ec2-user` was added to the Docker group:

``` bash
sudo usermod -aG docker ec2-user
```

sign out and reconnect to the EC2 instance before trying again.

------------------------------------------------------------------------

## Cleanup

RDS resources can continue generating charges while they exist.

After finishing the lab:

1.  Stop and remove temporary application containers.
2.  Review and remove Read Replicas, proxies, and other resources that depend
    on the database.
3.  Decide whether a final snapshot is required and verify its retention and
    encryption requirements.
4.  Disable deletion protection only after confirming the exact DB identifier,
    account, and Region, then delete the RDS DB instance if it is no longer
    needed.
5.  Delete temporary manual snapshots and automated-backup remnants that are
    no longer needed.
6.  Remove unused security groups, subnet groups, parameter groups, option
    groups, secrets, alarms, and log groups when they are no longer referenced.
7.  Terminate temporary EC2 instances if they were created only for the
    lab.
8.  Review the AWS console or billing tools for resources that may still
    incur charges.

------------------------------------------------------------------------

## Key takeaways

-   Amazon RDS is a managed relational database service.
-   RDS reduces operational work such as backups, patching, monitoring,
    recovery, and scaling.
-   RDS supports multiple relational database engines.
-   **Multi-AZ** focuses on high availability and failover.
-   **Read Replicas** focus on scaling read workloads.
-   Amazon Aurora provides AWS-designed MySQL- and PostgreSQL-compatible
    database options.
-   Security groups control network access to the database.
-   Database ports should be restricted to trusted application resources
    or IP addresses.
-   Automated backups and manual snapshots provide different recovery
    options.
-   Always clean up learning resources to avoid unnecessary AWS charges.

------------------------------------------------------------------------

## Knowledge check

1. Which database responsibilities remain with you when using Amazon RDS?
2. How does a Multi-AZ deployment differ from a Read Replica?
3. Why should an application use the RDS endpoint instead of an instance IP?
4. Why should the RDS security group reference the application security group?
5. What does point-in-time restore create?
6. When would you choose Aurora rather than an RDS community-engine deployment?
7. Which metrics would you inspect for connection exhaustion or low storage?
8. Which resources can continue generating charges after the DB instance is
   deleted?

## References

- [What is Amazon RDS? — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html)
- [High availability for Amazon RDS — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [Working with DB instance Read Replicas — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [Security in Amazon RDS — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.html)
- [Backing up and restoring — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html)
- [Monitoring Amazon RDS — Amazon RDS User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html)

> AWS engine support, features, console labels, quotas, and pricing can change.
> Verify production procedures against the current AWS documentation.

------------------------------------------------------------------------

## Related AWS topics

This guide fits into the following learning path:

``` text
IAM
 ↓
EC2
 ↓
VPC / Networking
 ↓
S3
 ↓
RDS / Aurora
 ↓
ELB + Auto Scaling
 ↓
CloudWatch
```

Understanding EC2 networking, VPCs, security groups, and IAM makes RDS
configuration much easier.
