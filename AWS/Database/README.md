# AWS Databases

[← Back to the AWS learning path](../README.md)

This section contains practical guides to managed AWS database services,
including engine selection, networking, availability, scaling, backup,
monitoring, security, and cost-aware operations.

## Topics

- [Amazon Relational Database Service (RDS)](./RDS/README.md) — relational
  database engines, Amazon Aurora, Multi-AZ deployments, Read Replicas,
  backups, monitoring, security, scaling, troubleshooting, and an EC2-to-RDS
  MySQL lab.
- [Amazon DynamoDB](./DynamoDB/README.md) — NoSQL data modeling, primary keys,
  secondary indexes, capacity modes, consistency, IAM access, backups, DAX,
  Global Tables, monitoring, and an EC2 application lab.

## Database mental model

Choose a database based on the application's data model and access patterns,
not only familiarity with an engine:

| Requirement | Service direction to investigate |
| --- | --- |
| Relational schema, joins, and transactions | Amazon RDS or Amazon Aurora |
| Key-value and document access at large scale | Amazon DynamoDB |
| In-memory caching | Amazon ElastiCache or Amazon MemoryDB |
| Analytics warehouse | Amazon Redshift |
| Graph relationships | Amazon Neptune |

This index currently provides in-depth guides for RDS and DynamoDB. The other
services are learning-path directions rather than completed guides.

## Recommended order

1. Learn relational database fundamentals and the AWS shared-responsibility
   model.
2. Review VPC subnet placement, routing, security groups, and DNS resolution.
3. Complete the RDS guide with a private database in a sandbox VPC.
4. Practice snapshots and point-in-time recovery before relying on backups.
5. Compare Multi-AZ availability with Read Replica scaling.
6. Complete the DynamoDB guide and model a table from known access patterns.
7. Compare DynamoDB on-demand and provisioned capacity and test point-in-time
   recovery.
8. Add monitoring, encryption, credential rotation, and cost controls.
9. Evaluate other purpose-built databases for specialized workloads.

## Study rule

Keep databases private unless public connectivity is explicitly required and
reviewed. Never commit database passwords, connection strings, or AWS access
keys. Before deleting a database, confirm its account, Region, identifier,
backup retention, replica relationships, deletion protection, and final-snapshot
requirements. Before deleting a DynamoDB table, confirm its keys, replicas,
backups, recovery settings, downstream stream consumers, and retention
requirements.
