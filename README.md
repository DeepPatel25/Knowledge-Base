# Knowledge Base

A practical collection of learning notes, operational guides, and reusable scripts for cloud infrastructure, containers, Linux administration, databases, source-control access, and macOS maintenance.

The guides favor secure defaults, reproducible commands, verification steps, troubleshooting advice, and explicit cleanup instructions.

## Contents

### Amazon Web Services

- [AWS learning path](./AWS/README.md) — an ordered roadmap for learning core AWS services and operational practices.
  - [Identity and Access Management (IAM)](./AWS/IAM/README.md) — identities, roles, policies, MFA, credentials, and least privilege.
  - [Elastic Compute Cloud (EC2)](./AWS/EC2/README.md) — instances, AMIs, instance types, EBS, networking, security groups, access methods, pricing, and an Apache lab.
    - [Amazon Machine Images (AMI)](./AWS/EC2/AMI/README.md) — reusable EC2 images, custom image creation, EBS snapshots, launch templates, golden images, and EC2 Image Builder.
    - [Elastic Load Balancing and Auto Scaling Groups](./AWS/EC2/Load%20Balancer/README.md) — scalable and highly available EC2 architectures, load balancer types, target groups, health checks, and scaling policies.
  - [AWS Storage](./AWS/Storage/README.md) — storage guides covering selection, configuration, backup, security, and operations.
    - [Amazon Elastic Block Store (EBS)](./AWS/Storage/EBS/README.md) — persistent EC2 block storage, volume management, snapshots, encryption, and lifecycle automation.
    - [Amazon Simple Storage Service (S3)](./AWS/Storage/S3/README.md) — object storage, permissions, versioning, replication, storage classes, lifecycle automation, encryption, and monitoring.
  - [AWS Databases](./AWS/Database/README.md) — managed database selection, networking, availability, scaling, backup, monitoring, security, and operations.
    - [Amazon Relational Database Service (RDS)](./AWS/Database/RDS/README.md) — relational engines, Aurora, Multi-AZ deployments, Read Replicas, backups, monitoring, security, and an EC2-to-RDS MySQL lab.

### Amazon Linux 2023

- [Install and configure MySQL on Amazon EC2](./Amazon%20Linux%202023/MySQL/README.md) — MySQL Community Server installation, database setup, user management, verification, and cleanup on Amazon Linux 2023.

### Docker

- [Docker command guide](./Docker/README.md) — images, containers, troubleshooting, Docker Hub, persistent storage, networking, security, and cleanup.

### Ubuntu

- [Install and configure MySQL on Amazon EC2](./Ubuntu/MySQL/README.md) — MySQL installation, database and user setup, security guidance, verification, and helper scripts.
- [Clone a private GitHub repository with a deploy key](./Ubuntu/GitHub-Deploy-Key/README.md) — repository-scoped SSH access from an Ubuntu EC2 instance.
- [Manage an Ubuntu user password on EC2](./Ubuntu/User-Password/README.md) — password creation, sudo behavior, SSH authentication, and safer access recommendations.

### macOS

- [Inspect and clean up storage](./macOS/Storage-Cleanup/README.md) — disk-usage inspection and cautious cleanup commands for common macOS storage locations.

## Repository structure

```text
Knowledge-Base/
├── AWS/
│   ├── Database/
│   │   └── RDS/
│   ├── EC2/
│   │   ├── AMI/
│   │   └── Load Balancer/
│   ├── IAM/
│   └── Storage/
│       ├── EBS/
│       └── S3/
├── Amazon Linux 2023/
│   └── MySQL/
├── Docker/
├── Ubuntu/
│   ├── GitHub-Deploy-Key/
│   ├── MySQL/
│   └── User-Password/
└── macOS/
    └── Storage-Cleanup/
```

Each topic lives in a focused directory with a `README.md`. Supporting scripts are stored beside the guide that explains them.

## How to use this knowledge base

1. Open the relevant topic guide from the contents above.
2. Read its prerequisites and security notes before running commands.
3. Replace placeholders such as `YOUR_EC2_PUBLIC_IP` with values from your environment.
4. Run commands one section at a time and verify the stated result.
5. Use a sandbox or non-production environment for practice.
6. Complete the cleanup section to avoid unused resources and unexpected charges.

## Available helper scripts

| Script                                                                                                         | Purpose                                             |
| -------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| [`Ubuntu/MySQL/install_mysql.sh`](./Ubuntu/MySQL/install_mysql.sh)                                             | Install MySQL Server on Ubuntu.                     |
| [`Ubuntu/MySQL/change_mysql_root_password.sh`](./Ubuntu/MySQL/change_mysql_root_password.sh)                   | Change the local MySQL root password interactively. |
| [`Ubuntu/MySQL/setup_mysql_user.sh`](./Ubuntu/MySQL/setup_mysql_user.sh)                                       | Create or configure a MySQL database user.          |
| [`Ubuntu/GitHub-Deploy-Key/setup-github-deploy-key.sh`](./Ubuntu/GitHub-Deploy-Key/setup-github-deploy-key.sh) | Configure a repository deploy key interactively.    |

Inspect every script before running it. Execute scripts only on systems you are authorized to administer.

## Security principles

- Never commit passwords, private keys, access keys, tokens, or production configuration.
- Prefer temporary AWS credentials and IAM roles over long-lived access keys.
- Apply least privilege to IAM policies, database users, security groups, and deploy keys.
- Restrict SSH, RDP, and database access to trusted sources; do not expose administrative ports to the entire internet.
- Back up important data and confirm the target before running commands that modify or delete resources.
- Keep operating systems, packages, and dependencies patched.
- Review cloud costs and remove unused instances, volumes, snapshots, addresses, and other resources.

## Contributing a guide

When adding a topic:

1. Place it under the appropriate platform or service directory.
2. Add a descriptive `README.md` with prerequisites, procedures, verification, troubleshooting, security notes, and cleanup where relevant.
3. Keep commands copyable and use obvious placeholders instead of real credentials or account details.
4. Put reusable scripts beside their guide and make them safe to rerun when practical.
5. Add the new guide to this index and to any relevant learning path.
6. Check Markdown links and review the diff before committing.

## Disclaimer

Commands and cloud-service behavior can vary by operating-system version, software release, AWS Region, and account configuration. Review current vendor documentation and pricing before applying a guide to production.
