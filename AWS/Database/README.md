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

This index currently provides an in-depth guide for RDS. The other services are
learning-path directions rather than completed guides.

## Recommended order

1. Learn relational database fundamentals and the AWS shared-responsibility model.
2. Review VPC subnet placement, routing, security groups, and DNS resolution.
3. Complete the RDS guide with a private database in a sandbox VPC.
4. Practice snapshots and point-in-time recovery before relying on backups.
5. Compare Multi-AZ availability with Read Replica scaling.
6. Add monitoring, encryption, credential rotation, and cost controls.
7. Evaluate DynamoDB and purpose-built databases for non-relational workloads.

## Study rule

Keep databases private unless public connectivity is explicitly required and
reviewed. Never commit database passwords or connection strings. Before deleting
a database, confirm its account, Region, identifier, backup retention, replica
relationships, deletion protection, and final-snapshot requirements.
