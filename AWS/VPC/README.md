# Amazon VPC (Virtual Private Cloud)

[← Back to the AWS learning path](../README.md)

Amazon VPC (**Virtual Private Cloud**) lets you define a logically isolated
virtual network in an AWS Region, including IP address ranges, subnets,
routing, gateways, endpoints, and layered traffic controls.

---

## Table of Contents

- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [What is AWS VPC?](#what-is-aws-vpc)
- [Why Do We Need a VPC?](#why-do-we-need-a-vpc)
- [Region and Availability Zones](#region-and-availability-zones)
- [CIDR](#cidr)
- [Subnets](#subnets)
- [Public and Private Subnets](#public-and-private-subnets)
- [Route Tables](#route-tables)
- [Internet Gateway](#internet-gateway)
- [Security Groups](#security-groups)
- [Network ACLs](#network-acls)
- [NAT Gateway](#nat-gateway)
- [VPC Peering](#vpc-peering)
- [VPC Endpoints](#vpc-endpoints)
- [Bastion Host](#bastion-host)
- [Elastic IP Address](#elastic-ip-address)
- [IPv6 and Egress-Only Internet Gateway](#ipv6-and-egress-only-internet-gateway)
- [VPC Flow Logs](#vpc-flow-logs)
- [AWS Direct Connect](#aws-direct-connect)
- [Transit Gateway](#transit-gateway)
- [AWS Client VPN](#aws-client-vpn)
- [Complete VPC Architecture](#complete-vpc-architecture)
- [Typical Web Application Architecture](#typical-web-application-architecture)
- [Quick Revision](#quick-revision)
- [Security Group vs Network ACL](#security-group-vs-network-acl)
- [Internet Gateway vs NAT Gateway](#internet-gateway-vs-nat-gateway)
- [Security and Cost Guidance](#security-and-cost-guidance)
- [Troubleshooting](#troubleshooting)
- [Cleanup Checklist](#cleanup-checklist)
- [Key Takeaways](#key-takeaways)
- [Knowledge Check](#knowledge-check)
- [References](#references)
- [Final Mental Model](#final-mental-model)

---

## Learning Objectives

After completing this guide, you should be able to:

- Plan non-overlapping IPv4 CIDR blocks and subnets across Availability Zones.
- Explain what makes a subnet public or private.
- Trace routes through internet gateways, NAT gateways, and VPC endpoints.
- Distinguish stateful security groups from stateless network ACLs.
- Compare VPC peering, Transit Gateway, VPN, and Direct Connect.
- Use Flow Logs and reachability checks to troubleshoot network paths.
- Design and safely clean up a basic multi-AZ VPC.

## Prerequisites

Use a sandbox account with billing alerts enabled. You should understand IPv4
addresses, CIDR notation, ports, protocols, routing, DNS, and the difference
between inbound and outbound traffic. Plan address ranges before creating
resources because overlapping CIDRs restrict future connectivity options.

---

## What is AWS VPC?

A **Virtual Private Cloud (VPC)** is a logically isolated regional network where
you control addressing, subnet placement, routing, and traffic boundaries for
supported AWS resources.

```text
AWS Cloud
|
+------------------------------------------------+
|                 Your VPC                       |
|                                                |
|     EC2       Database       Applications      |
|                                                |
+------------------------------------------------+
```

A VPC gives you control over the network environment used by your AWS
resources.

---

## Why Do We Need a VPC?

The main purpose of a VPC is to:

> Securely isolate and control your network environment.

Suppose your website is ready:

```text
Website/Application
        |
        v
Where should it be deployed?
        |
        v
AWS
```

AWS infrastructure is divided geographically.

```text
AWS
 |
 +-- US
 |
 +-- Europe
 |
 +-- Asia
```

You first choose a **Region** and then create networking infrastructure
for your application.

---

## Region and Availability Zones

### Region

A **Region** is a geographical AWS location.

For example, an application might use the Mumbai Region.

```text
Asia
 |
 +-- Singapore
 +-- Mumbai
 +-- Hyderabad
 +-- Tokyo
```

Your VPC belongs to a Region.

```text
AWS
 |
 v
Region
 |
 v
VPC
```

Example:

```text
Region: Mumbai
       |
       v
     MY-VPC
```

---

### Availability Zones

A Region contains multiple **Availability Zones (AZs)**.

Conceptually:

```text
Mumbai Region
 |
 +-- Availability Zone A
 |
 +-- Availability Zone B
 |
 +-- Availability Zone C
```

Subnets can be placed within Availability Zones to organize resources.

---

## CIDR

**CIDR** stands for:

```text
Classless Inter-Domain Routing
```

CIDR is a method used for allocating IP addresses and routing IP
packets.

A VPC is assigned a CIDR block.

Example:

```text
MY-VPC
10.0.0.0/16
```

The CIDR block determines the IP address range available inside the
network.

---

### Understanding `/24`

Example:

```text
10.0.1.0/24
```

The full range is:

```text
10.0.1.0
    |
    |
    v
10.0.1.255
```

`/24` means the first **24 bits** represent the network portion.

The remaining **8 bits** are available for host addresses.

```text
32-bit IPv4 Address

+------------------------+--------+
|     Network Bits       | Hosts  |
|        24 bits         | 8 bits |
+------------------------+--------+
```

---

## Subnets

A **Subnet** is a smaller segmented portion of a larger network.

It helps isolate and organize resources within a specific IP address
range.

```text
                  VPC
             10.0.0.0/16
                  |
          +-------+-------+
          |               |
          v               v
      Subnet A         Subnet B
     10.0.0.0/24      10.0.1.0/24
```

When creating a subnet, you assign it a CIDR block that falls within the
VPC's CIDR range.

The subnet CIDR determines the pool of IP addresses available to
resources in that subnet.

Each subnet belongs to exactly one Availability Zone. AWS reserves the first
four and last IPv4 addresses in every subnet CIDR, so a `/24` does not provide
all 256 addresses to resources. Leave space for growth, load-balancer nodes,
Fargate tasks, managed databases, and other elastic network interfaces.

---

## Public and Private Subnets

A common VPC design separates resources into:

```text
                MY-VPC
              10.0.0.0/16
                   |
        +----------+----------+
        |                     |
        v                     v
 Public Subnet          Private Subnet
 10.0.0.0/24            10.0.1.0/24
```

### Public Subnet

A public subnet is commonly used for resources that need internet-facing
connectivity.

A subnet is considered public when its associated route table has a route to an
internet gateway. A resource in that subnet also needs a public IPv4 address or
Elastic IP, or an IPv6 address with suitable routing, plus permissive security
controls before it can communicate with the internet.

Examples:

```text
Public Subnet
 |
 +-- Web Server
 +-- Load Balancer
 +-- Bastion Host
```

### Private Subnet

A private subnet is commonly used for resources that should not accept
direct connections from the public internet.

Private does not automatically mean isolated. A private subnet may have
outbound internet access through a NAT gateway, private access to AWS services
through VPC endpoints, or connectivity to other networks. An isolated subnet
has no route beyond the intended private network paths.

Examples:

```text
Private Subnet
 |
 +-- Application Server
 +-- Database
 +-- Internal Services
```

---

## Route Tables

A **Route Table** determines where network traffic from a subnet should
be sent.

Conceptually:

```text
Subnet
  |
  v
Route Table
  |
  +-- Local VPC traffic
  |
  +-- Internet traffic -> Internet Gateway
```

A route table contains routing rules called **routes**.

Example:

```text
Destination        Target
--------------------------------
10.0.0.0/16        local
0.0.0.0/0          Internet Gateway
```

The route table is an important part of deciding how resources
communicate.

Every route table includes a local route for each VPC CIDR. Longest-prefix match
selects the most specific applicable route. A subnet uses one explicitly
associated route table or the VPC's main route table; changing the main table
can therefore affect subnets without explicit associations.

---

## Internet Gateway

An **Internet Gateway (IGW)** allows communication between resources in
a VPC and the internet.

```text
Internet
    |
    v
Internet Gateway
    |
    v
   VPC
    |
    v
Public Subnet
    |
    v
EC2 Instance
```

A typical public network path is:

```text
EC2
 |
 v
Public Subnet
 |
 v
Route Table
 |
 v
Internet Gateway
 |
 v
Internet
```

An internet gateway is attached to a VPC, but attachment alone creates no
connectivity. The subnet route, resource addressing, security group, network
ACL, and return path must all be correct.

---

## Security Groups

A **Security Group** provides network firewall rules that control
inbound and outbound traffic for instances/resources.

```text
Internet
    |
    v
Security Group
    |
    v
EC2 Instance
```

It controls traffic such as:

```text
Inbound Traffic
      |
      v
Security Group
      |
      v
Instance
      |
      v
Security Group
      |
      v
Outbound Traffic
```

Security Groups operate around the resource/instance level.

Security groups are **stateful** and contain allow rules only. Return traffic
for an allowed connection is automatically permitted. When multiple security
groups are attached, their allow rules are combined.

---

## Network ACLs

**Network ACL (Network Access Control List)** is an optional security
layer for a VPC.

It acts as a firewall controlling traffic entering and leaving one or
more subnets.

```text
Traffic
   |
   v
Network ACL
   |
   v
Subnet
   |
   v
Resources
```

Network ACL rules can:

```text
ALLOW
or
DENY
```

A useful conceptual distinction is:

```text
Security Group -> Resource / Instance level

Network ACL    -> Subnet level
```

Network ACLs are **stateless**. Rules are evaluated in number order until the
first match, and both request and response traffic—including ephemeral
ports—must be allowed explicitly. The default network ACL allows traffic; a
custom network ACL initially denies all traffic until rules are added.

---

## NAT Gateway

A **NAT (Network Address Translation) Gateway** enables instances in a
**private subnet** to connect to the internet or other AWS services
while preventing the internet from initiating connections directly to
those private instances.

Example use case:

```text
Private EC2 Instance
       |
       | Needs software updates
       v
   NAT Gateway
       |
       v
Internet Gateway
       |
       v
    Internet
```

For example, an application server in a private subnet may need to
download:

```text
OS Updates
Packages
Dependencies
Security Patches
```

The connection flow is:

```text
Private Subnet
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet
```

but direct inbound internet access to the private instance is prevented.

A public NAT gateway is created in a public subnet, uses an Elastic IP, and
needs a route to an internet gateway. Private-subnet route tables send relevant
IPv4 destinations—often `0.0.0.0/0`—to the NAT gateway. For resilient production
designs, deploy a NAT gateway per Availability Zone and route each private
subnet to the NAT gateway in the same Zone; otherwise an AZ failure can remove
egress and cross-AZ processing can add cost.

---

## VPC Peering

**VPC Peering** creates a networking connection between two VPCs.

It allows traffic to be routed privately between them.

```text
+-------------+             +-------------+
|    VPC A    |-------------|    VPC B    |
| 10.0.0.0/16 | VPC Peering | 10.1.0.0/16 |
+-------------+             +-------------+
```

This can be useful when applications or services located in different
VPCs need private communication.

Peering requires routes and security controls on both sides. VPC peering is not
transitive and does not support overlapping CIDR blocks. A route through one
peered VPC cannot be used as a general transit path to another network.

---

## VPC Endpoints

A **VPC Endpoint** allows your VPC to privately connect to supported AWS
services and VPC endpoint services powered by AWS PrivateLink.

The learning material uses **Amazon S3** as an example.

```text
Private Resource
       |
       v
  VPC Endpoint
       |
       v
    Amazon S3
```

Conceptually, this provides private connectivity to supported AWS
services without requiring the normal public internet path.

- **Gateway endpoints** add route-table targets for Amazon S3 and DynamoDB and
  do not use security groups.
- **Interface endpoints** create private IP-addressed network interfaces
  powered by AWS PrivateLink and use security groups and private DNS options.

Endpoint policies, service resource policies, IAM policies, DNS, route tables,
and security groups can all affect access. An endpoint does not itself grant
permission to the service.

---

## Bastion Host

A **Bastion Host** is a special-purpose instance that provides secure
access to instances located in private subnets.

```text
Administrator
      |
      v
   Internet
      |
      v
+-------------------+
|   Public Subnet   |
|                   |
|   Bastion Host    |
+---------+---------+
          |
          v
+-------------------+
|  Private Subnet   |
|                   |
|   Private EC2     |
+-------------------+
```

Instead of directly exposing a private instance, administrative access
can pass through the Bastion Host.

Prefer AWS Systems Manager Session Manager or EC2 Instance Connect Endpoint
when they meet the requirement, because they can remove the need for a public
bastion and inbound SSH. If a bastion is required, harden and patch it, restrict
inbound access to trusted sources, use short-lived credentials, log sessions,
and avoid using it for general workloads.

---

## Elastic IP Address

An **Elastic IP Address** is a static IP address designed for dynamic
cloud computing.

```text
Elastic IP
    |
    v
AWS Resource
```

Unlike a dynamically changing public address, an Elastic IP provides a
static public IP that can be associated with supported AWS resources.

Public IPv4 addresses are billable resources. Allocate them only when required,
tag them, monitor association state, and release them after confirming they are
no longer referenced.

---

## IPv6 and Egress-Only Internet Gateway

IPv6 addresses are globally routable and are not translated through an IPv4 NAT
gateway. A subnet using IPv6 needs appropriate IPv6 CIDRs, routes, security
groups, and network ACL rules.

An **egress-only internet gateway** allows IPv6 resources to initiate outbound
internet connections while preventing unsolicited internet-initiated
connections through that gateway. It is the common IPv6 counterpart to the
outbound-only behavior often provided by NAT for private IPv4 resources.

---

## VPC Flow Logs

**VPC Flow Logs** capture information about IP traffic going to and from
network interfaces in your VPC.

```text
Network Traffic
      |
      v
Network Interface
      |
      v
VPC Flow Logs
      |
      v
Traffic Information
```

Flow Logs are useful for understanding network communication and
troubleshooting connectivity.

Flow Logs record network-flow metadata, not packet payloads. They can be created
for a VPC, subnet, or network interface and delivered to supported destinations.
Account for aggregation delay, fields not captured, destination permissions,
retention, and ingestion or storage cost.

---

## AWS Direct Connect

**AWS Direct Connect** establishes a dedicated network connection
between your premises and AWS.

```text
Office / Data Center
        |
        |
        | Dedicated Connection
        |
        v
      AWS
        |
        v
       VPC
```

This is useful when an organization needs dedicated connectivity between
its on-premises environment and AWS.

Direct Connect is not internet access and does not encrypt all traffic by
default. Use supported MACsec configurations or an encrypted VPN overlay when
the security requirement calls for encryption in transit. Design redundant
connections and failover paths for production workloads.

---

## Transit Gateway

An **AWS Transit Gateway** acts as a network transit hub.

It can interconnect:

- Multiple VPCs
- On-premises networks

```text
              VPC A
                |
                |
VPC B ------ Transit ------ VPC C
            Gateway
                |
                |
         On-Premises
            Network
```

Instead of creating many separate network connections, Transit Gateway
provides a central networking hub.

Transit Gateway supports transitive routing through centrally managed
attachments and route tables. Plan segmentation, propagation, inspection,
non-overlapping CIDRs, attachment availability, and per-hour and data-processing
costs before replacing simpler point-to-point designs.

---

## AWS Client VPN

**AWS Client VPN** is a managed VPN service that provides secure remote
access to AWS resources and on-premises networks using OpenVPN-based
clients.

```text
Remote User
     |
     v
AWS Client VPN
     |
     +------------------+
     |                  |
     v                  v
AWS Resources      On-Premises
```

This is useful when remote users need secure access to private network
resources.

Client VPN requires authentication, authorization rules, target-network
associations, routes, security groups, DNS, and client CIDR planning. Avoid
overlap between the client address pool and connected networks.

---

## Complete VPC Architecture

Putting the major concepts together:

```text
                           INTERNET
                               |
                               v
                     +------------------+
                     | Internet Gateway |
                     +--------+---------+
                              |
                              |
+------------------------------------------------------------+
|                       AWS VPC                              |
|                     10.0.0.0/16                           |
|                                                            |
|  +----------------------+      +-------------------------+ |
|  |    Public Subnet     |      |     Private Subnet      | |
|  |     10.0.0.0/24      |      |      10.0.1.0/24        | |
|  |                      |      |                         | |
|  |  Web Server          |      |  Application Server     | |
|  |  Bastion Host        |----->|  Database               | |
|  |  NAT Gateway         |      |  Private EC2            | |
|  +----------------------+      +-------------------------+ |
|            |                              |                |
|        Route Table                    Route Table           |
|                                                            |
+------------------------------------------------------------+
```

Security can be applied at different levels:

```text
VPC
 |
 +-- Network ACL
 |      |
 |      v
 |    Subnet
 |      |
 |      v
 | Security Group
 |      |
 |      v
|   Instance
```

The diagram is intentionally simplified. A production design commonly repeats
public and private subnets across at least two Availability Zones, places an
internet-facing load balancer rather than application instances in public
subnets, keeps databases in isolated private subnets, and provides an
Availability Zone-local egress path where required.

---

## Typical Web Application Architecture

A common architecture based on these concepts is:

```text
                        Internet
                           |
                           v
                    Internet Gateway
                           |
                           v
                 +-------------------+
                 |   Public Subnet   |
                 |                   |
                 |   Web / Bastion   |
                 |   NAT Gateway     |
                 +---------+---------+
                           |
                           v
                 +-------------------+
                 |  Private Subnet   |
                 |                   |
                 | Application       |
                 | Database          |
                 +-------------------+
```

This provides a useful separation between internet-facing resources and
internal application resources.

---

## Quick Revision

```text
VPC
 |
 +-- CIDR Block
 |
 +-- Availability Zones
 |
 +-- Subnets
 |     |
 |     +-- Public Subnet
 |     |
 |     +-- Private Subnet
 |
 +-- Route Tables
 |
 +-- Internet Gateway
 |
 +-- NAT Gateway
 |
 +-- Security Groups
 |
 +-- Network ACLs
 |
 +-- VPC Endpoints
 |
 +-- VPC Peering
 |
 +-- Flow Logs
```

Additional connectivity concepts:

```text
Bastion Host   -> Secure access to private instances

Direct Connect -> Dedicated on-premises <-> AWS connection

Transit Gateway -> Central hub connecting VPCs and on-premises networks

Client VPN     -> Secure remote user access
```

---

## Security Group vs Network ACL

| Feature        | Security group                                        | Network ACL                                          |
| -------------- | ----------------------------------------------------- | ---------------------------------------------------- |
| Scope          | Attached to supported network interfaces or resources | Associated with subnets                              |
| State          | Stateful                                              | Stateless                                            |
| Rules          | Allow only                                            | Allow and deny, processed by rule number             |
| Return traffic | Automatically allowed for an established flow         | Must be explicitly allowed                           |
| Typical use    | Primary resource-level traffic control                | Coarse subnet guardrail or explicit deny requirement |

---

## Internet Gateway vs NAT Gateway

```text
PUBLIC RESOURCE

EC2
 |
 v
Internet Gateway
 |
 v
Internet
```

```text
PRIVATE RESOURCE

Private EC2
    |
    v
NAT Gateway
    |
    v
Internet Gateway
    |
    v
Internet
```

Remember:

```text
Internet Gateway
      =
VPC <-> Internet connectivity
```

```text
NAT Gateway
      =
Private subnet -> Internet
without allowing internet-initiated connections
to the private instance
```

An internet gateway does not translate private IPv4 addresses by itself; the
resource needs public addressing. A NAT gateway provides address translation
for initiated IPv4 flows and adds hourly and data-processing charges.

---

## Security and Cost Guidance

- Start with no inbound access and add only required ports and trusted
  sources. Reference security groups between application tiers.
- Prefer private or isolated subnets for application and database workloads
  that do not need direct internet ingress.
- Use VPC endpoints to reduce public-path and NAT dependency where supported,
  while reviewing endpoint hourly and data-processing costs.
- Enable Flow Logs and AWS CloudTrail where audit requirements call for them,
  with explicit retention and least-privilege destinations.
- Review charges for NAT gateways, public IPv4 addresses, interface endpoints,
  Transit Gateway, VPN, Direct Connect, data processing, cross-AZ traffic, and
  logs.
- Do not assume a resource is secure merely because it lacks a public IP;
  review every reachable network path and IAM authorization boundary.

## Troubleshooting

Trace the path in both directions and check the most specific route first:

```text
Source -> security group -> NACL -> route -> gateway or endpoint ->
destination NACL -> destination security group -> listening service
```

- **No internet from a public subnet:** check public addressing, the route to
  the internet gateway, gateway attachment, security group, NACL, and listener.
- **No outbound internet from a private subnet:** check its route to a healthy
  NAT gateway, the NAT subnet's internet-gateway route, Elastic IP, ephemeral
  ports, DNS, and NAT metrics.
- **VPC endpoint fails:** check endpoint type, route-table or subnet selection,
  private DNS, security group, endpoint policy, IAM policy, and service policy.
- **Peering path fails:** check both route tables, security rules, DNS options,
  connection status, and overlapping CIDRs.
- **Intermittent multi-AZ failure:** verify each Zone has the required routes,
  egress, endpoint capacity, and healthy application resources.

Use VPC Reachability Analyzer where supported to identify a blocking component.
Flow Logs show accepted or rejected flow metadata but do not prove that an
application is listening or healthy.

## Cleanup Checklist

1. Terminate or detach instances, load balancers, databases, ECS tasks, and
   other network interfaces created for the lab.
2. Delete interface endpoints, NAT gateways, Client VPN endpoints, peering
   connections, and Transit Gateway attachments after confirming they are not
   shared.
3. Release lab Elastic IP addresses after dependent resources are deleted.
4. Delete custom security groups and network ACLs after references are gone.
5. Delete custom route tables and subnets.
6. Detach and delete the internet gateway, then delete the empty VPC.
7. Remove Flow Log subscriptions, log destinations, alarms, and IAM roles after
   reviewing retention requirements.
8. Confirm that no endpoints, gateways, public IPv4 addresses, VPN resources,
   logs, or data-transfer services remain billable.

---

## Key Takeaways

- **VPC** stands for Virtual Private Cloud.
- A VPC is a logically isolated regional network in AWS.
- A VPC is created within an AWS **Region**.
- Regions contain multiple **Availability Zones**.
- **CIDR blocks** define network IP address ranges.
- **Subnets** divide a VPC into smaller networks.
- Subnets can be designed as **public** or **private**.
- **Route Tables** control where network traffic is directed.
- An **Internet Gateway** provides connectivity between a VPC and the
  internet.
- **Security Groups** control inbound and outbound traffic for
  resources with stateful allow rules.
- **Network ACLs** provide subnet-level traffic filtering with
  ordered, stateless allow and deny rules.
- A **NAT Gateway** lets private subnet resources initiate internet
  connections without allowing internet-initiated connections back to
  those instances.
- **VPC Peering** privately connects two VPCs.
- **VPC Endpoints** provide private connectivity to supported AWS
  services through gateway or interface endpoint models.
- A **Bastion Host** provides secure access to resources in private
  subnets.
- **Elastic IPs** provide static public IP addresses.
- **VPC Flow Logs** capture IP traffic information.
- **Direct Connect** provides dedicated connectivity between
  on-premises infrastructure and AWS.
- **Transit Gateway** acts as a central hub for connecting multiple
  networks.
- **AWS Client VPN** provides secure remote access to AWS and
  on-premises resources.
- IPv6 outbound-only internet access uses an egress-only internet gateway,
  not an IPv4 NAT gateway.

---

## Knowledge Check

1. What route makes an IPv4 subnet public, and what else does an instance need
   for internet connectivity?
2. Why is a route to a NAT gateway placed in a private subnet's route table?
3. How do security groups and network ACLs differ in state and rule behavior?
4. Why should production NAT gateways normally be deployed per Availability
   Zone?
5. How do gateway and interface VPC endpoints differ?
6. Why can VPC peering not serve as a general transitive routing hub?
7. What can Flow Logs tell you, and what can they not tell you?
8. Which network resources can continue generating charges after compute is
   terminated?

## References

- [What is Amazon VPC? — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC and subnet basics — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/configure-your-vpc.html)
- [Connect a VPC to the internet — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
- [NAT gateways — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [Security groups — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html)
- [Network ACLs — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html)
- [VPC endpoints — AWS PrivateLink Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [VPC Flow Logs — Amazon VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

> AWS networking features, quotas, address charges, console labels, and pricing
> can change. Verify production designs against current AWS documentation.

---

## Final Mental Model

```text
                     AWS Region
                         |
                         v
                       VPC
                         |
              +----------+----------+
              |                     |
              v                     v
        Public Subnet         Private Subnet
              |                     |
              |                     |
       Internet Gateway        NAT Gateway
              |                     |
              +----------+----------+
                         |
                    Route Tables
                         |
              Security Controls
                  /          \
                 v            v
        Security Groups    Network ACLs
```

Understanding this architecture provides the networking foundation for
deploying services such as **EC2, RDS, ECS, and other AWS workloads**
securely.
