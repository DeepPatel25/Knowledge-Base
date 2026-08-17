# Amazon Elastic Compute Cloud (EC2)

Amazon Elastic Compute Cloud (EC2) provides resizable virtual servers, called **instances**, in AWS. An instance combines an operating-system image, compute capacity, storage, networking, identity, and firewall settings. You can launch it when needed, resize it as requirements change, and stop or terminate it when it is no longer required.

## Learning objectives

After completing this topic, you should be able to:

- Explain instances, Amazon Machine Images (AMIs), instance types, and EBS volumes.
- Choose an instance family for a workload.
- Launch an instance in a VPC and connect to it securely.
- Configure security-group rules for SSH, HTTP, and HTTPS.
- Use user data to bootstrap a web server.
- Explain how Elastic Load Balancing and Auto Scaling Groups provide scalable, highly available applications.
- Compare On-Demand, Spot, Reserved Instances, and Savings Plans.
- Stop, start, reboot, and terminate an instance safely.

## EC2 mental model

Instead of buying and maintaining a physical server, you rent compute capacity from AWS. When launching an instance, decide:

- **Where:** Region, Availability Zone, VPC, and subnet.
- **Operating system:** An AMI such as Amazon Linux, Ubuntu, or Windows Server.
- **Compute capacity:** An instance type that defines vCPUs, memory, networking, and sometimes local storage or accelerators.
- **Storage:** One or more Amazon Elastic Block Store (EBS) volumes, or instance-store volumes on supported types.
- **Network access:** Private/public IP addressing and security groups.
- **Administrative access:** SSH key pair, EC2 Instance Connect, Systems Manager Session Manager, or RDP for Windows.
- **AWS permissions:** An optional IAM role attached through an instance profile.
- **Bootstrap actions:** Optional user-data code that runs during the initial boot by default.

## Core components

### Amazon Machine Image (AMI)

An AMI is a launch template for the root volume of an instance. It contains an operating system and can include preinstalled applications and configuration. AMIs are specific to a Region and processor architecture. Select an AMI compatible with the chosen instance type, such as `x86_64` or `arm64`.

AMI sources include:

- AWS-provided images such as Amazon Linux and Windows Server.
- Verified publishers and AWS Marketplace products.
- Community AMIs, which require careful trust and security review.
- Private AMIs created from your configured instances.

See the [Amazon Machine Images (AMI) guide](./AMI/README.md) for image contents, custom AMI creation, EBS snapshot relationships, launch templates, golden images, EC2 Image Builder, security, and cleanup.

### Instance type

An instance type determines the hardware capacity available to the virtual machine. Its name combines a family, generation, options, and size. For example, in `t3.micro`, `t` is the burstable general-purpose family, `3` is the generation, and `micro` is the size.

Common workload categories:

| Category              | Typical families | Good for                                                              |
| --------------------- | ---------------- | --------------------------------------------------------------------- |
| General purpose       | T, M             | Web applications, development, small and balanced workloads           |
| Compute optimized     | C                | Batch processing, high-performance web servers, media encoding        |
| Memory optimized      | R, X             | In-memory databases, caching, real-time analytics                     |
| Accelerated computing | G, P, Inf, Trn   | Graphics, machine learning, inference, training                       |
| Storage optimized     | I, D, H          | High-throughput databases, data warehousing, distributed file systems |

Family availability, sizes, processors, and prices vary by Region. Measure the workload and right-size it rather than selecting an instance from its name alone.

### Storage

The root device is usually an EBS volume. EBS is persistent block storage: by default, stopping an EBS-backed instance preserves its volumes. Additional EBS volumes can be attached independently.

Important choices include:

- Volume type, such as general-purpose SSD or provisioned-IOPS SSD.
- Capacity, throughput, and IOPS.
- Encryption with an AWS managed or customer-managed KMS key.
- Whether the volume is deleted when the instance is terminated.
- Snapshot and backup policy.

Instance-store volumes are physically attached to the host and are temporary. Their data does not survive instance stop, termination, or underlying host failure. Use them only for disposable data such as caches or scratch space.

### Networking

Every instance launches into a subnet in a VPC and receives a private IP address. It may also receive a public IPv4 address when the subnet and launch configuration allow one. A public address can change after an instance is stopped and started. Use an Elastic IP only when a stable public IPv4 address is genuinely needed, and release it when it is no longer used to avoid charges.

For internet access, the route and addressing must also be correct:

- A public subnet normally has a route to an internet gateway.
- An internet-facing instance needs a public IPv4 address or Elastic IP.
- A private instance can make outbound connections through a NAT device or another controlled egress path.
- Security groups and network ACLs must permit the required traffic.

### IAM role

Attach an IAM role when software on the instance must call AWS APIs. The instance receives temporary credentials automatically. Do not copy long-lived access keys onto an instance.

Grant the role only the actions and resources the workload needs. A role controls AWS API permissions; it does not replace operating-system accounts or network controls.

## Security groups

A security group is a **stateful virtual firewall** attached to an instance's network interface. It contains allow rules only; traffic not allowed by a rule is denied. If a request is permitted, its response traffic is automatically permitted regardless of the opposite-direction rules.

Security groups belong to a VPC and are usable only in the Region containing that VPC. You can attach multiple security groups to an instance; AWS combines all their rules.

Rules specify:

- Protocol, such as TCP, UDP, or ICMP.
- Port or port range, where applicable.
- Source for inbound traffic or destination for outbound traffic.
- An optional description explaining the rule's purpose.

Typical inbound rules for a small Linux web server:

| Purpose            | Protocol | Port | Recommended source                                                      |
| ------------------ | -------- | ---- | ----------------------------------------------------------------------- |
| SSH administration | TCP      | 22   | Your current public IP as `/32`, or avoid the port with Session Manager |
| HTTP website       | TCP      | 80   | `0.0.0.0/0` and `::/0` only for a public site                           |
| HTTPS website      | TCP      | 443  | `0.0.0.0/0` and `::/0` only for a public site                           |

Other familiar ports include RDP `3389`, DNS `53`, MySQL `3306`, and PostgreSQL `5432`. Do not expose database or administrative ports to the entire internet. Prefer private subnets and allow traffic from a specific application security group.

### Security-group safety rules

- Start with no inbound access and add only what the application requires.
- Restrict SSH and RDP to a trusted IP range; never use `0.0.0.0/0` casually.
- Prefer Session Manager for administrative access when possible.
- Use security-group references between application tiers instead of hard-coded IP addresses.
- Give each rule a useful description and remove obsolete rules.
- Review outbound access too; the common default allows all outbound traffic.
- Remember that network ACLs are stateless and operate at the subnet boundary, unlike security groups.

## Key pairs and connection methods

An EC2 key pair consists of a public key stored by AWS and a private key kept by you. AWS places the public key on supported Linux instances during launch. The private key cannot be downloaded again after creation, so store it securely and never commit it to Git.

Common connection methods:

- **Systems Manager Session Manager:** Browser or CLI shell without opening inbound SSH; requires the SSM agent, an IAM instance role, and network access to Systems Manager.
- **EC2 Instance Connect:** Pushes a temporary SSH public key to a supported instance; network reachability to SSH is still required unless using an Instance Connect Endpoint.
- **SSH:** Uses the private key and the correct AMI username.
- **RDP:** Used for Windows instances with tightly restricted port `3389` access.

Example SSH connection for Amazon Linux:

```bash
chmod 400 learning-key.pem
ssh -i learning-key.pem ec2-user@PUBLIC_DNS_OR_IP
```

For Ubuntu AMIs, the common username is `ubuntu`. Confirm the username in the AMI documentation instead of guessing it.

## Launch a small Apache web server

This lab creates a public demonstration server. Use a sandbox account, confirm the selected resources' prices, and terminate everything afterward.

### 1. Choose the launch settings

In the EC2 console, choose **Launch instance**, then configure:

1. A descriptive name such as `ec2-apache-lab`.
2. A current Amazon Linux 2023 AMI.
3. A small instance type appropriate for the account and Region.
4. A key pair if SSH will be used, or plan to use Session Manager.
5. A VPC and public subnet with automatic public IPv4 addressing for this lab.
6. A security group allowing HTTP `80` from the internet and SSH `22` only from your IP if needed.
7. An encrypted EBS root volume with delete-on-termination enabled for this disposable lab.

### 2. Add user data

Paste this script into **Advanced details > User data**:

```bash
#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y httpd
systemctl enable --now httpd

cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><title>EC2 lab</title></head>
  <body><h1>Apache is running on Amazon EC2</h1></body>
</html>
HTML
```

This script is written for Amazon Linux 2023, which uses `dnf`. Package commands differ across operating systems. User-data output can be inspected in `/var/log/cloud-init-output.log` when troubleshooting.

### 3. Verify the instance

Wait until both EC2 status checks pass, then open:

```text
http://PUBLIC_IPV4_ADDRESS
```

If the page does not load, check:

- The instance is running and both status checks pass.
- The subnet route table has a route to an internet gateway.
- The instance has a public IPv4 address.
- The security group allows inbound TCP `80` from your client.
- Apache is running: `sudo systemctl status httpd`.
- User data completed: `sudo tail -n 100 /var/log/cloud-init-output.log`.

### 4. Clean up

Terminate the lab instance, then verify that its disposable EBS volumes were deleted. Delete the lab security group and release any Elastic IP created for the exercise. Check the billing dashboard after cleanup.

## Instance lifecycle

| Action    | Compute billing               | EBS data                             | Important effect                                                                  |
| --------- | ----------------------------- | ------------------------------------ | --------------------------------------------------------------------------------- |
| Reboot    | Continues                     | Preserved                            | Restarts the operating system, normally on the same host                          |
| Stop      | Stops for most instance usage | Preserved                            | Public IPv4 can change; some attached-resource charges continue                   |
| Start     | Resumes                       | Preserved                            | Instance may move to another host                                                 |
| Terminate | Stops                         | Root volume often deleted by default | Instance cannot be recovered; retained volumes and snapshots can still cost money |

Stopping an instance does not make the environment free. EBS volumes, snapshots, Elastic IPs, and other attached services can continue to incur charges.

## Purchasing options

| Option                       | Best suited to                                                       | Commitment and interruption                                                              |
| ---------------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| On-Demand Instances          | New, short-term, or unpredictable workloads                          | No long-term commitment; not interrupted by EC2 for capacity-price reasons               |
| Savings Plans                | Steady compute usage where flexibility is useful                     | Commit to an hourly spend for one or three years                                         |
| Reserved Instances           | Predictable EC2 usage or capacity reservation requirements           | One- or three-year term; details vary by Standard, Convertible, and zonal/regional scope |
| Spot Instances               | Fault-tolerant batch, CI, rendering, analytics, and distributed work | Uses spare capacity at a discount and can be interrupted with short notice               |
| Dedicated Hosts or Instances | Licensing, compliance, or host-isolation requirements                | Higher cost; tenancy and commitment options vary                                         |

Discounts and terms change, so check the current AWS pricing pages and use the AWS Pricing Calculator before making a commitment. Design Spot workloads to checkpoint, retry, and distribute work across instance types and Availability Zones.

## Cost and operational controls

- Create an AWS Budget and billing alerts before launching resources.
- Add tags such as `Name`, `Environment`, `Owner`, and `CostCenter`.
- Right-size with CloudWatch metrics and AWS Compute Optimizer where appropriate.
- Stop or terminate unused instances automatically in sandbox environments.
- Delete unused EBS volumes and old snapshots after confirming retention requirements.
- Use Auto Scaling rather than permanently overprovisioning for peak demand.
- Patch the operating system and applications; AWS secures the underlying cloud, while you secure the guest system and workload.
- Send logs and metrics off the instance so they survive replacement or failure.

## Common mistakes

- Launching into the wrong Region or Availability Zone.
- Choosing an AMI with the wrong CPU architecture for the instance type.
- Opening SSH, RDP, or a database port to `0.0.0.0/0`.
- Storing AWS access keys on the instance instead of attaching an IAM role.
- Losing the private key or committing it to a repository.
- Assuming a security-group rule alone creates network connectivity.
- Treating instance-store data as persistent.
- Forgetting that public IPv4 addresses can change after stop/start.
- Stopping an instance and assuming all charges have stopped.
- Terminating an instance without checking volume deletion and backup settings.
- Depending on manual configuration instead of repeatable user data or infrastructure as code.

## Hands-on learning checklist

- [ ] Launch an Amazon Linux instance in a sandbox VPC.
- [ ] Explain every launch choice: AMI, type, subnet, storage, key pair, role, and security group.
- [ ] Bootstrap Apache with user data and inspect the cloud-init log.
- [ ] Reach the page over HTTP, then remove the HTTP rule and observe the result.
- [ ] Connect with Session Manager or SSH restricted to your IP.
- [ ] Attach an IAM role with a narrowly scoped test permission.
- [ ] Stop and start the instance and observe its addressing and lifecycle state.
- [ ] Inspect its EBS volume and delete-on-termination setting.
- [ ] Review monitoring, tags, and estimated cost.
- [ ] Terminate all lab resources and verify cleanup.

## Quick review

1. What is the difference between an AMI and an instance type?
2. Why can a security group omit a response rule for an allowed inbound request?
3. What else is required for internet access besides a permissive security-group rule?
4. Why is an IAM role preferable to access keys stored on an instance?
5. What data can be lost when an instance with instance-store storage is stopped?
6. Why might a public IPv4 address change after stop/start?
7. Which purchasing option fits an interruptible batch workload?
8. Which resources may still cost money after an instance is stopped?

## Continue learning

- Study [Amazon Machine Images (AMI)](./AMI/README.md) in depth, including custom images and EC2 Image Builder.
- Learn how to combine [Elastic Load Balancing and Auto Scaling Groups](./Load%20Balancer/README.md) for scalable, highly available EC2 applications.
- Return to the [AWS learning path](../README.md) and continue with VPC networking, monitoring, and infrastructure as code.
