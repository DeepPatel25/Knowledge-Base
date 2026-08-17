# Amazon Machine Images (AMI)

[← Back to Amazon EC2](../README.md) · [AWS learning path](../../README.md)

Amazon Machine Images (AMIs) are reusable templates used to launch
Amazon EC2 instances with a predefined operating system, software,
configuration, and block-device setup.

An AMI is useful when you want to create multiple EC2 instances with a
consistent server configuration instead of configuring every instance
manually.

------------------------------------------------------------------------

## Learning Objectives

After completing this guide, you should be able to:

- Explain what an AMI contains and how it relates to EBS snapshots.
- Choose a trusted AMI that is compatible with an instance type.
- Create, test, copy, share, and retire a custom AMI safely.
- Distinguish an AMI from an EBS snapshot and an EC2 launch template.
- Explain when EC2 Image Builder is preferable to manual image creation.

------------------------------------------------------------------------

## What is an AMI?

An **Amazon Machine Image (AMI)** contains the information Amazon EC2
needs to launch an instance.

Conceptually:

``` text
AMI
├── Operating System
├── Installed Software
├── Application Configuration
├── Root Volume
├── Additional EBS Snapshot Mappings
└── Block Device Configuration
```

For example, you can configure an EC2 instance with:

``` text
Ubuntu
   ↓
Nginx
   ↓
.NET / Node.js
   ↓
Application
   ↓
Configuration
```

Create an AMI from that instance and use the AMI as a reusable image for
new EC2 instances.

``` text
Configured EC2 Instance
          │
          ▼
      Create AMI
          │
          ▼
    Custom AMI
     /    |    \
    ▼     ▼     ▼
  EC2-1 EC2-2 EC2-3
```

This helps keep newly launched servers consistent.

------------------------------------------------------------------------

## What an AMI Contains

An AMI primarily defines the machine image and block-device mappings
required to create an EC2 instance.

Depending on what exists on the instance volumes when the image is
created, this can include:

-   Operating system
-   Installed packages
-   Web servers such as Apache or Nginx
-   Application binaries
-   Runtime environments
-   Configuration files
-   Environment configuration stored on disk
-   Users and operating-system configuration
-   EBS-backed filesystem data captured in snapshots

> An AMI should not be treated as a safe place for secrets. Remove
> credentials, private keys, tokens, shell history, and other sensitive
> machine-specific data before creating a reusable image.

------------------------------------------------------------------------

## Types of AMIs

### Public AMIs

Public AMIs are available for other AWS users to launch.

Common examples include operating-system images published by trusted
vendors.

Typical uses:

-   Amazon Linux
-   Ubuntu
-   Red Hat Enterprise Linux
-   Windows Server

Always verify the AMI owner before using a public image.

### Private AMIs

A custom AMI is private to your AWS account by default.

Private AMIs are useful for:

-   Company base images
-   Preconfigured application servers
-   Development environments
-   Standardized production servers
-   Golden images

An AMI can also be shared with specific AWS accounts when required.

### AWS Marketplace AMIs

AWS Marketplace contains images provided by third-party vendors.

They can include preconfigured:

-   Databases
-   Security products
-   Monitoring systems
-   Application servers
-   Development platforms

Marketplace software may have additional licensing charges beyond the
underlying AWS infrastructure cost.

------------------------------------------------------------------------

## Region and Compatibility Rules

An AMI is a Regional resource. To use the same image in another Region,
copy it to that Region and use the new AMI ID created there. AMI IDs are
also unique to each Region.

Before launching an instance, confirm that the AMI is compatible with:

- The instance type's CPU architecture, such as `x86_64` or `arm64`.
- The required boot mode and virtualization type.
- The desired root-device and storage configuration.
- Any product codes or licensing terms attached to the image.
- The target Region and account permissions.

When selecting a public image, verify its owner and publisher rather
than trusting an AMI name alone.

------------------------------------------------------------------------

## Why Use AMIs?

Without a custom AMI:

``` text
Launch EC2
   ↓
Install packages
   ↓
Install runtime
   ↓
Configure application
   ↓
Configure services
   ↓
Deploy application
```

With a custom AMI:

``` text
Launch EC2 from AMI
        ↓
Server starts with the predefined image
```

Benefits include:

-   Faster server provisioning
-   Repeatable environments
-   Consistent configurations
-   Easier horizontal scaling
-   Simplified recovery
-   Standardized server images
-   Reduced manual setup

------------------------------------------------------------------------

## Example Use Case

Suppose an application uses a LAMP stack:

``` text
Linux
Apache
MySQL
PHP
```

Instead of installing and configuring the stack on every new EC2
instance, you can prepare one instance and create a reusable AMI.

``` text
EC2 Instance
├── Linux
├── Apache
├── MySQL
├── PHP
└── Application configuration
        │
        ▼
     Create AMI
        │
        ▼
    Custom AMI
        │
        ├── EC2 Instance 1
        ├── EC2 Instance 2
        └── EC2 Instance 3
```

This is especially useful when instances need to be created repeatedly
or automatically.

------------------------------------------------------------------------

## Creating a Custom AMI

A common workflow is:

``` text
Launch Base EC2 Instance
          ↓
Install Required Software
          ↓
Configure the Server
          ↓
Test the Instance
          ↓
Remove Sensitive/Machine-Specific Data
          ↓
Create Image
          ↓
AMI + EBS Snapshots
          ↓
Launch New Instances
```

From the EC2 console:

1.  Open **EC2 → Instances**.
2.  Select the configured instance.
3.  Choose **Actions → Image and templates → Create image**.
4.  Enter an image name and description.
5.  Review the attached volume configuration.
6.  Create the image.
7.  Open **EC2 → AMIs** and wait until the AMI becomes available.
8.  Launch a test instance from the new AMI before depending on it.

By default, EC2 reboots the source instance before it creates snapshots
so that the filesystems have a consistent state. The console offers a
**No reboot** option, but skipping the reboot can produce crash-consistent
rather than application-consistent snapshots. Quiesce applications and
flush pending writes before using that option.

Creating an AMI does not automatically update existing instances. New
instances must be launched from the new AMI, usually through a new
launch-template version or a deployment process.

------------------------------------------------------------------------

## Cleanup Before Creating an AMI

A reusable image should not contain credentials or temporary
machine-specific information.

Examples of data that may need review or removal:

``` text
~/.aws/credentials
~/.git-credentials
shell history
temporary files
application secrets
private SSH keys
cached credentials
temporary deployment artifacts
```

Do **not** blindly delete system configuration, SSH configuration, logs,
users, or application files merely because a generic cleanup script
recommends it.

Before building a production AMI:

1.  Identify which data is machine-specific.
2.  Remove secrets and credentials.
3.  Preserve configuration required for the server to boot.
4.  Preserve application configuration that intentionally belongs in the
    image.
5.  Test the resulting image by launching a new instance.

------------------------------------------------------------------------

## AMI and EBS Snapshots

For EBS-backed instances, creating an AMI creates snapshots of the EBS
volumes included in the image.

``` text
EC2 Instance
     │
     ├── Root EBS Volume
     │        │
     │        ▼
     │    EBS Snapshot
     │
     └───────────────┐
                     ▼
                    AMI
```

The AMI references the snapshots and defines how volumes should be
created when a new instance is launched.

Therefore, an AMI is not simply one copied file containing the entire
virtual machine.

------------------------------------------------------------------------

## AMI vs EBS Snapshot

  Feature                                  AMI                    EBS Snapshot
  ---------------------------------------- ---------------------- ------------------------
  Main purpose                             Launch EC2 instances   Back up EBS volumes
  Contains launchable machine definition   Yes                    No
  References EBS snapshots                 Yes                    N/A
  Used directly to launch EC2              Yes                    No
  Typical use                              Server templates       Volume backup/recovery

An EBS snapshot focuses on storage.

An AMI combines the information needed to create a launchable EC2
machine image with its associated block-device mappings.

------------------------------------------------------------------------

## AMI vs Launch Template

AMIs and launch templates solve different problems.

### AMI

An AMI answers:

> **What should be installed on the machine?**

It represents the machine image.

Examples:

-   Operating system
-   Installed packages
-   Application files
-   Disk-level configuration

### Launch Template

A launch template answers:

> **How should EC2 launch the machine?**

It can define settings such as:

-   AMI
-   Instance type
-   Security groups
-   Storage configuration
-   IAM instance profile
-   Key pair
-   User data
-   Network configuration
-   Tags

### Comparison

  -----------------------------------------------------------------------
  Feature                 AMI                     Launch Template
  ----------------------- ----------------------- -----------------------
  Purpose                 Machine image           EC2 launch
                                                  configuration

  Operating system        Included                References an AMI

  Installed software      Captured in image       No
                          volumes                 

  Instance type           No                      Yes

  Security groups         No                      Yes

  IAM instance profile    No                      Yes

  User data               No                      Yes

  Versioning              AMIs are separate image Launch templates
                          resources               support versions
  -----------------------------------------------------------------------

A common production pattern is:

``` text
Custom AMI
    │
    ▼
Launch Template
    │
    ▼
Auto Scaling Group
    │
    ├── EC2
    ├── EC2
    └── EC2
```

------------------------------------------------------------------------

## Create Image vs Create Launch Template

When working with an existing EC2 instance, AWS provides both concepts.

Use **Create Image** when you want to capture the machine's disk-based
operating system, installed software, and configuration into a reusable
AMI.

Use a **Launch Template** when you want reusable EC2 launch parameters.

``` text
Existing EC2
    │
    ├── Create Image
    │       ↓
    │      AMI
    │
    └── Create Launch Template
            ↓
       Launch Configuration
```

In many environments they are used together rather than as alternatives.

------------------------------------------------------------------------

## AMI Lifecycle

A typical AMI lifecycle is:

``` text
Build
  ↓
Test
  ↓
Create AMI
  ↓
Validate
  ↓
Deploy
  ↓
Replace with New Version
  ↓
Deregister Old AMI
  ↓
Delete Unneeded Snapshots
```

Treat AMIs as immutable artifacts where practical.

Instead of repeatedly modifying production servers, build a new image,
test it, and replace instances with instances launched from the newer
image.

Use clear names and tags that identify the image's operating system,
application, version, owner, build date, and intended environment. AMI
IDs are immutable identifiers, while names and tags help people and
automation determine which image should be used.

------------------------------------------------------------------------

# EC2 Image Builder

Manually creating AMIs works for learning and small environments, but
regularly maintaining many images becomes repetitive.

**EC2 Image Builder** helps automate creation, customization, testing,
and distribution of machine images.

``` text
Source Image
     ↓
Build Components
     ↓
Test Components
     ↓
Image Builder Pipeline
     ↓
Custom AMI
     ↓
Distribution
```

Typical automation can include:

-   Installing packages
-   Applying operating-system updates
-   Installing application dependencies
-   Running configuration scripts
-   Testing the image
-   Producing new AMIs
-   Distributing images to configured Regions/accounts

------------------------------------------------------------------------

## Image Builder Pipeline

A simplified pipeline looks like:

``` text
Base AMI
   ↓
Image Recipe
   ↓
Build Instance
   ↓
Build Components
   ↓
Validation / Tests
   ↓
Output AMI
   ↓
Distribution
```

Image pipelines can be run manually or configured on a schedule.

This makes Image Builder useful for maintaining regularly updated golden
images.

------------------------------------------------------------------------

## Golden AMI Pattern

A **golden AMI** is an approved base image prepared according to an
organization's requirements.

For example:

``` text
Amazon Linux 2023
       ↓
Security Updates
       ↓
Monitoring Agent
       ↓
Runtime Dependencies
       ↓
Security Hardening
       ↓
Validation Tests
       ↓
Golden AMI
       ↓
Application Infrastructure
```

Benefits include:

-   Consistent base servers
-   Faster provisioning
-   Centralized patching strategy
-   Repeatable security configuration
-   Easier compliance
-   Reduced configuration drift

------------------------------------------------------------------------

## Image Builder and Launch Templates

Image Builder can work with EC2 launch templates during AMI
distribution.

A useful deployment flow is:

``` text
EC2 Image Builder
       ↓
New AMI
       ↓
New Launch Template Version
       ↓
Auto Scaling / Deployment
       ↓
New EC2 Instances
```

This separates:

``` text
AMI              → machine contents
Launch Template  → launch configuration
Image Builder    → automated image creation
```

------------------------------------------------------------------------

## Important Security Practices

-   Never bake AWS access keys into an AMI.
-   Prefer IAM roles for EC2 applications.
-   Remove private keys, tokens, passwords, and deployment credentials.
-   Do not make a custom AMI public unless it is intentionally prepared
    for public distribution.
-   Verify publishers when using public or Marketplace AMIs.
-   Encrypt EBS snapshots when required.
-   Patch the operating system and packages regularly.
-   Test new AMIs before production deployment.
-   Keep secrets in an appropriate secrets-management system rather than
    inside the image.
-   Review AMI permissions before sharing images across accounts.

------------------------------------------------------------------------

## Cost Considerations

Creating an AMI does not mean every associated resource is free.

Potential costs include:

-   EBS snapshot storage
-   EC2 instances used while building/testing images
-   Data transfer
-   Marketplace software licensing
-   Image Builder infrastructure/resources used during builds

Review and remove obsolete images and snapshots when they are no longer
required.

------------------------------------------------------------------------

## Cleanup

When an AMI is no longer needed:

1.  Confirm that no required deployment depends on it.
2.  Deregister the AMI.
3.  Identify snapshots associated with the image.
4.  Delete snapshots that are no longer required.
5.  Remove obsolete launch-template versions when appropriate.
6.  Review remaining EBS snapshot storage.

Be careful when deleting snapshots because they may still be required
for backup or recovery workflows.

------------------------------------------------------------------------

## Quick Reference

``` text
AMI
│
├── Reusable EC2 machine image
├── OS + disk-based software/configuration
├── References EBS snapshots
└── Used to launch EC2 instances

Launch Template
│
├── Reusable launch configuration
├── AMI
├── Instance type
├── Security groups
├── IAM role
├── Storage/network settings
└── User data

EC2 Image Builder
│
├── Builds images
├── Customizes images
├── Tests images
├── Automates pipelines
└── Distributes AMIs
```

------------------------------------------------------------------------

## Summary

An **AMI** is a reusable machine image for Amazon EC2.

Use an AMI when you need multiple EC2 instances with the same operating
system, installed software, and disk-level configuration.

Use a **Launch Template** to standardize the parameters used when EC2
launches those instances.

Use **EC2 Image Builder** when AMI creation, testing, patching, and
distribution should become an automated and repeatable pipeline.

A common scalable architecture is:

``` text
Base AMI
   ↓
EC2 Image Builder
   ↓
Golden AMI
   ↓
Launch Template
   ↓
Auto Scaling Group
   ↓
EC2 Instances
```

------------------------------------------------------------------------

## References

- [Amazon Machine Images (AMI) — Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
- [Create an Amazon EBS-backed AMI — Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-an-ami-ebs.html)
- [Launch templates — Amazon EC2 User Guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html)
- [What is EC2 Image Builder? — EC2 Image Builder User Guide](https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html)

> AWS behavior, pricing, supported operating systems, and service
> features can change. Verify production procedures against the current
> AWS documentation.
