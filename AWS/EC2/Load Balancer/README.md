# AWS Elastic Load Balancing (ELB) & Auto Scaling Groups (ASG)

[← Back to Amazon EC2](../README.md) · [AWS learning path](../../README.md)

> Learning notes for understanding scalability, high availability,
> elasticity, Elastic Load Balancing, and Auto Scaling Groups in AWS.

## Table of Contents

- [Overview](#overview)
- [Learning Objectives](#learning-objectives)
- [Prerequisites](#prerequisites)
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

---

Scaling Type Meaning Example

---

Vertical Increase resources of Move from `t2.micro` to
an existing server `m5.large`

Horizontal Add more server Add more EC2 instances
instances behind a load balancer

---

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

# Elastic Load Balancing

## What is a Load Balancer?

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

## Why Use a Load Balancer?

### 1. Distributes Traffic

Incoming traffic is distributed across multiple servers so that a single
server does not receive all the workload.

### 2. Improves Availability

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

### 3. Supports Scaling

When additional servers are available during periods of high demand, the
load balancer can distribute traffic across them.

### 4. Provides a Single Access Point

Clients can access the application through the load balancer instead of
needing to know the addresses of individual backend servers.

### 5. Supports High Availability Across AZs

Backend resources can be distributed across multiple Availability Zones.

---

# AWS Load Balancer Types

AWS provides different load balancer types for different workloads.

## Application Load Balancer (ALB)

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

## Network Load Balancer (NLB)

**Network Load Balancer** is designed for high-performance, low-latency
workloads.

It can handle traffic such as:

- TCP
- UDP

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

## Gateway Load Balancer (GWLB)

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

## Load Balancer Comparison

---

Type Layer / Traffic Main Purpose

---

**ALB** Layer 7 --- HTTP/HTTPS Web applications

**NLB** Layer 4 --- TCP/UDP High-performance and
low-latency workloads

**GWLB** Virtual appliance Firewalls and
traffic monitoring appliances

---

---

# Practical: Creating an Application Load Balancer

The learning material describes the following practical workflow.

## Step 1 --- Set Up EC2 Instances

Create two or more EC2 instances.

Install a web server on each instance and tag the instances so they are
easy to identify.

```text
EC2-A ---> Apache
EC2-B ---> Apache
```

## Step 2 --- Configure Security Groups

Configure a security group that allows the required access, including:

- HTTP
- SSH

## Step 3 --- Create the Load Balancer

From the EC2 dashboard:

1.  Create an **Application Load Balancer**.
2.  Configure it as **internet-facing**.

## Step 4 --- Register Targets

Add the EC2 instances to a **target group**.

Configure health checks for the targets.

```text
ALB
 |
 v
Target Group
 |
 +--> EC2-A
 +--> EC2-B
```

## Step 5 --- Test the Load Balancer

Open the load balancer's DNS name.

Requests should be distributed among the registered EC2 instances.

A useful way to observe this is to return the hostname of each EC2
instance from its web page.

---

# EC2 Web Server User Data

The source material uses the following Amazon Linux setup to install
Apache and display the current instance hostname:

```bash
#!/bin/bash

sudo yum update -y

# Install Apache web server
sudo yum install -y httpd

# Start Apache
sudo systemctl start httpd

# Enable Apache on boot
sudo systemctl enable httpd

# Create a page that displays the current server hostname
echo "<html><h1>Welcome to Apache Web Server on Amazon Linux - $(hostname)!</h1></html>" \
  > /var/www/html/index.html
```

If multiple EC2 instances use this setup, refreshing the load balancer
endpoint can help demonstrate which backend instance handled a request.

---

# Auto Scaling Groups

## What is an ASG?

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

# ASG Functions

## 1. Automatic Scaling

Increase or decrease the number of EC2 instances based on demand.

```text
Demand ↑  ---> Instances ↑
Demand ↓  ---> Instances ↓
```

## 2. Maintain Instance Health

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

## 3. Scaling Policies

Scaling rules can be based on metrics such as:

- CPU usage
- Request count

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

## 4. Ensure Availability

The group can maintain a defined number of EC2 instances so that
application capacity remains available.

## 5. Scheduled Scaling

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

## 6. Distribute Instances Across Availability Zones

Instances can be deployed across multiple Availability Zones to improve
high availability.

```text
ASG
 |
 +--> AZ-A ---> EC2
 |
 +--> AZ-B ---> EC2
```

## 7. Integrate with ELB

An Auto Scaling Group can work with an Elastic Load Balancer so that
traffic is distributed among its instances.

## 8. Optimize Costs

During periods of low demand, unnecessary capacity can be removed to
reduce infrastructure costs.

---

# ELB + ASG Together

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

# Steps to Create an ASG

The source material outlines this sequence:

```text
Launch Template / Configuration
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

## 1. Launch Template or Configuration

Define the configuration that will be used when EC2 instances are
launched.

## 2. Create Auto Scaling Group

Create the ASG that will manage the EC2 instances.

## 3. Select VPC and Subnets

Choose where the instances should be deployed.

## 4. Attach Load Balancer --- Optional

Connect the ASG with a load balancer when traffic should be distributed
among the managed instances.

## 5. Configure Scaling Policies

Define the rules that determine when capacity should increase or
decrease.

## 6. Configure Health Checks

Configure health checks so unhealthy capacity can be identified.

## 7. Add Notifications --- Optional

Configure notifications if required.

## 8. Review and Create

Review the configuration and create the Auto Scaling Group.

---

# Quick Revision

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
    +--> Distributes incoming traffic

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
