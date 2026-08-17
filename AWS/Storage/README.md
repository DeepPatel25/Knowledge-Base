# AWS Storage

This section contains practical guides to AWS storage services, including storage selection, configuration, backup, security, and cost-aware operations.

## Topics

- [Amazon Elastic Block Store (EBS)](./EBS/README.md) — persistent block storage for EC2, volume types, attachment and mounting, resizing, snapshots, encryption, and lifecycle management.
- [Amazon Simple Storage Service (S3)](./S3/README.md) — object storage, access control, versioning, replication, storage classes, lifecycle automation, encryption, monitoring, and hybrid transfer options.

## Recommended order

1. Learn the differences between block, file, and object storage.
2. Complete the EBS guide alongside the EC2 learning path.
3. Complete the S3 guide to learn buckets, objects, permissions, data protection, and lifecycle management.
4. Practice EBS snapshot recovery and S3 object-version recovery.
5. Review encryption, retention, monitoring, cost, and cleanup settings before using storage in production.

## Study rule

Use non-production data for storage labs. Confirm the selected account, Region, resource name, versioning or backup state, and retention requirements before formatting, detaching, emptying, or deleting storage.
