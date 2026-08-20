# AWS Lambda

[← Back to the AWS learning path](../README.md)

AWS Lambda is a **serverless computing service** that lets you run code
in response to events without managing servers.

You upload your code, configure how it should be triggered, and AWS
handles the underlying infrastructure, execution environments, and scaling.
Billing is usage-based and can include requests, execution duration, configured
resources, and optional Lambda features rather than an idle-server charge.

## Table of Contents

-   [Learning Objectives](#learning-objectives)
-   [Prerequisites](#prerequisites)
-   [What is AWS Lambda?](#what-is-aws-lambda)
-   [How Lambda Works](#how-lambda-works)
-   [Invocation Models](#invocation-models)
-   [When to Use Lambda](#when-to-use-lambda)
-   [Event-Driven Execution](#event-driven-execution)
-   [Automatic Scaling](#automatic-scaling)
-   [Pay-as-You-Go](#pay-as-you-go)
-   [Supported Languages](#supported-languages)
-   [S3 + Lambda Example](#s3--lambda-example)
-   [Permissions](#permissions)
-   [Configuration and Deployment](#configuration-and-deployment)
-   [Reliability and Idempotency](#reliability-and-idempotency)
-   [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
-   [Security and Cost Guidance](#security-and-cost-guidance)
-   [AWS Lambda Limitations](#aws-lambda-limitations)
-   [When to Use Lambda vs
    Alternatives](#when-to-use-lambda-vs-alternatives)
-   [Lambda Architecture Summary](#lambda-architecture-summary)
-   [Key Takeaways](#key-takeaways)
-   [Knowledge Check](#knowledge-check)
-   [Cleanup Checklist](#cleanup-checklist)
-   [References](#references)
-   [Related AWS Services](#related-aws-services)

------------------------------------------------------------------------

## Learning Objectives

After completing this guide, you should be able to:

- Explain functions, handlers, events, execution environments, and triggers.
- Distinguish synchronous, asynchronous, and event-source-mapping invocations.
- Configure an execution role and a resource-based invoke permission.
- Explain concurrency, throttling, retries, duplicate delivery, and idempotency.
- Package and configure a function without embedding credentials or secrets.
- Monitor invocations with logs, metrics, traces, alarms, and failure destinations.
- Decide when Lambda is preferable to containers, virtual machines, or workflows.
- Safely remove a Lambda learning environment and its related resources.

## Prerequisites

Use a sandbox account with billing alerts enabled. You should understand IAM
roles and policies, Amazon S3, CloudWatch, JSON events, and one supported
programming language. Never use production data or long-lived access keys in a
practice function.

------------------------------------------------------------------------

## What is AWS Lambda?

AWS Lambda allows applications to execute code without requiring you to
manage the underlying servers.

Traditional application hosting often looks like:

``` text
Application
    |
    v
Server / VM
    |
    +-- Operating System
    +-- Runtime
    +-- Application
```

With Lambda, the developer focuses primarily on the function:

``` text
Event
  |
  v
AWS Lambda
  |
  v
Your Function
  |
  v
Result
```

AWS manages the infrastructure needed to execute the function.

### Core Idea

``` text
Write Code
    |
    v
Upload / Configure Lambda
    |
    v
Configure Trigger
    |
    v
Event Occurs
    |
    v
Lambda Executes Function
```

This makes Lambda useful for small, independent tasks that should
execute when something happens.

------------------------------------------------------------------------

## How Lambda Works

Lambda is designed around **functions** and **events**.

A simplified workflow is:

``` text
AWS Service / Application
          |
          | Event
          v
+----------------------+
| AWS Lambda Function  |
|                      |
| Your Code            |
+----------+-----------+
           |
           v
     Process Event
           |
           v
   Perform an Action
```

For example, an uploaded file can trigger a Lambda function
automatically:

``` text
User uploads file
       |
       v
Amazon S3
       |
       | Object-created event
       v
AWS Lambda
       |
       v
Process the file
```

No application server needs to continuously wait for the event.

------------------------------------------------------------------------

## Invocation Models

How failures and responses behave depends on how a function is invoked:

| Model | Caller behavior | Common examples | Failure handling |
| --- | --- | --- | --- |
| **Synchronous** | Waits for the function response | API Gateway, function URL, direct SDK call | The caller receives the error and decides whether to retry |
| **Asynchronous** | Lambda queues the event and returns an acceptance response | Amazon S3 and Amazon EventBridge | Lambda retries according to asynchronous settings and can send failures to a destination or dead-letter queue |
| **Event source mapping** | Lambda polls a stream or queue and invokes the function with batches | Amazon SQS, DynamoDB Streams, Kinesis | Retry and checkpoint behavior depends on the source and mapping configuration |

Do not assume every trigger has identical retry, ordering, batching, or
delivery behavior. Read the event source's contract and design the handler to
process repeated events safely.

------------------------------------------------------------------------

## When to Use Lambda

Common Lambda use cases include:

### Image Processing

Suppose users upload images to an application.

A Lambda function can automatically:

-   Resize images
-   Compress images
-   Apply filters
-   Perform other image-processing operations

Architecture:

``` text
User
 |
 | Upload Image
 v
Amazon S3
 |
 | Trigger
 v
AWS Lambda
 |
 +-- Resize
 +-- Compress
 +-- Apply Filter
 |
 v
Processed Image
```

------------------------------------------------------------------------

### Data Transformation

Lambda can process or clean data before it is stored in another system.

Example:

``` text
Incoming Data
     |
     v
AWS Lambda
     |
     +-- Validate
     +-- Clean
     +-- Transform
     |
     v
Database / Storage
```

This is useful when incoming data requires preprocessing.

------------------------------------------------------------------------

### Real-Time Notifications

Lambda can respond to application events such as a new user
registration.

Example:

``` text
New User Signup
       |
       v
     Event
       |
       v
AWS Lambda
       |
       +----------+----------+
       |          |          |
       v          v          v
     Email       SMS      Notification
```

The function runs automatically when the configured event occurs.

------------------------------------------------------------------------

## Event-Driven Execution

AWS Lambda is an **event-driven service**.

This means Lambda functions execute in response to triggers or events
rather than running continuously.

Several AWS services can generate or deliver events:

``` text
Amazon S3
   |
   | File Upload
   v
Lambda

DynamoDB
   |
   | Database Change
   v
Lambda

API Gateway
   |
   | HTTP Request
   v
Lambda

EventBridge
   |
   | Scheduled Event
   v
Lambda
```

### Common Event Sources

| AWS service | Example event |
| --- | --- |
| Amazon S3 | Object created |
| DynamoDB Streams | Item change record |
| Amazon API Gateway | HTTP request |
| Amazon EventBridge | Schedule or matching event |
| Amazon SQS | Queued message batch |

This event-driven model is one of the most important concepts to
understand when learning Lambda.

------------------------------------------------------------------------

## Automatic Scaling

AWS Lambda automatically scales function execution according to incoming
requests.

Conceptually:

``` text
1 Request
    |
    v
Lambda Function
```

When many requests arrive:

``` text
              Incoming Requests
        /       /       \       \
       v       v         v       v
   Lambda   Lambda    Lambda   Lambda
      |        |         |        |
      +--------+---------+--------+
               |
               v
        Parallel Processing
```

Lambda can process many requests in parallel without requiring you to manage
servers, but scaling is not unlimited. **Concurrency** is the number of
in-progress invocations. Regional account quotas, function scaling behavior,
downstream capacity, and reserved-concurrency settings can cause throttling.

-   **Reserved concurrency** guarantees and caps concurrency for one function,
    protecting both the function and the account's shared pool.
-   **Provisioned concurrency** prepares execution environments in advance to
    reduce initialization latency and adds cost.

Set concurrency deliberately so a rapidly scaling function does not overwhelm
a database, API, or other downstream dependency. Request quota increases before
a planned load event and test the complete system, not only Lambda.

This is especially useful for workloads with unpredictable or sporadic
traffic.

------------------------------------------------------------------------

## Pay-as-You-Go

Lambda uses a pay-as-you-go pricing model.

-   Number of function executions
-   Duration of function execution
-   Allocated memory and architecture
-   Additional ephemeral storage when configured above the included amount
-   Provisioned concurrency and other optional features
-   Data transfer and services invoked by the function

The basic idea is:

``` text
Function Not Running
        |
        v
No Idle Compute Charge

Function Running
        |
        v
Compute Usage
        |
        v
Billing
```

This can make Lambda cost-effective for workloads that do not need a
continuously running server.

> AWS pricing can change. Always check current AWS pricing information
> before making billing or architecture decisions.

------------------------------------------------------------------------

## Supported Languages

Common AWS Lambda runtime families include:

-   Node.js (JavaScript)
-   Python
-   Java
-   C# (.NET Core)
-   Ruby
-   Custom Runtime API

Conceptually:

``` text
                  AWS Lambda
                       |
       +---------------+---------------+
       |               |               |
       v               v               v
    Node.js          Python           Java
       |
       +-------------+-------------+
                     |             |
                     v             v
                  C#/.NET        Ruby
                     |
                     v
              Custom Runtime API
```

The Custom Runtime API allows runtimes beyond the directly listed
options to integrate with Lambda.

Runtime versions are retired over time. Choose a currently supported version,
track deprecation dates, patch dependencies, and rebuild deployment artifacts
regularly. Lambda can deploy code as a `.zip` archive or a compatible container
image; a container-image function still runs under the Lambda execution model
and is not a general-purpose continuously running container.

------------------------------------------------------------------------

## S3 + Lambda Example

Consider a practical S3-to-Lambda workflow.

The architecture contains:

-   A source S3 bucket
-   An AWS Lambda function
-   A permissions policy
-   A destination S3 bucket

The function shown in the diagram performs file encryption.

``` text
File Upload
    |
    v
+----------------+
| Source S3      |
| Bucket         |
+-------+--------+
        |
        | Event Trigger
        v
+----------------+
| AWS Lambda     |
|                |
| File Encrypt   |
| Function       |
+-------+--------+
        |
        | Write Result
        v
+----------------+
| Destination S3 |
| Bucket         |
+----------------+
```

The important idea is that uploading a file into the source bucket can
trigger processing automatically.

------------------------------------------------------------------------

### Example Workflow

#### Step 1 - Upload a File

A user or application uploads a file:

``` text
file.txt
   |
   v
Source S3 Bucket
```

#### Step 2 - S3 Generates an Event

The file upload generates an S3 event.

``` text
S3 Object Created
       |
       v
Lambda Trigger
```

#### Step 3 - Lambda Executes

Lambda executes the file-processing function.

``` text
Lambda Function
      |
      v
Encrypt File
```

#### Step 4 - Save the Result

The processed file is written to the destination bucket.

``` text
Encrypted File
      |
      v
Destination S3 Bucket
```

The complete workflow is:

``` text
Upload
  |
  v
Source S3
  |
  v
Lambda
  |
  v
Encrypt
  |
  v
Destination S3
```

Amazon S3 event notifications can be delivered more than once and do not
guarantee global ordering. Make processing idempotent, record completed work
when necessary, and use an object version ID or sequencer when the workflow
depends on object ordering.

Avoid recursive invocation. If the function writes to the same bucket and
prefix that triggers it, each output can create another invocation. Prefer a
separate destination bucket or use carefully tested prefix and suffix filters.

------------------------------------------------------------------------

## Permissions

The S3/Lambda architecture diagram also includes a **permissions
policy**.

Lambda requires appropriate permissions to access other AWS resources.

For the illustrated workflow, the function conceptually needs permission
to:

``` text
Lambda
 |
 +-- Read file from Source S3 Bucket
 |
 +-- Process file
 |
 +-- Write file to Destination S3 Bucket
```

Without the required permissions, the function cannot successfully
interact with the buckets.

A simplified architecture is:

``` text
              IAM Permissions
                    |
                    v
Source S3 ---> AWS Lambda ---> Destination S3
```

Permissions should grant the function only the access required to
perform its task.

Two permission directions are involved:

-   The function's **execution role** grants the function permission to write
    logs and call services such as `s3:GetObject` and `s3:PutObject`.
-   The function's **resource-based policy** grants an event source or another
    principal permission to invoke the function. For an S3 trigger, scope the
    permission to the intended bucket account and bucket ARN.

The execution role does not grant a user permission to update or invoke the
function. Human and deployment identities need separate IAM permissions. Avoid
wildcard actions and resources when specific function, bucket, prefix, log, and
KMS key ARNs can be used.

------------------------------------------------------------------------

## Configuration and Deployment

Review these settings for every function:

-   **Runtime, architecture, and handler:** must match the deployment artifact.
-   **Memory:** also influences available CPU and can change both performance
    and total cost; measure instead of always choosing the smallest value.
-   **Timeout:** should be shorter than the caller or event source timeout and
    leave time for graceful failure handling.
-   **Ephemeral storage:** `/tmp` can be reused by a warm execution environment
    but is not durable or shared state.
-   **Environment variables:** useful for non-secret configuration. Store
    secrets in AWS Secrets Manager or Systems Manager Parameter Store and
    control decryption with IAM and KMS.
-   **Layers or container image:** package shared dependencies carefully and
    scan artifacts for vulnerabilities.
-   **Versions and aliases:** publish immutable versions and move an alias for
    controlled testing, rollback, or weighted deployment.
-   **VPC attachment:** use it only when the function needs VPC resources.
    Plan subnet IP capacity and an egress path or VPC endpoints for required
    services.

Manage repeatable environments with infrastructure as code rather than relying
on console-only configuration. Keep source, dependency locks, templates, and
tests in version control, but exclude secrets and generated credentials.

## Reliability and Idempotency

Retries and duplicate delivery are normal in distributed event-driven systems.
Design a function so processing the same event more than once produces the same
intended result.

-   Derive an idempotency key from a stable event identifier or business key.
-   Store completion state with a conditional write when duplicate side effects
    would be harmful.
-   Configure asynchronous maximum event age, retry attempts, and on-success or
    on-failure destinations.
-   Configure queue visibility timeout, redrive policy, and dead-letter queue
    together with the function timeout and batch behavior.
-   For supported stream and queue mappings, use partial batch failure handling
    so successful records do not needlessly run again.
-   Put explicit timeouts and bounded retries with jitter around downstream
    calls. Reuse SDK clients and connections outside the handler when safe.
-   Use AWS Step Functions when the workflow needs durable orchestration,
    branching, waits, or multi-step compensation.

## Monitoring and Troubleshooting

Monitor at least these CloudWatch metrics where relevant: `Invocations`,
`Errors`, `Duration`, `Throttles`, `ConcurrentExecutions`, `IteratorAge`,
`DeadLetterErrors`, and destination-delivery failures. Configure alarms from
service objectives rather than waiting for user reports.

Write structured logs with request and correlation identifiers, but never log
credentials, authorization headers, secrets, or sensitive event payloads. Use
AWS X-Ray or supported tracing to follow calls across services, and set log
retention explicitly because log groups can outlive the function.

Common checks:

-   **Timeout:** inspect duration, downstream latency, DNS/network access,
    memory allocation, and retry settings.
-   **`AccessDenied`:** check the execution role, resource policy, KMS key
    policy, organization controls, and exact resource ARN.
-   **Throttling:** check account concurrency, reserved concurrency, scaling
    rate, and the caller's retry behavior.
-   **Missing events:** verify the trigger or event source mapping is enabled,
    filters match, source permissions are valid, and failures are not waiting in
    a queue or destination.
-   **Works outside a VPC but fails inside:** inspect route tables, NAT or VPC
    endpoints, security groups, DNS settings, and subnet IP availability.

## Security and Cost Guidance

-   Give each function a narrowly scoped execution role rather than sharing one
    broad role across unrelated functions.
-   Keep runtimes and dependencies supported and patched; scan `.zip`, layer,
    and container artifacts.
-   Validate and bound event input, especially for public APIs and file
    processing.
-   Encrypt sensitive environment variables and data, and restrict KMS key use.
-   Use reserved concurrency as a safety control for downstream systems and
    recursive invocation risk.
-   Tag functions and related resources, configure AWS Budgets, and monitor
    invocation, duration, log-ingestion, provisioned-concurrency, data-transfer,
    and downstream-service costs.
-   Remove unused versions, layers, event mappings, provisioned concurrency,
    log groups, and deployment artifacts after confirming retention needs.

------------------------------------------------------------------------

## AWS Lambda Limitations

Three important Lambda constraints are:

### 1. Execution Time Limit

A Lambda function can run for a maximum of **15 minutes**.

``` text
Lambda Invocation
       |
       | Maximum
       v
   15 Minutes
```

For workloads requiring longer continuous execution, Lambda may not be
the appropriate choice.

------------------------------------------------------------------------

### 2. Stateless Execution

Treat Lambda invocations as stateless. Lambda may reuse an execution environment
and its `/tmp` directory, but reuse is opportunistic and never guaranteed.

You should not design a Lambda function assuming that data stored in
memory during one invocation will always be available during another
invocation.

Think of each invocation as:

``` text
Invocation #1
     |
     v
Execute Function
     |
     v
Finish

Invocation #2
     |
     v
Execute Function Again
```

Persistent state should therefore be stored outside the function when an
application requires it.

------------------------------------------------------------------------

### 3. Cold Start Delays

If a Lambda function has not executed for some time, its next invocation
may experience an initialization delay known as a **cold start**.

``` text
Request
   |
   v
Initialize Environment
   |
   | Cold Start Delay
   v
Execute Function
```

This additional startup latency can matter for latency-sensitive
workloads.

Reduce initialization work, keep deployment packages focused, reuse initialized
clients when safe, and measure latency before enabling cost-bearing mitigations
such as provisioned concurrency. Runtime-specific features may provide other
options.

------------------------------------------------------------------------

## When to Use Lambda vs Alternatives

Compare the workload's execution model and operational needs before choosing
Lambda.

| Use Lambda when... | Consider alternatives when... |
| --- | --- |
| Work is event-driven, short-lived, or has sporadic traffic | A task must run longer than the Lambda timeout |
| Automatic scaling and low infrastructure maintenance are priorities | Sustained compute, specialized hardware, or predictable dedicated capacity is needed |
| Functions can be stateless and independently retried | The process requires durable local state or continuous execution |
| Usage-based pricing fits the traffic pattern | Constant high utilization is more economical on containers or instances |
| The supported runtime and execution environment meet the need | The workload requires privileged access or deep operating-system control |

A simple decision model is:

``` text
Is the workload event-driven?
          |
     +----+----+
     |         |
    Yes        No
     |         |
     v         v
Short task?   Consider
     |        Alternatives
 +---+---+
 |       |
Yes      No
 |       |
 v       v
Lambda   Consider Alternatives
```

------------------------------------------------------------------------

## Lambda Architecture Summary

A typical serverless application can combine several AWS services:

``` text
                    Client
                      |
                      v
                API Gateway
                      |
                      v
                 AWS Lambda
                  /       \
                 /         \
                v           v
           DynamoDB       Amazon S3
```

Another event-driven workflow can be:

``` text
Amazon S3
    |
    v
AWS Lambda
    |
    v
Process File
    |
    v
Amazon S3
```

The central idea remains the same:

> An event occurs, Lambda executes code, and the function performs a
> focused task.

------------------------------------------------------------------------

## Key Takeaways

-   AWS Lambda is a serverless computing service.
-   Lambda lets you execute code without managing servers.
-   Lambda functions are commonly triggered by events.
-   Event sources include S3, DynamoDB Streams, API Gateway, EventBridge,
    and SQS.
-   Common use cases include image processing, data transformation, and
    real-time notifications.
-   Lambda automatically scales function execution based on incoming
    requests.
-   Lambda uses a pay-as-you-go model rather than charging for an idle
    application server.
-   Runtime support changes over time; track deprecations and rebuild
    deployment artifacts regularly.
-   The S3 example uses a source bucket, Lambda encryption function,
    permissions policy, and destination bucket.
-   Lambda functions require appropriate permissions to interact with
    AWS resources.
-   Lambda functions have a maximum execution time of 15 minutes.
-   Lambda functions should be treated as stateless between invocations.
-   Cold starts can introduce additional startup latency.
-   Lambda is particularly suitable for event-driven, short-running,
    automatically scalable workloads.
-   Alternatives should be considered for long-running workloads or
    applications requiring continuous control over compute resources.

------------------------------------------------------------------------

## Knowledge Check

1. How do synchronous, asynchronous, and event-source-mapping invocations
   differ when a function fails?
2. What is the difference between an execution role and a resource-based
   function policy?
3. Why must an S3-triggered function be idempotent?
4. How do reserved concurrency and provisioned concurrency differ?
5. Why is `/tmp` unsuitable for durable application state?
6. Which metrics would help distinguish function errors from throttling?
7. How can writing output to an S3 source bucket create a recursive loop?
8. Which resources can continue generating charges after a function is
   deleted?

## Cleanup Checklist

After a lab, remove resources in dependency-aware order:

1. Disable the trigger or event source mapping so new invocations stop.
2. Inspect queues, failed-event destinations, dead-letter queues, and logs for
   work or evidence that must be retained.
3. Remove provisioned concurrency, aliases, unused versions, and layers.
4. Delete the function after confirming its exact account and Region.
5. Remove the function's execution role and resource permissions only after no
   other workload uses them.
6. Empty and delete lab-only S3 buckets, queues, API Gateway APIs, EventBridge
   rules, log groups, alarms, and deployment artifacts after reviewing
   retention requirements.
7. Confirm in AWS Cost Explorer or the billing dashboard that no unintended
   related resources remain.

## References

- [What is AWS Lambda? — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [Invoking Lambda functions — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html)
- [Lambda permissions — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-permissions.html)
- [Lambda concurrency — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-concurrency.html)
- [Best practices for working with Lambda — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Using Lambda with Amazon S3 — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html)
- [Monitoring Lambda functions — AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/lambda-monitoring.html)

> AWS runtimes, quotas, features, console labels, and pricing can change. Verify
> production designs against the current AWS documentation.

------------------------------------------------------------------------

## Related AWS Services

``` text
Amazon S3
    |
    +----> AWS Lambda <---- API Gateway
              |
              +---- DynamoDB
              |
              +---- CloudWatch
              |
              +---- IAM Permissions
```

Understanding **S3 events, IAM permissions, DynamoDB, API Gateway, and
CloudWatch** helps build a stronger foundation for working with AWS
Lambda.
