# Amazon DynamoDB

[← Back to AWS Databases](../README.md) · [AWS learning path](../../README.md)

Amazon DynamoDB is a fully managed NoSQL database service designed for
key-value and document data. It provides a flexible, non-tabular data
model and is intended for applications that need reliable performance at
scale.

This guide covers the DynamoDB concepts from the AWS database learning
section, including NoSQL basics, tables and items, capacity, a practical
EC2 + Docker + Node.js example, serverless characteristics, DynamoDB
Accelerator (DAX), and Global Tables.

## Table of Contents

-   [Learning Objectives](#learning-objectives)
-   [Prerequisites](#prerequisites)
-   [What is NoSQL?](#what-is-nosql)
-   [What is Amazon DynamoDB?](#what-is-amazon-dynamodb)
-   [DynamoDB Data Model](#dynamodb-data-model)
-   [Tables and Items](#tables-and-items)
-   [Primary Keys](#primary-keys)
-   [Secondary Indexes](#secondary-indexes)
-   [Query, Scan, and Consistency](#query-scan-and-consistency)
-   [Capacity Modes and Cost](#capacity-modes-and-cost)
-   [Practical Lab: EC2 + Docker + Node.js +
    DynamoDB](#practical-lab-ec2--docker--nodejs--dynamodb)
-   [Create the DynamoDB Table](#create-the-dynamodb-table)
-   [Prepare the EC2 Instance](#prepare-the-ec2-instance)
-   [Application Permissions](#application-permissions)
-   [Run the Application](#run-the-application)
-   [DynamoDB Characteristics](#dynamodb-characteristics)
-   [Common Use Cases](#common-use-cases)
-   [DynamoDB Accelerator - DAX](#dynamodb-accelerator---dax)
-   [DynamoDB Global Tables](#dynamodb-global-tables)
-   [Data Protection and Monitoring](#data-protection-and-monitoring)
-   [Verification Checklist](#verification-checklist)
-   [Troubleshooting](#troubleshooting)
-   [Cleanup](#cleanup)
-   [Key Takeaways](#key-takeaways)
-   [Knowledge Check](#knowledge-check)
-   [References](#references)
-   [Related AWS Topics](#related-aws-topics)

------------------------------------------------------------------------

## Learning Objectives

After completing this guide, you should be able to:

- Explain tables, items, attributes, partition keys, and sort keys.
- Design a primary key around an application's access patterns.
- Distinguish `Query` from `Scan` and eventual from strong consistency.
- Compare on-demand and provisioned capacity modes.
- Grant an EC2 application least-privilege DynamoDB access with an IAM role.
- Explain secondary indexes, Streams, TTL, backups, DAX, and Global Tables.
- Verify, troubleshoot, monitor, and safely clean up a DynamoDB lab.

## Prerequisites

Use a sandbox account with billing alerts enabled. You should understand IAM
roles and policies, EC2, Docker basics, AWS Regions, JSON, and application access
patterns. Use non-production data, confirm current regional pricing, and never
create long-lived access keys for this lab.

------------------------------------------------------------------------

## What is NoSQL?

NoSQL databases are designed to store and manage data using flexible,
non-tabular structures.

They are useful when applications need to work with large volumes of
data that may not fit naturally into a traditional relational table
structure.

Unlike a relational database where records generally follow a predefined
table schema, NoSQL documents can contain flexible attributes.

Example document:

``` json
{
  "_id": 1,
  "name": "Raju",
  "email": "raju@example.com",
  "age": 35,
  "address": {
    "street": "123 Bollywood Blvd",
    "city": "Mumbai",
    "zip": "400001"
  },
  "hobbies": ["acting", "reading"]
}
```

The document contains:

-   Scalar values
-   Nested objects
-   Arrays
-   Key-value attributes

------------------------------------------------------------------------

## What is Amazon DynamoDB?

Amazon DynamoDB is a fully managed NoSQL database service.

DynamoDB stores data using **key-value** and **document** structures
rather than traditional relational rows and joins.

Important characteristics covered in this section include:

-   Fully managed
-   Serverless
-   Flexible data model
-   Automatic scaling
-   Low-latency access
-   On-demand pricing options
-   No database server provisioning
-   No operating-system or database-software maintenance

A typical application architecture looks like:

``` text
Application
     |
     v
AWS SDK / API
     |
     v
Amazon DynamoDB
```

AWS manages the underlying database infrastructure while the application
interacts with DynamoDB through APIs and AWS SDKs.

------------------------------------------------------------------------

## DynamoDB Data Model

DynamoDB organizes data using:

``` text
DynamoDB
   |
   +-- Table
         |
         +-- Item
         |     |
         |     +-- Attribute
         |     +-- Attribute
         |
         +-- Item
               |
               +-- Attribute
```

### Table

A **table** is a collection of related items.

Example:

``` text
Table: users
```

### Item

An **item** is an individual record inside a table.

Example:

``` json
{
  "name": "Raju",
  "age": 25
}
```

Another item in the same table can contain:

``` json
{
  "name": "Sham",
  "age": 28
}
```

### Attribute

An **attribute** is an individual piece of data inside an item.

For example:

``` text
name -> Raju
age  -> 25
```

------------------------------------------------------------------------

## Tables and Items

DynamoDB stores data as items inside tables.

Each item can be represented as a JSON-like document containing
key-value pairs.

Example:

``` text
users
|
+-- Item
|   +-- name: Raju
|   +-- age: 25
|
+-- Item
|   +-- name: Sham
|   +-- age: 28
|
+-- Item
    +-- name: Baburao
    +-- age: 45
```

This document-oriented structure makes DynamoDB suitable for
applications where records may evolve over time.

Items in one table can have different non-key attributes, but every item must
include the attributes defined by the table's primary key. An item, including
its attribute names and values, can be up to 400 KB.

------------------------------------------------------------------------

## Primary Keys

Every DynamoDB table requires a primary key. DynamoDB supports:

-   **Simple primary key:** one partition key.
-   **Composite primary key:** a partition key plus a sort key.

The partition key determines how data is distributed. With a composite key,
items that share a partition-key value are ordered by sort key, enabling
efficient range and prefix access within that logical group.

In the practical example from this section, the table is:

``` text
Contacts
```

with the primary key:

``` text
id
```

and its type is:

``` text
String
```

Conceptually:

``` text
Contacts
|
+-- id: "1"
|   +-- name: "User One"
|
+-- id: "2"
    +-- name: "User Two"
```

The primary key uniquely identifies an item in the table.

Choose keys from the queries and write patterns the application must support.
A low-cardinality or heavily concentrated partition key can create a hot
partition, while random keys without a useful access pattern can force scans.

------------------------------------------------------------------------

## Secondary Indexes

Secondary indexes provide additional query patterns without changing the base
table's primary key.

| Index | Key choice | Creation and scope | Consistency |
| --- | --- | --- | --- |
| **Global secondary index (GSI)** | Different partition key and optional sort key | Can be added after table creation; spans the table | Eventually consistent reads |
| **Local secondary index (LSI)** | Same partition key with a different sort key | Must be created with the table; scoped to a partition-key value | Eventual or strong reads |

Indexes consume storage and write capacity or request charges because DynamoDB
maintains projected data as the base table changes. Project only attributes the
access pattern needs.

------------------------------------------------------------------------

## Query, Scan, and Consistency

-   **`GetItem`** retrieves one item by its complete primary key.
-   **`Query`** reads items for one partition-key value and can apply sort-key
    conditions. It is normally the preferred multi-item read operation.
-   **`Scan`** examines every item or index entry before filtering results. It
    can consume substantial capacity and should not be the default access path.

Eventually consistent reads are the default for table and LSI reads. Strongly
consistent reads can be requested for supported table and LSI operations but
cost more read capacity. GSI and DynamoDB Streams reads are eventually
consistent. Use transactions when an operation requires coordinated,
all-or-nothing changes across multiple items.

------------------------------------------------------------------------

## Capacity Modes and Cost

DynamoDB offers two capacity modes:

-   **On-demand:** pay per request without preconfiguring read and write
    throughput. It is a useful starting point for new or unpredictable traffic.
-   **Provisioned:** configure read capacity units (RCUs) and write capacity
    units (WCUs), optionally with auto scaling. It can suit predictable traffic
    when capacity is managed carefully.

Capacity consumption depends on item size, operation type, consistency, indexes,
and transactional behavior. Additional costs can include storage, backups,
Streams, change-data capture, data transfer, Global Tables replication, DAX,
and reserved capacity where applicable.

> AWS prices and Free Tier offers can change. Check the current DynamoDB pricing
> page for the selected Region instead of relying on fixed allowance values in
> study notes.

------------------------------------------------------------------------

## Practical Lab: EC2 + Docker + Node.js + DynamoDB

The practical example connects a Docker-based Node.js application
running on EC2 to DynamoDB.

Architecture:

``` text
+----------------------------+
| Amazon EC2                 |
|                            |
|  Docker                    |
|     |                      |
|     +-- Node.js App        |
|                            |
+-------------+--------------+
              |
              | AWS API
              v
+----------------------------+
| Amazon DynamoDB            |
|                            |
| Table: Contacts            |
| Primary Key: id (String)   |
+----------------------------+
```

------------------------------------------------------------------------

### Create the DynamoDB Table

Open the AWS Management Console and navigate to DynamoDB.

Create a table with:

``` text
Table name:     Contacts
Partition key:  id
Type:           String
Capacity mode:  On-demand
```

After creating the table, wait until it becomes available.

The Node.js application will use this table to store and retrieve data.

------------------------------------------------------------------------

### Prepare the EC2 Instance

The practical example uses an Amazon Linux EC2 instance.

Install Docker:

``` bash
sudo dnf install -y docker
```

Start Docker:

``` bash
sudo systemctl enable --now docker
```

Add `ec2-user` to the Docker group:

``` bash
sudo usermod -aG docker ec2-user
```

After changing group membership, log out and reconnect to the EC2
instance.

Pull the demo application:

``` bash
docker pull philippaul/node-dynamodb-demo
```

This is a third-party demonstration image. Inspect its source and metadata
before running it, use only non-production data, and pin a reviewed image digest
when reproducibility matters.

------------------------------------------------------------------------

### Application Permissions

Do not create access keys for this lab. Attach an IAM role to the EC2 instance
and allow only the actions the application needs on the `Contacts` table.

An example identity policy is:

``` json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ContactsTableAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:UpdateItem"
      ],
      "Resource": "arn:aws:dynamodb:YOUR_REGION:YOUR_ACCOUNT_ID:table/Contacts"
    }
  ]
}
```

Replace the Region and account ID, create a role trusted by EC2, attach this
policy to the role, and attach the role through an instance profile. Remove
actions that the application does not use; for example, remove `Scan` if the
application never scans the table.

The AWS SDK's default credential provider can obtain temporary role credentials
from EC2 Instance Metadata Service (IMDS). Container networking and IMDSv2 hop
settings must permit that access. Configure them deliberately; do not work
around an instance-role problem by copying long-lived credentials into the
container.

Never hard-code credentials into:

-   Source code
-   Dockerfiles
-   Git repositories
-   README files
-   Public environment files

Use IMDSv2, restrict which workloads can access instance metadata, and give the
instance role no permissions beyond those required by the lab.

------------------------------------------------------------------------

### Run the Application

The source lab runs the application container on port `3000` and exposes
it through port `80` on the EC2 instance.

Example:

``` bash
docker run --rm -d \
  -p 80:3000 \
  --name node-dynamo-app \
  -e AWS_REGION="YOUR_REGION" \
  philippaul/node-dynamodb-demo
```

Replace `YOUR_REGION` with the table's Region. No access-key environment
variables are required when the SDK can obtain temporary credentials from the
EC2 role.

The request flow becomes:

``` text
Browser
   |
   v
EC2 :80
   |
   v
Docker Container :3000
   |
   v
Node.js Application
   |
   v
AWS DynamoDB API
   |
   v
Contacts Table
```

Check that the container is running:

``` bash
docker ps
```

View application logs:

``` bash
docker logs node-dynamo-app
```

------------------------------------------------------------------------

## DynamoDB Characteristics

### Serverless

There is no need to manually provision and maintain a database server.

AWS manages infrastructure tasks such as:

-   Server provisioning
-   Software installation
-   Maintenance
-   Patching

### Automatic Scaling

DynamoDB can adapt capacity based on application demand, depending on
the configured capacity mode and scaling settings.

This reduces the need to manually resize traditional database servers.

### Continuous Availability

The service is designed so applications do not need to manage
traditional database maintenance windows or database server replacement.

### On-Demand Pricing

On-demand capacity is useful for applications with unpredictable or
fluctuating request traffic.

Instead of provisioning a fixed amount of read/write capacity, usage is
based on requests.

### Reduced Idle Capacity Management

Serverless operation means applications do not need to keep a
traditional database server running solely to remain ready for requests.

------------------------------------------------------------------------

## Common Use Cases

The learning material identifies DynamoDB as a good fit for applications
such as:

### Mobile Applications

Useful for application data that requires flexible storage and fast
access.

### Web Applications

Suitable for web workloads requiring scalable key-value or document
storage.

### Gaming

Useful for data such as:

-   Player information
-   Game state
-   Session-related data

### Advertising Technology

Can support high-volume workloads that require rapid access to
application data.

### Internet of Things

Useful for applications handling data generated by large numbers of
connected devices.

Other applications requiring flexible data models and scalable access
patterns can also benefit from DynamoDB.

------------------------------------------------------------------------

## DynamoDB Accelerator - DAX

**DynamoDB Accelerator (DAX)** is a fully managed in-memory cache
designed specifically for DynamoDB.

Architecture:

``` text
+-----------------------+
| Application           |
|                       |
| DAX Client            |
+-----------+-----------+
            |
            v
+-----------------------+
| DAX Cluster           |
|                       |
| In-Memory Cache       |
+-----------+-----------+
            |
            v
+-----------------------+
| Amazon DynamoDB       |
+-----------------------+
```

The application communicates with the DAX cluster using a DAX client.

DAX can serve cached data without every compatible read request going
directly to DynamoDB.

### DAX Benefits

-   Fully managed in-memory caching
-   Microsecond latency
-   High availability
-   Multi-AZ deployment capability
-   Native DynamoDB integration

### DAX vs ElastiCache

A key distinction from the material is:

``` text
DAX
 |
 +-- Designed specifically for DynamoDB

ElastiCache
 |
 +-- General caching service usable with other application/database architectures
```

Use DAX when the caching requirement is tightly integrated with
DynamoDB.

------------------------------------------------------------------------

## DynamoDB Global Tables

DynamoDB Global Tables provide a multi-Region architecture for
applications with globally distributed users.

Conceptually:

``` text
                    Global Application
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
   North America        Europe            Asia
      Region            Region           Region
          |                |                |
          v                v                v
      Replica <-------> Replica <-------> Replica
```

Global Tables are useful when an application needs data available closer
to users in multiple AWS Regions.

Global Tables provide multi-active replication: applications can write to
replicas in multiple Regions. Design for replication latency and concurrent
updates, test regional failover, and understand the selected consistency mode,
conflict-resolution behavior, quotas, KMS configuration, and replication costs.

Typical goals include:

-   Multi-Region applications
-   Globally distributed users
-   Regional data access
-   Improved global application availability

------------------------------------------------------------------------

## Data Protection and Monitoring

-   **Encryption:** DynamoDB encrypts table data at rest. Choose an AWS owned,
    AWS managed, or customer managed KMS key according to access-control and
    compliance requirements.
-   **Point-in-time recovery (PITR):** provides continuous backups within the
    configured recovery window and restores into a new table.
-   **On-demand backups:** create retained recovery points for longer-term or
    migration needs; test restores rather than assuming a backup is usable.
-   **DynamoDB Streams:** captures item-level changes for event-driven
    processing within its retention window.
-   **Time to Live (TTL):** marks expired items for asynchronous deletion. Do
    not use TTL when deletion must occur at an exact time.
-   **CloudWatch:** monitor consumed capacity, throttled requests, latency,
    system errors, replication, and account or table limits.
-   **CloudTrail:** records DynamoDB control-plane activity and configured data
    events for auditing.
-   **Contributor Insights:** helps identify frequently accessed or throttled
    keys when enabled.

Use alarms for sustained throttling, system errors, and capacity conditions
that require action. Protect backups and customer-managed KMS keys with least
privilege and appropriate retention policies.

------------------------------------------------------------------------

## Verification Checklist

After completing the practical exercise, verify:

-   [ ] DynamoDB table `Contacts` exists
-   [ ] Partition key is `id`
-   [ ] Partition key type is `String`
-   [ ] EC2 instance is running
-   [ ] Docker is installed and running
-   [ ] `node-dynamodb-demo` image is available
-   [ ] Application container is running
-   [ ] Correct AWS Region is configured
-   [ ] Application has permission to access DynamoDB
-   [ ] Application can create/read expected DynamoDB items
-   [ ] No AWS credentials are committed to Git

Useful commands:

``` bash
docker ps
```

``` bash
docker logs node-dynamo-app
```

------------------------------------------------------------------------

## Troubleshooting

### `AccessDeniedException`

Confirm the EC2 instance has the intended IAM role, the policy action and table
ARN match the request, the Region and account ID are correct, and no permissions
boundary or organization policy denies access. Index operations may also need
the table's `/index/*` resource ARN.

### `ResourceNotFoundException`

Check the exact table name and AWS Region. DynamoDB tables are Regional, and
names are case-sensitive.

### Container cannot obtain credentials

Confirm the role is attached to the EC2 instance and the SDK supports the EC2
role credential provider. Review IMDSv2 and container-network reachability
without printing credentials. Do not put access keys into the image or command.

### Throttled requests or uneven performance

Inspect CloudWatch throttling and consumed-capacity metrics. Review partition-key
cardinality, concentrated traffic, item size, capacity mode, index traffic, and
retry behavior. AWS SDK clients should use bounded exponential backoff with
jitter for retryable failures.

### Query returns no items

Verify the partition-key value and data type, sort-key condition, index name,
expression attribute names and values, and whether an eventually consistent
index has finished propagating a recent write.

------------------------------------------------------------------------

## Cleanup

AWS resources can incur charges, so remove resources that are no longer
required after completing the lab.

### Remove the container

``` bash
docker stop node-dynamo-app
```

Because the container was started with `--rm`, Docker removes it after
it stops.

### Remove the DynamoDB table

Before deleting the `Contacts` table, confirm the account, Region, table name,
PITR status, backups, Streams consumers, replicas, and retention requirements.
Create and verify an on-demand backup first if the data must be retained.

### Remove EC2 resources

If the EC2 instance was created only for this exercise:

1.  Terminate the EC2 instance.
2.  Remove unused security groups if applicable.
3.  Remove other temporary resources created for the lab.

### Remove IAM resources and related services

Detach and delete the lab IAM policy and role after the EC2 instance no longer
uses them. Remove lab-only backups, DAX clusters, alarms, log groups, stream
consumers, and Global Tables replicas after confirming they are not required.
Review the billing dashboard for remaining resources and charges.

------------------------------------------------------------------------

## Key Takeaways

-   DynamoDB is a fully managed NoSQL database service.
-   DynamoDB supports key-value and document data models.
-   Data is organized into **tables**, **items**, and **attributes**.
-   Every table requires a primary key.
-   Key design should begin with application access patterns.
-   Prefer targeted `GetItem` and `Query` operations over broad scans.
-   The practical example uses a `Contacts` table with `id` as a String
    primary key.
-   DynamoDB removes the need to provision and maintain traditional
    database servers.
-   Capacity can be managed using provisioned or on-demand approaches.
-   EC2 applications can communicate with DynamoDB through AWS APIs.
-   Avoid storing long-lived AWS credentials in source code or Git.
-   DAX provides an in-memory caching layer specifically for DynamoDB.
-   Global Tables support multi-Region DynamoDB architectures.
-   DynamoDB is useful for mobile, web, gaming, advertising technology,
    IoT, and other scalable applications.

------------------------------------------------------------------------

## Knowledge Check

1. What is the difference between a partition key and a sort key?
2. Why can a low-cardinality partition key create performance problems?
3. When should an application use `Query` instead of `Scan`?
4. How do a GSI and an LSI differ?
5. When would on-demand capacity be preferable to provisioned capacity?
6. Why should the EC2 application use an IAM role instead of access keys?
7. What does point-in-time recovery create when data is restored?
8. Which resources can continue generating charges after a table is deleted?

## References

- [What is Amazon DynamoDB? — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html)
- [DynamoDB core components — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html)
- [Best practices for designing partition keys — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/bp-partition-key-design.html)
- [Read consistency — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadConsistency.html)
- [DynamoDB security best practices — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/security-best-practices.html)
- [Backup and restore — DynamoDB Developer Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/BackupRestore.html)

> AWS features, capacity behavior, quotas, Free Tier offers, console labels, and
> pricing can change. Verify production designs against current AWS
> documentation.

------------------------------------------------------------------------

## Related AWS Topics

``` text
IAM
 |
EC2
 |
DynamoDB
 |
DAX
 |
Global Tables
 |
CloudWatch
```

Understanding IAM is especially important because applications require
appropriate AWS permissions to access DynamoDB.
