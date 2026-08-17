# AWS Elastic Load Balancing (ELB) & Auto Scaling Groups (ASG)

[← Back to Amazon EC2](../README.md) · [AWS learning path](../../README.md)

> Learning notes for understanding scalability, high availability,
> elasticity, Elastic Load Balancing, and Auto Scaling Groups in AWS.

## Table of Contents

- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Scalability](#scalability)
- [Vertical vs Horizontal Scaling](#vertical-vs-horizontal-scaling)
- [High Availability](#high-availability)
- [Elasticity](#elasticity)
- [Elastic Load Balancing](#elastic-load-balancing)
- [Why Use a Load Balancer?](#why-use-a-load-balancer)
- [AWS Load Balancer Types](#aws-load-balancer-types)
- [Practical: Creating an Application Load
  Balancer](#practical-creating-an-application-load-balancer)
- [EC2 Web Server User Data](#ec2-web-server-user-data)
- [Auto Scaling Groups](#auto-scaling-groups)
- [ASG Functions](#asg-functions)
- [ELB + ASG Together](#elb--asg-together)
- [Steps to Create an ASG](#steps-to-create-an-asg)
- [Verification and Troubleshooting](#verification-and-troubleshooting)
- [Security and Cost Guidance](#security-and-cost-guidance)
- [Cleanup](#cleanup)
- [Quick Revision](#quick-revision)
- [Key Takeaway](#key-takeaway)
- [Knowledge Check](#knowledge-check)
- [References](#references)

---

## Learning Objectives

After completing this guide, you should be able to:

- Distinguish scalability, elasticity, and high availability.
- Compare Application, Network, and Gateway Load Balancers.
- Explain listeners, rules, target groups, and health checks.
- Build an internet-facing Application Load Balancer across two Availability Zones.
- Explain desired, minimum, and maximum Auto Scaling Group capacity.
- Combine a launch template, target group, load balancer, and scaling policy.
- Verify the deployment, diagnose common failures, and remove billable resources.

## Prerequisites

Before starting the practical sections, you should understand EC2 instances,
security groups, VPCs, subnets, and launch templates. Use a sandbox account,
configure a billing alert, and have at least two public subnets in different
Availability Zones for the internet-facing Application Load Balancer lab.

---

## Overview

Two important AWS concepts for building scalable and highly available
applications are:

- **ELB --- Elastic Load Balancing**
- **ASG --- Auto Scaling Group**

At a high level:

```text
Users
  |
  v
Elastic Load Balancer
  |
  +----------+----------+
  |          |          |
  v          v          v
 EC2        EC2        EC2
             ^
             |
       Auto Scaling Group
```

The **load balancer** distributes incoming traffic between servers,
while the **Auto Scaling Group** adjusts the number of EC2 instances
according to application demand.

---

## Scalability

**Scalability** is the ability to increase a system's resources when an
application or website receives more traffic or users.

For example, when traffic increases, we can:

1.  Increase the power of the existing server.
2.  Add more servers and distribute traffic between them.

These approaches are called **vertical scaling** and **horizontal
scaling**.

---

## Vertical vs Horizontal Scaling

### Vertical Scalability --- Scaling Up

Vertical scaling means adding more computing power to an existing
server.

Typical resources that can be increased include:

- CPU
- RAM

Example:

```text
t2.micro
    |
    | Scale Up
    v
m5.large
```

The number of servers remains the same, but the existing server becomes
more powerful.

### Horizontal Scalability --- Scaling Out

Horizontal scaling means adding more server instances so the workload
can be distributed across them.

Example:

```text
Before

Users ---> EC2

After scaling out

             +--> EC2
Users ---> LB +--> EC2
             +--> EC2
```

In AWS, multiple EC2 instances can be placed behind a load balancer.

### Comparison

| Scaling type | Meaning | Example |
| --- | --- | --- |
| Vertical | Increase the resources of one server | Move from `t3.micro` to `m7i.large` |
| Horizontal | Add more servers | Add EC2 instances behind a load balancer |

---

## High Availability

**High Availability (HA)** means keeping a service running with minimal
downtime so that it remains accessible to users.

A common AWS approach is to run resources across multiple **Availability
Zones (AZs)**.

```text
                 Load Balancer
                 /           \
                /             \
             AZ-A             AZ-B
              |                 |
             EC2               EC2
```

If resources in one location become unavailable, resources in another
Availability Zone can continue serving the application.

---

## Elasticity

**Elasticity** is the ability to automatically adjust resources as
demand changes.

This means:

```text
Traffic increases
      |
      v
Add resources

Traffic decreases
      |
      v
Remove unnecessary resources
```

An **Auto Scaling Group (ASG)** is an example of elasticity because it
can add EC2 instances when more capacity is required and remove them
when demand decreases.

### Scalability vs Elasticity

```text
Scalability
    |
    +--> Ability to handle growth by increasing resources

Elasticity
    |
    +--> Automatically adjusts resources as demand changes
```

---

## Elastic Load Balancing

### What is a Load Balancer?

A load balancer sits between users and backend servers and distributes
incoming requests across multiple servers.

```text
 User A ----\
 User B -----+----> Load Balancer ----> EC2 A
 User C ----/            |-----------> EC2 B
                         |-----------> EC2 C
```

Instead of users directly accessing individual application servers, they
access the load balancer.

The load balancer then decides which backend server should receive each
request.

---

### Why Use a Load Balancer?

#### 1. Distributes Traffic

Incoming traffic is distributed across multiple servers so that a single
server does not receive all the workload.

#### 2. Improves Availability

If one server becomes unavailable, traffic can be sent to the remaining
working servers.

```text
              Load Balancer
              /     |     \
             /      |      \
           EC2     EC2     EC2
            OK     DOWN     OK
             ^               ^
             +---- Traffic --+
```

#### 3. Supports Scaling

When additional servers are available during periods of high demand, the
load balancer can distribute traffic across them.

#### 4. Provides a Single Access Point

Clients can access the application through the load balancer instead of
needing to know the addresses of individual backend servers.

#### 5. Supports High Availability Across AZs

Backend resources can be distributed across multiple Availability Zones.

---

## AWS Load Balancer Types

AWS provides different load balancer types for different workloads.

### Application Load Balancer (ALB)

**Application Load Balancer** is designed for web applications and
handles:

- HTTP
- HTTPS

It operates at **Layer 7 --- Application Layer**.

```text
HTTP/HTTPS
    |
    v
   ALB
    |
    +--> Web Application
```

Typical use:

```text
Web applications
APIs
HTTP/HTTPS traffic
```

---

### Network Load Balancer (NLB)

**Network Load Balancer** is designed for high-performance, low-latency
workloads.

It can handle traffic such as:

- TCP
- UDP
- TLS

It operates at **Layer 4 --- Transport Layer**.

Example workloads mentioned in the learning material include:

- Gaming applications
- Financial applications

```text
TCP / UDP
    |
    v
   NLB
    |
    +--> Backend Services
```

---

### Gateway Load Balancer (GWLB)

**Gateway Load Balancer** is used to deploy, scale, and manage
third-party virtual network appliances.

Examples include:

- Firewalls
- Monitoring solutions

```text
Traffic
   |
   v
 GWLB
   |
   v
Virtual Appliance
(Firewall / Monitoring)
```

---

### Load Balancer Comparison

| Type | Layer or traffic | Primary use |
| --- | --- | --- |
| **ALB** | Layer 7: HTTP and HTTPS | Web applications, APIs, and content-based routing |
| **NLB** | Layer 4: TCP, UDP, and TLS | High-performance, low-latency connections and static IP requirements |
| **GWLB** | Layer 3 gateway with GENEVE | Inserting and scaling virtual network appliances |

---

## Practical: Creating an Application Load Balancer

The learning material describes the following practical workflow.

### Step 1 --- Set Up EC2 Instances

Create two or more EC2 instances.

Install a web server on each instance and tag the instances so they are
easy to identify.

```text
EC2-A ---> Apache
EC2-B ---> Apache
```

### Step 2 --- Configure Security Groups

Use separate security groups for the load balancer and targets:

- **ALB security group:** allow inbound HTTP `80` from `0.0.0.0/0` and
  `::/0` for this public lab. Use HTTPS `443` and a certificate for real
  applications.
- **EC2 security group:** allow inbound HTTP `80` only from the ALB security
  group. Do not expose the instances directly to the internet.
- For administration, prefer Systems Manager Session Manager. If SSH is
  required, restrict port `22` to your current public IP address.

### Step 3 --- Create the Target Group

1. Create an instance target group using HTTP port `80`.
2. Set the health-check path to `/`.
3. Register both instances.
4. Wait for both targets to become healthy before testing traffic.

### Step 4 --- Create the Load Balancer

From the EC2 dashboard:

1.  Create an **Application Load Balancer**.
2.  Configure it as **internet-facing**.
3.  Select the VPC and at least two public subnets in different Availability
    Zones.
4.  Attach the ALB security group.
5.  Create an HTTP listener on port `80` that forwards to the target group.

### Step 5 --- Understand the Request Path

```text
Client -> ALB listener -> Listener rule -> Target group -> Healthy EC2 target
```

The listener accepts connections on a configured protocol and port. Its rules
evaluate each request and forward matching traffic to a target group. The load
balancer sends traffic only to targets that pass health checks.

### Step 6 --- Test the Load Balancer

Open the load balancer's DNS name.

Requests should be distributed among the registered EC2 instances.

A useful way to observe this is to return the hostname of each EC2 instance
from its web page and make several separate requests. Browser connection reuse
and routing behavior mean that refreshing is not guaranteed to alternate
between targets.

---

## EC2 Web Server User Data

The source material uses the following Amazon Linux setup to install
Apache and display the current instance hostname:

```bash
#!/bin/bash
set -euo pipefail

dnf install -y httpd
systemctl enable --now httpd

# Create a page that displays the current server hostname
echo "<html><h1>Served by $(hostname)</h1></html>" \
  > /var/www/html/index.html
```

This example targets Amazon Linux 2023. EC2 user data runs as `root`, so
`sudo` is unnecessary. Review `/var/log/cloud-init-output.log` if the package
installation or web-server startup fails.

If multiple EC2 instances use this setup, refreshing the load balancer
endpoint can help demonstrate which backend instance handled a request.

---

## Auto Scaling Groups

### What is an ASG?

An **AWS Auto Scaling Group (ASG)** automatically adds or removes EC2
instances based on demand.

Its purpose is to keep an appropriate number of instances running for
the application's current needs.

```text
Low Traffic

ASG
 |
 +--> EC2


High Traffic

ASG
 |
 +--> EC2
 +--> EC2
 +--> EC2
```

When more capacity is required, the group can scale up.

When demand becomes lower, the group can scale down to reduce
infrastructure costs.

---

## ASG Functions

### 1. Automatic Scaling

Increase or decrease the number of EC2 instances based on demand.

```text
Demand ↑  ---> Instances ↑
Demand ↓  ---> Instances ↓
```

### 2. Maintain Instance Health

An ASG can replace unhealthy instances to maintain reliability.

```text
EC2 becomes unhealthy
        |
        v
ASG replaces instance
        |
        v
New healthy EC2
```

### 3. Scaling Policies

Scaling rules can be based on metrics such as:

- CPU usage
- Application Load Balancer request count per target

Conceptually:

```text
Metric changes
      |
      v
Scaling Policy
      |
      v
Scale Out / Scale In
```

Common policy types include target tracking, step scaling, and simple scaling.
Target tracking is often the easiest starting point: choose a metric and target
value, and EC2 Auto Scaling adjusts capacity toward that target.

### 4. Ensure Availability

The group can maintain a defined number of EC2 instances so that
application capacity remains available.

An ASG has three important capacity settings:

- **Minimum capacity:** the lowest number of instances the group may retain.
- **Desired capacity:** the number the group currently attempts to run.
- **Maximum capacity:** the highest number scaling policies may request.

### 5. Scheduled Scaling

Scaling activities can be configured for known periods of increased or
reduced traffic.

Example:

```text
Known traffic peak
      |
      v
Scheduled Scaling
      |
      v
Increase capacity
```

### 6. Distribute Instances Across Availability Zones

Instances can be deployed across multiple Availability Zones to improve
high availability.

```text
ASG
 |
 +--> AZ-A ---> EC2
 |
 +--> AZ-B ---> EC2
```

### 7. Integrate with ELB

An Auto Scaling Group can work with Elastic Load Balancing so that
traffic is distributed among its instances.

When the ASG is attached to a target group, new instances are registered and
terminating instances are deregistered automatically. Enable Elastic Load
Balancing health checks when target health should influence instance
replacement; EC2 health checks alone do not evaluate the application endpoint.

### 8. Optimize Costs

During periods of low demand, unnecessary capacity can be removed to
reduce infrastructure costs.

---

## ELB + ASG Together

ELB and ASG solve related but different problems.

```text
                        +-------------------+
                        | Auto Scaling Group|
                        +---------+---------+
                                  |
                    manages EC2 capacity
                                  |
                                  v
Users ---> ELB ---> +-------------------------+
                    | EC2 | EC2 | EC2 | ...  |
                    +-------------------------+
```

### ELB Responsibility

```text
Where should the incoming request go?
```

The load balancer distributes traffic among available backend instances.

### ASG Responsibility

```text
How many EC2 instances should be running?
```

The Auto Scaling Group manages instance capacity according to demand,
health, policies, and configured requirements.

### Combined Flow

```text
1. Users send requests
        |
        v
2. ELB receives traffic
        |
        v
3. ELB distributes requests to EC2 instances
        |
        v
4. Demand changes
        |
        v
5. ASG adjusts EC2 capacity
```

Together they support:

- Scalability
- Elasticity
- High availability
- Better resource utilization
- Cost optimization

---

## Steps to Create an ASG

The source material outlines this sequence:

```text
Launch Template
            |
            v
Create Auto Scaling Group
            |
            v
Select VPC and Subnets
            |
            v
Attach Load Balancer (Optional)
            |
            v
Configure Scaling Policies
            |
            v
Configure Health Checks
            |
            v
Add Notifications (Optional)
            |
            v
Review and Create
```

### 1. Create a Launch Template

Define the configuration that will be used when EC2 instances are
launched, including the AMI, instance type, security group, IAM instance
profile, storage, and user data. Use a launch template for new deployments.

### 2. Create Auto Scaling Group

Create the ASG that will manage the EC2 instances.

### 3. Select VPC and Subnets

Choose where the instances should be deployed.

### 4. Attach Load Balancer --- Optional

Connect the ASG with a load balancer when traffic should be distributed
among the managed instances.

For this lab, attach the existing target group and enable Elastic Load
Balancing health checks. The ALB itself is connected through the target group,
not selected as an individual backend server.

### 5. Configure Capacity and Scaling Policies

Set minimum, desired, and maximum capacity, then define the policy that
determines when capacity should increase or decrease. Allow for instance warmup
so a new instance can boot and begin serving traffic before its metrics affect
another scaling decision.

### 6. Configure Health Checks

Configure health checks so unhealthy capacity can be identified.

### 7. Add Notifications --- Optional

Configure notifications if required.

### 8. Review and Create

Review the configuration and create the Auto Scaling Group.

---

## Verification and Troubleshooting

Use the load balancer DNS name rather than an individual instance address:

```bash
for request in {1..10}; do
  curl --silent "http://ALB_DNS_NAME/"
  echo
done
```

Confirm the following before generating load for a scaling test:

- The ALB is active and its listener forwards to the expected target group.
- Targets report `healthy` in every enabled Availability Zone.
- The ASG has reached its desired capacity and instances show `InService`.
- The web page returns through the ALB DNS name.
- CloudWatch displays the metric used by the scaling policy.

If targets remain unhealthy, check:

- The EC2 security group permits the application port from the ALB security
  group.
- The target group uses the correct protocol, port, health-check path, and
  success code.
- Apache is running with `systemctl status httpd`.
- User data completed successfully in `/var/log/cloud-init-output.log`.
- The application listens on the target port and returns a successful response.
- Network ACLs and route tables allow traffic between the ALB nodes and targets.

If the ALB cannot be reached, verify that it is internet-facing, spans public
subnets whose route tables lead to an internet gateway, and allows the listener
port in its security group. DNS provisioning can also take a short time after
creation.

## Security and Cost Guidance

- Terminate TLS on an HTTPS listener with an AWS Certificate Manager
  certificate for real applications, and redirect HTTP to HTTPS when suitable.
- Allow the target port only from the load balancer security group.
- Place application instances in private subnets when they do not require
  direct inbound internet access.
- Attach an IAM role to instances instead of storing access keys in user data or
  an AMI.
- Protect public applications with appropriate authentication, logging, and
  AWS WAF controls where required.
- Review access logs and CloudWatch metrics, and configure alarms for unhealthy
  targets and unexpected capacity changes.
- Load balancers, EC2 instances, public IPv4 addresses, NAT gateways, and data
  processing can incur charges. Consult current AWS pricing before the lab.
- Set conservative minimum and maximum ASG capacity so a faulty policy cannot
  grow without a limit.

## Cleanup

Delete lab resources after verification to prevent ongoing charges:

1. Set the ASG desired and minimum capacity to `0` if you want to observe a
   controlled scale-in, then delete the ASG.
2. Delete the load balancer.
3. Delete the target group after the load balancer no longer references it.
4. Delete the launch template and any manually created EC2 instances.
5. Delete lab security groups after their network interfaces and references are
   gone.
6. Review CloudWatch alarms, snapshots, public IPv4 addresses, NAT gateways,
   and other resources created for the exercise.
7. Confirm in the EC2 console and billing dashboard that no unintended
   resources remain.

---

## Quick Revision

```text
Scalability
    |
    +--> Ability to increase resources

Vertical Scaling
    |
    +--> Make one server more powerful

Horizontal Scaling
    |
    +--> Add more servers

High Availability
    |
    +--> Keep the application available with minimal downtime
    +--> Example: resources across multiple AZs

Elasticity
    |
    +--> Automatically add/remove resources as demand changes

ELB
    |
    +--> Elastic Load Balancing distributes incoming traffic

ALB
    |
    +--> HTTP/HTTPS
    +--> Layer 7

NLB
    |
    +--> TCP/UDP
    +--> Layer 4
    +--> High performance / low latency

GWLB
    |
    +--> Third-party virtual appliances
    +--> Firewalls / monitoring

ASG
    |
    +--> Automatically manages EC2 instance capacity
    +--> Replaces unhealthy instances
    +--> Uses scaling policies
    +--> Supports scheduled scaling
    +--> Can span multiple AZs
    +--> Can integrate with ELB
```

---

## Key Takeaway

Think of the relationship this way:

```text
ELB = Distribute the traffic
ASG = Manage the number of servers
```

When used together, ELB and ASG provide a foundation for building
scalable, elastic, and highly available EC2-based applications.

## Knowledge Check

1. How do scalability, elasticity, and high availability differ?
2. When would you choose an ALB instead of an NLB?
3. What roles do a listener, listener rule, target group, and health check play?
4. Why should the EC2 security group accept HTTP from the ALB security group
   instead of from `0.0.0.0/0`?
5. What happens when desired capacity is below the ASG minimum or above its
   maximum?
6. Why might an instance pass an EC2 health check but fail an ELB health check?
7. Which scaling policy would you start with to maintain a target average CPU
   utilization?
8. Which resources can continue generating charges after the instances are
   terminated?

## References

- [What is Elastic Load Balancing? — AWS Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)
- [Get started with an Application Load Balancer — AWS Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/getting-started.html)
- [What is Amazon EC2 Auto Scaling? — AWS Documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)
- [Target tracking scaling policies — AWS Documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-scaling-target-tracking.html)

> AWS features, console labels, quotas, supported protocols, and pricing can
> change. Verify production designs against the current AWS documentation.
