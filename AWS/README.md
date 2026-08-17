# Amazon Web Services (AWS)

This section contains practical AWS learning notes, examples, and security guidance.

## Learning path

- [x] [Identity and Access Management (IAM)](./IAM/README.md)
- [ ] AWS global infrastructure: Regions, Availability Zones, and edge locations
- [x] [Elastic Compute Cloud (EC2)](./EC2/README.md): instances, AMIs, key pairs, security groups, storage, and pricing
  - [x] [Amazon Machine Images (AMI)](./EC2/AMI/README.md): image creation, EBS snapshots, launch templates, golden images, Image Builder, security, and cleanup
  - [x] [Elastic Load Balancing and Auto Scaling Groups](./EC2/Load%20Balancer/README.md): scalability, high availability, load balancer types, target groups, scaling policies, and hands-on setup
- [x] [Storage](./Storage/README.md): storage fundamentals and service-specific guides
  - [x] [Amazon Elastic Block Store (EBS)](./Storage/EBS/README.md): volumes, attachment, mounting, resizing, snapshots, encryption, and lifecycle management
- [ ] VPC: subnets, route tables, internet gateways, NAT, and network ACLs
- [ ] S3: buckets, objects, permissions, versioning, and lifecycle rules
- [ ] Databases: RDS, Aurora, and DynamoDB fundamentals
- [ ] Monitoring and auditing: CloudWatch and CloudTrail
- [ ] Infrastructure as code: CloudFormation or Terraform
- [ ] Cost management: budgets, alerts, and the AWS Pricing Calculator

## Recommended order

1. Learn IAM and secure the AWS account.
2. Understand Regions, Availability Zones, and the shared responsibility model.
3. Build a small EC2 and VPC lab.
4. Attach and manage an EBS volume, then practice snapshot recovery.
5. Add S3, a managed database, monitoring, and cost controls.
6. Rebuild the lab with infrastructure as code.

## Study rule

Use a sandbox account for practice, enable billing alerts, and delete unused resources after each lab. Never commit passwords, access keys, secret keys, or session tokens to this repository.
