# Amazon Web Services (AWS)

This section contains practical AWS learning notes, examples, and security guidance.

## Learning path

- [x] [Identity and Access Management (IAM)](./IAM/README.md)
- [ ] AWS global infrastructure: Regions, Availability Zones, and edge locations
- [ ] EC2: instances, AMIs, key pairs, security groups, and storage
- [ ] VPC: subnets, route tables, internet gateways, NAT, and network ACLs
- [ ] S3: buckets, objects, permissions, versioning, and lifecycle rules
- [ ] Databases: RDS, Aurora, and DynamoDB fundamentals
- [ ] Load balancing and Auto Scaling
- [ ] Monitoring and auditing: CloudWatch and CloudTrail
- [ ] Infrastructure as code: CloudFormation or Terraform
- [ ] Cost management: budgets, alerts, and the AWS Pricing Calculator

## Recommended order

1. Learn IAM and secure the AWS account.
2. Understand Regions, Availability Zones, and the shared responsibility model.
3. Build a small EC2 and VPC lab.
4. Add S3, a managed database, monitoring, and cost controls.
5. Rebuild the lab with infrastructure as code.

## Study rule

Use a sandbox account for practice, enable billing alerts, and delete unused resources after each lab. Never commit passwords, access keys, secret keys, or session tokens to this repository.
