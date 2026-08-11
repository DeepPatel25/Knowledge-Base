# AWS Identity and Access Management (IAM)

AWS Identity and Access Management (IAM) controls who can sign in to AWS and which actions they can perform on AWS resources. IAM is a global AWS service and has no additional charge, although resources accessed through IAM may have charges.

## Learning objectives

After completing this topic, you should be able to:

- Explain users, user groups, roles, and policies.
- Distinguish authentication from authorization.
- Describe console, CLI, SDK, and API access.
- Apply least privilege and protect the root user.
- Enable multi-factor authentication (MFA).
- Recognize and troubleshoot missing CLI credentials.
- Audit credentials and permissions.

## Key characteristics

- **Global service:** IAM resources are not tied to one AWS Region.
- **No additional IAM charge:** You pay for the AWS resources that identities use, not for IAM itself.
- **Root user exists by default:** Protect it with MFA and use it only for tasks that specifically require root credentials.
- **Explicit authorization:** Access is controlled by policies; an implicit deny applies unless a request is allowed.

## Core IAM concepts

### Users

An IAM user represents a person or workload that needs long-term credentials in one AWS account. Where possible, give human users federated access through IAM Identity Center instead of creating long-lived IAM users.

### User groups

A user group is a collection of IAM users. Attach permissions to a group when multiple users need the same job-based access. For example, users `paul` and `alex` can both belong to an `operations` group and receive the group's permissions. Groups cannot contain other groups, and roles cannot be added to groups.

### Roles

An IAM role is an identity with permissions but no long-term password or access keys. A trusted principal assumes the role and receives temporary credentials. Roles are preferred for AWS services, applications on AWS, cross-account access, and federated users.

### Policies

A policy is a JSON document that defines permissions. An identity-based policy can be attached to a user, group, or role. Resource-based policies are attached to supported resources, such as S3 buckets.

A policy statement commonly contains:

- `Effect`: `Allow` or `Deny`
- `Action`: API operations that are affected
- `Resource`: resources to which the operations apply
- `Condition`: optional restrictions on when the statement applies

Example read-only policy for one S3 bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::example-learning-bucket",
        "arn:aws:s3:::example-learning-bucket/*"
      ]
    }
  ]
}
```

Replace the example bucket name before using the policy.

## Authentication and authorization

- **Authentication** proves who or what is making the request—for example, a console password plus MFA or temporary role credentials.
- **Authorization** determines whether the authenticated principal may perform the requested action on the requested resource.

AWS evaluates all applicable policies. An explicit deny overrides an allow. Without an applicable allow, the request is denied.

## Multi-factor authentication (MFA)

MFA adds another verification factor to a password. It requires two or more forms of verification, such as a password and a one-time code or security key. Enable MFA for the root user and all human users. Prefer phishing-resistant options such as security keys when available.

## Ways to access AWS

- **AWS Management Console:** Browser-based graphical interface.
- **AWS CLI:** Commands suitable for interactive work and automation.
- **AWS SDKs:** Language-specific libraries used by applications.
- **AWS APIs:** Direct programmatic service requests.

## AWS CLI credentials

Check the installed CLI:

```bash
aws --version
```

Check the current caller identity:

```bash
aws sts get-caller-identity
```

If the CLI reports `Unable to locate credentials`, it did not find a usable credential provider. Configure an authorized identity before retrying the command.

For a local learning profile, configure a named profile rather than overwriting the default profile:

```bash
aws configure --profile learning
aws sts get-caller-identity --profile learning
```

Do not paste secret access keys into source files or commit the files in `~/.aws/`. For production workloads on AWS, attach an IAM role to the compute service so the SDK or CLI can obtain temporary credentials automatically. For human access, prefer IAM Identity Center and short-lived sessions.

## Best practices

- Protect the root user with MFA; do not create root access keys.
- Use the root user only for tasks that require it.
- Prefer federation and IAM Identity Center for workforce access.
- Prefer roles and temporary credentials for workloads.
- Grant least privilege and refine permissions as usage becomes known.
- Use groups or permission sets to manage job-based access consistently.
- Require MFA for human access.
- Rotate or remove credentials that are no longer needed.
- Never share passwords or access keys.
- Review IAM Access Analyzer findings and credential reports.
- Use CloudTrail to record account activity.

## Hands-on learning checklist

- [x] Enable MFA on the AWS account root user.
- [x] Create an administrative identity for daily tasks and stop using root.
- [x] Create a user group and attach a limited AWS managed policy in a sandbox account.
- [x] Compare a user, group, and role in the IAM console.
- [x] Open a managed policy and identify its effect, actions, resources, and conditions.
- [x] Create a least-privilege customer-managed policy for a test resource.
- [x] Configure a named CLI profile or an IAM Identity Center session.
- [x] Run `aws sts get-caller-identity` and explain every field.
- [x] Assume a role and observe that its credentials are temporary.
- [x] Generate and review the IAM credential report.
- [x] Remove every test identity, policy, and credential created by the lab.

## Common mistakes

- Using the root user for routine administration.
- Attaching `AdministratorAccess` when narrower permissions are sufficient.
- Creating access keys for workloads that can use an IAM role.
- Sharing one IAM user among multiple people.
- Storing secrets in Git, screenshots, shell history, or application configuration.
- Assuming that a policy's allow always wins; an explicit deny takes precedence.
- Confusing a role's trust policy (who may assume it) with its permissions policies (what it may do).

## Quick review

1. When should an IAM role be used instead of an IAM user?
2. Why should permissions generally be assigned through groups or permission sets?
3. What is the difference between authentication and authorization?
4. What wins when one applicable policy allows an action and another explicitly denies it?
5. Why are temporary credentials safer than long-lived access keys?
6. What does `aws sts get-caller-identity` tell you?

## Continue learning

Return to the [AWS learning path](../README.md) and continue with global infrastructure, EC2, and VPC fundamentals.
