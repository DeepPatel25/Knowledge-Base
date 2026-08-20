# Amazon ECS (Elastic Container Service)

[← Back to the AWS learning path](../README.md)

Amazon ECS (**Elastic Container Service**) is a managed container
orchestration service used to deploy, run, scale, and monitor applications from
container images.

------------------------------------------------------------------------

## Table of Contents

-   [Learning Objectives](#learning-objectives)
-   [Prerequisites](#prerequisites)
-   [What is AWS ECS?](#what-is-aws-ecs)
-   [Why ECS?](#why-ecs)
-   [Core ECS Terms](#core-ecs-terms)
-   [ECS Architecture](#ecs-architecture)
-   [AWS Fargate](#aws-fargate)
-   [How the Components Fit Together](#how-the-components-fit-together)
-   [Simple Deployment Flow](#simple-deployment-flow)
-   [IAM Roles and Secrets](#iam-roles-and-secrets)
-   [Networking and Load Balancing](#networking-and-load-balancing)
-   [Deployments, Scaling, and Observability](#deployments-scaling-and-observability)
-   [Security and Cost Guidance](#security-and-cost-guidance)
-   [Troubleshooting](#troubleshooting)
-   [Cleanup Checklist](#cleanup-checklist)
-   [ECS vs Manual Container Management](#ecs-vs-manual-container-management)
-   [Quick Revision](#quick-revision)
-   [Key Takeaways](#key-takeaways)
-   [Knowledge Check](#knowledge-check)
-   [References](#references)
-   [Related Concepts to Learn Next](#related-concepts-to-learn-next)

------------------------------------------------------------------------

## Learning Objectives

After completing this guide, you should be able to:

- Explain clusters, task definitions, tasks, services, and containers.
- Compare AWS Fargate with the EC2 capacity-provider model.
- Distinguish the task execution role from the application task role.
- Configure task networking, security groups, service load balancing, and logs.
- Explain desired count, health replacement, deployment, and service scaling.
- Diagnose stopped tasks and safely remove an ECS learning environment.

## Prerequisites

Use a sandbox account with billing alerts enabled. You should understand Docker
images, Amazon ECR, IAM roles, VPC subnets and security groups, load balancers,
CloudWatch Logs, and basic application health checks. Do not place credentials
or plaintext secrets in images or task definitions.

------------------------------------------------------------------------

## What is AWS ECS?

ECS schedules containerized workloads onto AWS Fargate, ECS container
instances backed by EC2, or supported external capacity. ECS orchestrates
containers; it does not build application images for you.

``` text
Application
    |
    v
Docker Container
    |
    v
AWS ECS
    |
    v
Managed Container Workload
```

ECS provides a structured way to organize and manage containerized
applications.

------------------------------------------------------------------------

## Why ECS?

ECS coordinates container-management operations such as:

-   **Creation**
-   **Management**
-   **Updating**

``` text
                 AWS ECS
                    |
       +------------+------------+
       |            |            |
       v            v            v
   Creation     Management     Updating
       |            |            |
       +------------+------------+
                    |
                    v
             Docker Containers
```

------------------------------------------------------------------------

## Core ECS Terms

### 1. Cluster

A **cluster** is a logical grouping for ECS tasks, services, and capacity
providers. A Fargate-only cluster does not require you to manage EC2 container
instances.

``` text
ECS Cluster
    |
    +-- Services
    +-- Tasks
    +-- Resources / Infrastructure
```

The cluster is the high-level logical environment for ECS workloads.

### 2. Service

An **ECS service** maintains a desired number of tasks, replaces unhealthy or
stopped tasks, and coordinates deployments. It can integrate with Elastic Load
Balancing, service discovery, and Application Auto Scaling.

``` text
ECS Service
    |
    +-- Task
    +-- Task
    +-- Task
```

The service manages the application workload inside the ECS cluster.

### 3. Task

A **task** is one running copy of a task definition and can contain one or more
cooperating containers.

``` text
Task Definition
      |
      v
     Task
      |
      v
Running Container
```

### 4. Task Definition

A **task definition** is a versioned JSON blueprint. It defines container
images, CPU and memory, port mappings, environment configuration, secrets,
volumes, logging, health checks, network mode, and IAM roles. Registering a
change creates a new revision; existing tasks do not change until replaced.

A useful distinction is:

``` text
Task Definition = workload definition/configuration

Task            = running workload
```

------------------------------------------------------------------------

## ECS Architecture

The provided architecture diagram shows the ECS components in this
hierarchy:

``` text
+--------------------------------------------------+
|                      ECS                         |
|                                                  |
|  +--------------------------------------------+  |
|  |          ECS Cluster (Fargate)             |  |
|  |                                            |  |
|  |   +------------------------------------+   |  |
|  |   |            ECS Service             |   |  |
|  |   |                                    |   |  |
|  |   |  +------------------------------+  |   |  |
|  |   |  |      ECS Task Definition     |  |   |  |
|  |   |  |                              |  |   |  |
|  |   |  |         Container            |  |   |  |
|  |   |  +------------------------------+  |   |  |
|  |   +------------------------------------+   |  |
|  +--------------------------------------------+  |
+--------------------------------------------------+
```

The main mental model is:

``` text
ECS
 |
 v
Cluster
 |
 v
Service
 |
 v
Task Definition
 |
 v
Container Workload
```

------------------------------------------------------------------------

## AWS Fargate

**AWS Fargate** provides serverless compute capacity for ECS tasks. You choose
task CPU, memory, platform, networking, and count while AWS manages the
underlying hosts.

``` text
ECS Cluster (Fargate)
```

Within the supplied screenshots, Fargate is the execution model used for
the ECS container workload.

``` text
AWS ECS
   |
   v
ECS Cluster (Fargate)
   |
   v
ECS Service
   |
   v
Task Definition
   |
   v
Container
```

Fargate tasks use `awsvpc` networking and receive elastic network interfaces in
the selected subnets. A task in a public subnet still needs public addressing
and a route to an internet gateway for direct internet connectivity. A task in
a private subnet normally uses a NAT gateway or VPC endpoints for required
outbound services such as ECR, S3, CloudWatch Logs, and Secrets Manager.

With the **EC2 capacity-provider** model, you manage EC2 container instances,
their AMIs, patching, scaling, and available cluster resources. This provides
more host control and can suit specialized or steady workloads, but increases
operational responsibility.

------------------------------------------------------------------------

## How the Components Fit Together

The easiest way to remember the concepts is:

``` text
Cluster
   |
   | contains
   v
Service
   |
   | manages
   v
Tasks
   |
   | run according to
   v
Task Definition
   |
   | describes
   v
Container Workload
```

| ECS component | Purpose |
| --- | --- |
| **Cluster** | Logically groups tasks, services, and capacity providers |
| **Service** | Maintains desired tasks and coordinates health and deployments |
| **Task definition** | Versioned configuration for the workload |
| **Task** | Running copy of a task definition |
| **Container** | Application or supporting process within a task |
| **Fargate** | AWS-managed serverless compute capacity for tasks |
| **Capacity provider** | Connects a service or cluster to Fargate or managed EC2 capacity |

------------------------------------------------------------------------

## Simple Deployment Flow

The introductory concepts can be remembered with this logical flow:

``` text
Docker Application
       |
       v
Task Definition
       |
       v
ECS Cluster
       |
       v
ECS Service
       |
       v
Task
       |
       v
Running Container
```

A practical deployment normally follows this sequence:

1. Build and test the container image.
2. Scan it and push an immutable version tag or digest to Amazon ECR.
3. Register a task-definition revision referencing that image.
4. Create or update an ECS service in selected subnets and security groups.
5. Wait for tasks and load-balancer targets to become healthy.
6. Verify logs, metrics, application behavior, and rollback settings.
7. Shift traffic only after the new deployment passes validation.

------------------------------------------------------------------------

## IAM Roles and Secrets

ECS commonly uses two different roles:

-   **Task execution role:** used by the ECS and Fargate agents for actions such
    as pulling a private ECR image, retrieving referenced secrets, and sending
    logs using the configured log driver.
-   **Task role:** credentials delivered to application containers so the code
    can call AWS APIs such as DynamoDB or S3.

Do not grant application data permissions to the execution role or place access
keys in an image, environment file, or task definition. Give each workload a
narrow task role. Reference secrets from AWS Secrets Manager or Systems Manager
Parameter Store and grant only the required secret and KMS permissions.

## Networking and Load Balancing

For a typical internet-facing service:

``` text
Internet
   |
Application Load Balancer in public subnets
   |
ECS service tasks in private subnets
   |
Database or AWS services
```

-   Allow the application port on the task security group only from the load
    balancer security group.
-   Use at least two Availability Zones for a production service when the
    workload supports it.
-   Configure the target-group health path and container health check to reflect
    real application readiness.
-   Use Cloud Map or ECS Service Connect for suitable service-to-service
    discovery and connectivity patterns.
-   Plan subnet IP capacity because each Fargate task consumes an address.

## Deployments, Scaling, and Observability

An ECS service replaces tasks during a deployment according to its deployment
configuration and health signals. Configure a deployment circuit breaker with
rollback, or another supported deployment strategy, so a failed revision does
not remain partially deployed.

Service auto scaling adjusts desired task count using target tracking, step, or
scheduled policies. Scaling tasks does not guarantee a healthy system: ensure
load balancers, databases, queues, quotas, and subnet IP capacity can support
the new count.

Send container output to CloudWatch Logs with the `awslogs` driver or another
approved destination. Monitor service desired versus running task count, stopped
task reasons, deployment status, CPU, memory, load-balancer health, application
latency, and error rates. Enable Container Insights when its added telemetry and
cost are justified.

## Security and Cost Guidance

-   Use minimal, regularly patched base images and scan images in CI and ECR.
-   Run as a non-root user, use a read-only root filesystem when possible, and
    drop unnecessary Linux capabilities.
-   Never expose the Docker socket or privileged host access to a container.
-   Scope task and execution roles separately and rotate referenced secrets.
-   Restrict inbound and outbound security-group rules and use TLS for traffic.
-   Choose task CPU and memory from measurements. Review Fargate runtime,
    ephemeral storage, public IPv4, NAT gateway, load balancer, logs, ECR, and
    data-transfer charges.
-   Use Savings Plans or Fargate Spot only when their commitment or interruption
    behavior fits the workload.

## Troubleshooting

-   **Task stops before running:** inspect the stopped reason, ECR image and
    architecture, execution-role permissions, secrets, log configuration, CPU
    and memory combination, and subnet egress.
-   **Task runs but is unreachable:** verify port mappings, bind address,
    security groups, routes, load-balancer listener and target group, and health
    check path.
-   **Application receives `AccessDenied`:** check the task role rather than the
    execution role, along with resource policies and KMS permissions.
-   **Deployment never stabilizes:** inspect events, target health, container
    health, startup time, desired count, deployment percentages, and available
    IP addresses or EC2 capacity.
-   **Logs are missing:** check the log driver, log group and Region, execution
    role, network path to CloudWatch Logs, and whether the process writes to
    standard output or standard error.

## Cleanup Checklist

1. Scale the service to zero if you need to observe controlled task shutdown.
2. Delete the ECS service and wait for its tasks to stop.
3. Stop any standalone tasks.
4. Delete lab-only load balancers, listeners, target groups, service discovery,
   and auto-scaling policies after checking dependencies.
5. Deregister obsolete task-definition revisions and delete unused ECR images
   only after confirming no rollback or deployment needs them.
6. Delete lab-only log groups, secrets, IAM roles and policies, security groups,
   and the empty cluster.
7. Review NAT gateways, public IPv4 addresses, EC2 capacity, EBS volumes, and
   other resources that can continue generating charges.

------------------------------------------------------------------------

## ECS vs Manual Container Management

The lesson motivates ECS through container lifecycle management.

``` text
Manual Container Management
        |
        +-- Creation
        +-- Management
        +-- Updating
```

With ECS:

``` text
Developer
    |
    v
AWS ECS
    |
    +-- Creation
    +-- Management
    +-- Updating
    |
    v
Container Workloads
```

------------------------------------------------------------------------

## Quick Revision

``` text
ECS = Elastic Container Service
```

Remember:

``` text
Cluster
  └── Service
       └── Task
            └── Container
```

The configuration for the running task is represented by:

``` text
Task Definition
      |
      v
Task
      |
      v
Container
```

The service references a task-definition revision and launches tasks from it:

``` text
Cluster
  └── Service ──references──> Task Definition revision
       ├── Task
       │    └── Container
       └── Task
            └── Container
```

------------------------------------------------------------------------

## Key Takeaways

-   **Amazon ECS** stands for Elastic Container Service.
-   ECS is used to run and manage Docker container workloads.
-   ECS orchestrates container deployment, health, scaling, and updating; image
    builds remain part of the delivery workflow.
-   A **cluster** logically groups tasks, services, and capacity providers.
-   An **ECS service** maintains desired tasks, health, deployments, and
    optional load-balancer integration.
-   A **Task Definition** defines the container workload.
-   A **Task** represents a running container workload.
-   Fargate provides AWS-managed serverless task capacity; ECS can also use
    managed EC2 or supported external capacity.
-   The main hierarchy to remember is:

``` text
ECS
 ↓
Cluster
 ↓
Service ──references──> Task Definition
 ↓
Tasks
 ↓
Containers
```

------------------------------------------------------------------------

## Knowledge Check

1. How does a task definition differ from a running task?
2. What additional responsibilities come with ECS on EC2 instead of Fargate?
3. Why must task and execution roles be separate?
4. Why might a Fargate task in a private subnet fail to pull an ECR image?
5. What does an ECS service do when a task becomes unhealthy?
6. Which signals should stop or roll back a deployment?
7. Why can task auto scaling overload a downstream database?
8. Which resources can incur charges after an ECS service is deleted?

## References

- [What is Amazon ECS? — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)
- [Amazon ECS task definitions — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
- [AWS Fargate for Amazon ECS — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Amazon ECS task IAM role — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
- [Amazon ECS task execution IAM role — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
- [Security best practices for Amazon ECS — Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-tasks-containers.html)

> AWS capabilities, platform versions, quotas, console labels, and pricing can
> change. Verify production designs against current AWS documentation.

------------------------------------------------------------------------

## Related Concepts to Learn Next

``` text
Docker
   ↓
Container Image
   ↓
Task Definition
   ↓
ECS Service in a Cluster
   ↓
Tasks
```

Continue with Amazon ECR, Application Load Balancers, Service Connect,
CloudWatch Container Insights, deployment pipelines, and infrastructure as code.
