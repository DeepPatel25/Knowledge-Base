# Amazon S3 (Simple Storage Service)

[← Back to AWS Storage](../README.md) · [AWS learning path](../../README.md)

> Learning notes for storing, protecting, managing, and retrieving objects with
> Amazon Simple Storage Service (Amazon S3).

## Table of Contents

- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [What is Amazon S3?](#what-is-amazon-s3)
- [Core Concepts](#core-concepts)
- [Object Size and Multipart Upload](#object-size-and-multipart-upload)
- [Common Use Cases](#common-use-cases)
- [S3 Versioning](#s3-versioning)
- [S3 Replication](#s3-replication)
- [S3 Bucket Policies](#s3-bucket-policies)
- [S3 Storage Classes](#s3-storage-classes)
- [S3 Lifecycle Policies](#s3-lifecycle-policies)
- [Data Encryption](#data-encryption)
- [Logging and Monitoring](#logging-and-monitoring)
- [Hands-on Practice](#hands-on-practice)
- [AWS Snow Family](#aws-snow-family)
- [AWS Storage Gateway](#aws-storage-gateway)
- [Security and Cost Guidance](#security-and-cost-guidance)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Quick Revision](#quick-revision)
- [Knowledge Check](#knowledge-check)
- [References](#references)

---

## Learning Objectives

After completing this guide, you should be able to:

- Explain buckets, objects, keys, prefixes, metadata, and version IDs.
- Upload and retrieve objects, including large objects with multipart upload.
- Apply least-privilege access with IAM and bucket policies.
- Use versioning, replication, lifecycle rules, and storage classes correctly.
- Choose an encryption option and monitor data access.
- Create and safely clean up a private practice bucket.
- Distinguish S3 from EBS, EFS, Snow Family devices, and Storage Gateway.

## Prerequisites

Use an AWS sandbox account with billing alerts enabled. You should understand
AWS Regions, IAM identities and roles, and basic JSON policy structure. Keep
Block Public Access enabled unless a lab explicitly requires public access, and
never upload credentials, private keys, or production data for practice.

---

## What is Amazon S3?

**Amazon S3 (Simple Storage Service)** is a managed object-storage service used
to store and retrieve data such as documents, images, videos, logs, backups,
artifacts, and analytics datasets.

Applications access S3 through APIs and service endpoints. Access can use public
AWS endpoints or private connectivity such as a VPC endpoint; an S3 bucket does
not need to be public.

### Simple mental model

```text
Application / User
       |
       v
   S3 Bucket
       |
       +-- object-1
       +-- object-2
       +-- folder-like-prefix/object-3
```

### S3 compared with other storage models

| Service | Storage model | Typical access | Common use |
| --- | --- | --- | --- |
| **Amazon S3** | Object | S3 API, SDK, CLI, or HTTPS | Backups, logs, media, artifacts, and data lakes |
| **Amazon EBS** | Block | Attached as a volume to compute | Boot volumes, databases, and low-latency block workloads |
| **Amazon EFS** | File | NFS mount shared by compute | Shared Linux files and applications needing filesystem semantics |

S3 objects are addressed by bucket and key. Applications should not assume S3
behaves like a locally mounted disk with in-place file modification or POSIX
filesystem semantics.

---

## Core Concepts

### 1. S3 stores data as objects

S3 is **object storage** rather than a traditional file system.

An object consists of data plus attributes used to identify and describe it:

```text
Key       -> object name within the bucket
Data      -> object content
Metadata  -> system-defined and user-defined attributes
Version ID -> specific version when versioning is enabled
```

Example:

```text
Bucket: knowledge-base-assets

Key:   aws/images/s3.png
Value: <image data>
```

Although `/` can appear in an object key and make the console look like it has
directories, S3 is not a hierarchical filesystem. The apparent folders are
key-name prefixes.

### 2. Bucket names must be unique

An S3 general-purpose bucket name must be unique across all AWS accounts within
an AWS partition, such as `aws`, `aws-cn`, or `aws-us-gov`.

```text
my-learning-bucket-2026
```

### 3. Buckets are region-specific

A bucket is created in an AWS Region.

Choose the Region based on latency, compliance, service availability, and data
transfer requirements. A bucket's Region cannot be changed after creation;
create another bucket and copy the objects when migration is required.

### 4. S3 provides strong consistency

After a successful write or delete, subsequent reads and listings reflect that
change. Strong consistency does not replace versioning, backup, or replication:
an accidental deletion can still become immediately visible.

---

## Object Size and Multipart Upload

The maximum size of a single Amazon S3 object is:

```text
5 TB
```

One `PUT` request can upload an object of up to **5 GB**. Multipart upload is
required above that limit, and AWS recommends considering it for objects around
**100 MB or larger** so failed parts can be retried independently.

Multipart upload splits a large file into smaller parts that can be uploaded separately.

```text
Large File
   |
   +-- Part 1
   +-- Part 2
   +-- Part 3
   +-- ...
   |
   v
Amazon S3
```

After initiating a multipart upload, either complete it or abort it. Uploaded
parts consume storage and incur charges until one of those actions occurs. A
lifecycle rule can automatically remove incomplete multipart uploads.

---

## Common Use Cases

### Static Website Hosting

S3 can host static website content such as:

- HTML
- CSS
- JavaScript

```text
index.html
styles.css
app.js
    |
    v
S3 Bucket
    |
    v
Static Website
```

The S3 website endpoint is public and supports HTTP, not HTTPS. For a public
production website, use CloudFront with HTTPS and keep the S3 origin private
where possible. S3 cannot run server-side application code.

### Data Lake

S3 can act as a central repository for both:

- structured data
- unstructured data

This makes it useful for storing data that will later be processed or analyzed.

### Backups and Disaster Recovery

S3 is commonly used for:

- backups
- long-term archives
- disaster recovery data

Its different storage classes allow data to be stored according to how often it needs to be accessed.

---

## S3 Versioning

**S3 Versioning** allows multiple versions of the same object to exist in one bucket.

This helps protect data from:

- accidental deletion
- accidental overwrite
- unwanted changes

Example:

```text
report.pdf
   |
   +-- Version 1
   +-- Version 2
   +-- Version 3
```

If the latest version is incorrect, an older version can be recovered.

Deleting a versioned object normally adds a **delete marker** rather than
immediately erasing every version. Permanently deleting data requires deleting
specific version IDs. Once versioning is enabled, it can be suspended but not
return to the original unversioned state.

### Why use versioning?

```text
Without Versioning
------------------
Upload new file -> old file is replaced

With Versioning
---------------
Upload new file -> previous version is retained
```

Versioning is therefore useful for **data safety and backup**.

---

## S3 Replication

S3 Replication automatically copies objects from one bucket to another.

The two primary live replication patterns are:

### Same-Region Replication (SRR)

Copies data between buckets in the **same AWS Region**.

```text
Bucket A (Region X)
        |
        v
Bucket B (Region X)
```

### Cross-Region Replication (CRR)

Copies data between buckets in **different AWS Regions**.

```text
Bucket A (Region X)
        |
        v
Bucket B (Region Y)
```

### Common reasons for replication

- compliance
- redundancy
- maintaining copies of data
- improving access by keeping copies closer to users

Replication requires versioning on both source and destination buckets and an
IAM role that S3 can assume. By default, a new replication rule applies to
eligible objects written after the rule is enabled; use S3 Batch Replication
when existing objects must also be copied. Replication behavior for delete
markers, ownership, encryption, and storage class depends on the rule, so test
recovery rather than treating replication as an automatic backup.

---

## S3 Bucket Policies

An **S3 Bucket Policy** is a JSON-based access-control policy attached directly to a bucket.

It defines:

```text
WHO can access the bucket
WHAT actions they can perform
WHICH resources those permissions apply to
```

Bucket policies can control operations such as:

- read
- write
- delete

### Common S3 actions

| Action | Purpose |
|---|---|
| `GetObject` | Retrieve or download an object from S3 |
| `PutObject` | Upload or add an object to S3 |

IAM policies are identity-based policies attached to users, groups, or roles.
Bucket policies are resource-based policies attached to a bucket. Access is
determined by the combination of applicable policies, Block Public Access,
object ownership, organization controls, and any explicit denies.

### Example: require encrypted transport

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::YOUR_BUCKET_NAME",
        "arn:aws:s3:::YOUR_BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

Replace `YOUR_BUCKET_NAME` before use. This policy adds a deny guardrail; it
does not grant access. Keep all four S3 Block Public Access settings enabled for
private buckets, use **Bucket owner enforced** Object Ownership for modern
workloads, and avoid ACLs unless a legacy integration specifically requires
them.

---

## S3 Storage Classes

Different S3 storage classes are intended for different access patterns, resilience requirements, and costs.

| Storage Class | Typical Use Case | Key Idea |
| --- | --- | --- |
| **S3 Standard** | Frequently accessed data | High durability, high availability, low latency |
| **S3 Intelligent-Tiering** | Unknown or unpredictable access patterns | Automatically moves data between frequent and infrequent access tiers |
| **S3 Standard-IA** | Infrequently accessed but quickly retrievable data | Lower storage cost with higher retrieval cost |
| **S3 One Zone-IA** | Non-critical, infrequently accessed data | Stored in a single Availability Zone with lower resilience |
| **S3 Glacier Instant Retrieval** | Rarely accessed archives needing millisecond retrieval | Archive pricing with immediate access and minimum-duration considerations |
| **S3 Glacier Flexible Retrieval** | Archives that can wait minutes or hours for restoration | Multiple retrieval-speed options and minimum-duration considerations |
| **S3 Glacier Deep Archive** | Long-lived archives that can wait hours for restoration | Lowest-cost S3 archival tier for very infrequent access |
| **S3 Express One Zone** | Latency-sensitive workloads with very high request rates | Single-AZ storage using S3 directory buckets |
| **S3 Outposts** | S3-style storage on AWS Outposts | Provides S3 APIs for local/on-premises requirements |

Storage price is only one part of the decision. Compare retrieval fees,
request charges, minimum storage duration, minimum billable object size,
availability, resilience, and retrieval time. Exact prices and constraints vary
by Region and can change.

### Choosing a class - simplified

```text
Frequently accessed
      |
      v
S3 Standard

Unknown access pattern
      |
      v
S3 Intelligent-Tiering

Infrequently accessed
      |
      +--> S3 Standard-IA
      +--> S3 One Zone-IA

Archive
      |
      +--> S3 Glacier Instant Retrieval
      +--> S3 Glacier Flexible Retrieval
      +--> S3 Glacier Deep Archive
```

---

## S3 Lifecycle Policies

An **S3 Lifecycle Policy** automates how objects move between storage classes or when they are deleted.

Lifecycle rules support two major types of actions.

### 1. Transition Actions

Transition actions move objects to another storage class as they age or become less frequently accessed.

Example lifecycle:

```text
Day 0
S3 Standard
    |
    | after 30 days
    v
S3 Standard-IA
    |
    | after 90 days
    v
S3 Glacier Flexible Retrieval
    |
    | later for long-term retention
    v
S3 Glacier Deep Archive
```

Example transitions include:

- moving objects from S3 Standard to S3 Standard-IA after 30 days
- moving objects from S3 Standard-IA to S3 Glacier Flexible Retrieval after 90 days
- moving objects to Glacier Deep Archive after a specified period

### 2. Expiration Actions

Expiration actions delete objects after a specified period.

Examples:

```text
Delete objects after 365 days
```

or, when versioning is enabled:

```text
Delete old object versions after a configured period
```

Lifecycle policies help automate storage management and cleanup.

Test lifecycle filters carefully. Rules can target prefixes, tags, object sizes,
current versions, noncurrent versions, delete markers, and incomplete multipart
uploads. Expiration is asynchronous, and transitions can introduce retrieval
charges or minimum-storage-duration charges.

---

## Data Encryption

Amazon S3 encrypts new uploads at rest by default with server-side encryption
using S3-managed keys (SSE-S3). Depending on control and compliance needs, you
can choose:

| Option | Key management | Important consideration |
| --- | --- | --- |
| **SSE-S3** | Amazon S3 manages the keys | Simple default for many workloads |
| **SSE-KMS** | AWS KMS manages the key | Adds key policies, audit events, quotas, and KMS charges |
| **DSSE-KMS** | Two independent KMS encryption layers | Intended for workloads requiring dual-layer server-side encryption |
| **SSE-C** | The client supplies a key with each request | The customer must securely retain and provide the key |
| **Client-side encryption** | The application encrypts before upload | AWS never receives plaintext, but the application owns key handling |

Use TLS for data in transit. If using SSE-KMS, grant both the S3 permissions and
the required KMS key permissions, and confirm that replication and cross-account
consumers can use the key.

## Logging and Monitoring

Use the control that matches the question you need to answer:

- **AWS CloudTrail management events:** bucket-level API activity such as
  creating a bucket or changing its policy.
- **CloudTrail data events:** object-level calls such as `GetObject` and
  `PutObject`; configure them explicitly and account for event charges.
- **S3 server access logging:** detailed request records delivered to a
  destination bucket on a best-effort basis.
- **Amazon CloudWatch:** request, storage, replication, and operational metrics
  with alarms where supported.
- **S3 Inventory:** scheduled object and metadata listings for audits and batch
  workflows.
- **IAM Access Analyzer for S3:** findings for buckets shared outside the
  account or organization.

Do not send access logs back to the same source prefix in a way that creates a
logging loop. Protect logs with least privilege, encryption, retention rules,
and separation from the workload account when required.

## Hands-on Practice

This AWS CLI lab creates a private, versioned bucket. Replace the placeholders
and use the Region configured for your sandbox account.

```bash
aws s3api create-bucket \
  --bucket YOUR_GLOBALLY_UNIQUE_BUCKET_NAME \
  --region YOUR_REGION \
  --create-bucket-configuration LocationConstraint=YOUR_REGION

aws s3api put-public-access-block \
  --bucket YOUR_GLOBALLY_UNIQUE_BUCKET_NAME \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-versioning \
  --bucket YOUR_GLOBALLY_UNIQUE_BUCKET_NAME \
  --versioning-configuration Status=Enabled

printf 'first version\n' > /tmp/s3-learning-object.txt
aws s3 cp /tmp/s3-learning-object.txt \
  s3://YOUR_GLOBALLY_UNIQUE_BUCKET_NAME/learning/object.txt

aws s3api head-object \
  --bucket YOUR_GLOBALLY_UNIQUE_BUCKET_NAME \
  --key learning/object.txt

aws s3api list-object-versions \
  --bucket YOUR_GLOBALLY_UNIQUE_BUCKET_NAME \
  --prefix learning/object.txt
```

For `us-east-1`, omit `--create-bucket-configuration`; that API call handles
the Region differently. Avoid putting secrets in commands because shell history
and process inspection can expose them.

---

## AWS Snow Family

The **AWS Snow Family** is a group of physical devices historically used for
offline data transfer and edge computing when network transfer is impractical.
AWS changes device availability and ordering eligibility over time, so verify
current regional availability before designing a migration around a device.

Typical situations include:

- very large datasets
- limited internet bandwidth
- unreliable internet connectivity
- remote locations

### Common device concepts

| Device | Description |
|---|---|
| **AWS Snowcone** | Small, portable device for transferring a few terabytes of data |
| **AWS Snowball** | Larger device for moving very large datasets and supporting edge-computing scenarios |
| **AWS Snowmobile** | Historically offered truck-sized transfer for extremely large datasets; verify current availability |

Conceptually:

```text
On-Premises Data
       |
       v
Snow Device
       |
   Physical Transfer
       |
       v
AWS
```

---

## AWS Storage Gateway

**Amazon S3 File Gateway**, part of AWS Storage Gateway, connects on-premises
applications to objects in Amazon S3 while presenting familiar file protocols.

It acts as a bridge between local applications and AWS storage.

```text
On-Premises
Application Server
      |
      | Standard protocols
      v
Storage Gateway
      |
      | HTTPS
      v
AWS Cloud / Amazon S3
```

An on-premises gateway communicates securely with AWS services and maintains a
local cache where supported.

### Gateway types

#### Amazon S3 File Gateway

Used to store and access objects in Amazon S3 from file-based protocols such as:

- NFS
- SMB

with local caching.

#### Amazon FSx File Gateway

Provides access to fully managed file shares in Amazon FSx for Windows File Server using SMB.

#### Tape Gateway

Uses virtual tapes and supports archival storage in S3 archival services.

#### Volume Gateway

Provides iSCSI block-storage volumes connected to AWS storage.

---

## Security and Cost Guidance

- Keep S3 Block Public Access enabled at both account and bucket level unless a
  reviewed requirement explicitly needs public access.
- Prefer IAM roles and temporary credentials; never embed access keys in code,
  object metadata, or bucket policies.
- Grant only required actions on specific bucket and object ARNs. Remember that
  bucket operations and object operations use different ARN forms.
- Enable versioning for recovery, but combine it with lifecycle rules because
  noncurrent versions continue to consume storage.
- Use Object Lock only after understanding retention modes and deletion
  restrictions; it can intentionally make objects impossible to delete early.
- Review storage, requests, retrievals, early deletions, replication, KMS,
  internet transfer, and acceleration charges—not only the per-GB storage rate.
- Use cost-allocation tags, AWS Budgets, Storage Lens, and lifecycle policies to
  find and control unexpected growth.
- Do not place sensitive information in bucket names or object keys because
  names can appear in URLs and logs.

## Troubleshooting

### `AccessDenied`

Check the caller identity, IAM policy, bucket policy, access point policy,
permissions boundary, organization service control policies, Block Public
Access, object ownership, and KMS key policy. An explicit deny overrides an
allow.

### Redirect or region error

Confirm the bucket's Region and use the matching regional endpoint and client
configuration. Bucket names identify a resource globally within a partition,
but requests are served in the bucket's Region.

### Replication is not occurring

Confirm versioning on both buckets, the replication rule scope, IAM role
permissions, destination ownership settings, KMS permissions for encrypted
objects, and replication status in object metadata. Existing objects require a
separate replication approach such as S3 Batch Replication.

### Archive object cannot be downloaded

Objects in S3 Glacier Flexible Retrieval or Deep Archive must normally be
restored before they can be read. Start a restore request, wait for completion,
and download the temporary restored copy before its restore period expires.

## Cleanup

A bucket must be empty before deletion. With versioning enabled, deleting only
the visible current objects is insufficient because noncurrent versions and
delete markers remain.

1. Review retention, legal hold, Object Lock, replication, and backup needs.
2. Abort incomplete multipart uploads.
3. Delete all object versions and delete markers only when the data is no longer
   required.
4. Remove replication, access points, and dependent policies as appropriate.
5. Delete the empty practice bucket.
6. Remove the temporary local lab file.
7. Review Storage Lens, billing, KMS keys, CloudTrail data-event selectors, and
   log destinations for resources that can continue generating charges.

Never apply recursive deletion commands to a bucket until you have confirmed
the exact account, Region, bucket name, versioning state, and retention needs.

---

## Quick Revision

| Concept | Remember |
| --- | --- |
| S3 | Object storage service |
| Bucket | Container for S3 objects |
| Bucket name | Unique within an AWS partition for general-purpose buckets |
| Bucket location | Region-specific |
| Object | Key + data + metadata, with a version ID when versioning is enabled |
| Maximum object size | 5 TB |
| Large uploads | Multipart required above 5 GB; consider it from about 100 MB |
| Versioning | Keeps multiple versions of an object |
| SRR | Replication within the same Region |
| CRR | Replication across different Regions |
| Bucket Policy | JSON-based bucket access control |
| `GetObject` | Retrieve/download an object |
| `PutObject` | Upload/add an object |
| Lifecycle Transition | Move objects between storage classes |
| Lifecycle Expiration | Delete objects after a configured period |
| Snow Family | Physical data-transfer devices |
| Storage Gateway | Hybrid bridge between on-premises systems and AWS storage |
| Block Public Access | Guardrails that restrict public bucket and object access |
| Default encryption | New uploads are encrypted at rest with SSE-S3 by default |

---

## Learning Checklist

- [ ] Understand buckets and objects
- [ ] Understand key-value object naming
- [ ] Remember the 5 TB maximum object size
- [ ] Understand multipart upload
- [ ] Understand static website hosting use case
- [ ] Understand S3 Versioning
- [ ] Understand SRR vs CRR
- [ ] Understand S3 Bucket Policies
- [ ] Keep Block Public Access enabled and apply least privilege
- [ ] Compare common S3 storage classes
- [ ] Understand lifecycle transition and expiration actions
- [ ] Choose between SSE-S3 and AWS KMS-based encryption
- [ ] Use CloudTrail, CloudWatch, Inventory, and access logging appropriately
- [ ] Understand the purpose of the Snow Family
- [ ] Understand S3 Storage Gateway and its gateway types
- [ ] Create, verify, and completely remove a private versioned practice bucket

---

## Knowledge Check

1. How does an S3 object key differ from a filesystem path?
2. When is multipart upload required, and why might you use it for smaller
   objects?
3. What does versioning do when a user deletes an object without specifying a
   version ID?
4. Why is replication not a complete replacement for backup?
5. What is the difference between an IAM policy and a bucket policy?
6. Which storage class fits an archive that needs millisecond retrieval?
7. Why can an SSE-KMS request fail even when the caller has S3 permission?
8. Which resources must be removed before a versioned bucket can be deleted?

## References

- [What is Amazon S3? — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [Amazon S3 security best practices — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [Using versioning in S3 buckets — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)
- [Replicating objects — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Amazon S3 storage classes — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html)
- [Managing the lifecycle of objects — Amazon S3 User Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)

> AWS features, console labels, quotas, availability, and pricing can change.
> Verify production procedures against the current AWS documentation.
