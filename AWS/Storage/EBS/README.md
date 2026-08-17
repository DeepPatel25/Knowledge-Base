# Amazon Elastic Block Store (EBS)

Amazon Elastic Block Store (EBS) provides persistent block storage for Amazon EC2 instances. An EBS volume works like a virtual disk that can store operating-system files, application data, databases, logs, and other persistent data.

## Learning objectives

After completing this topic, you should be able to:

- Explain EBS volumes and their relationship with EC2.
- Choose a suitable EBS volume type.
- Create, attach, format, and mount an EBS volume.
- Resize an EBS volume and filesystem.
- Understand delete-on-termination behavior.
- Create and restore EBS snapshots.
- Move EBS data across Availability Zones and Regions.
- Understand EBS encryption and snapshot lifecycle management.

## Core concepts

### Persistent block storage

EBS volumes provide block-level storage for EC2.

Unlike instance-store storage, EBS data normally remains available when an EBS-backed EC2 instance is stopped or restarted.

Typical workloads include:

- EC2 root volumes
- MySQL and PostgreSQL databases
- Application data
- Logs
- Docker data
- Persistent file systems

### Availability Zone scope

An EBS volume is created inside one Availability Zone.

A normal EBS volume can be attached only to an EC2 instance in the same Availability Zone.

```text
EC2 instance:  ap-south-1a
EBS volume:    ap-south-1a
Result:        Can attach

EC2 instance:  ap-south-1b
EBS volume:    ap-south-1a
Result:        Cannot attach directly
```

To move the data to another Availability Zone, create a snapshot and then create a new volume from that snapshot in the destination AZ.

## EBS volume types

| Type | Storage | Typical use |
|---|---|---|
| `gp3` | General Purpose SSD | Most applications, boot volumes, development, databases |
| `gp2` | General Purpose SSD | Older general-purpose workloads |
| `io2` | Provisioned IOPS SSD | I/O-intensive and business-critical databases |
| `io1` | Provisioned IOPS SSD | Older provisioned-IOPS workloads |
| `st1` | Throughput Optimized HDD | Large sequential workloads, logs, analytics |
| `sc1` | Cold HDD | Infrequently accessed data |

For most new general-purpose workloads, `gp3` is a good starting point.

`st1` and `sc1` cannot be used as boot volumes.

## Important EBS points

- EBS volumes are Availability-Zone specific.
- EBS provides built-in redundancy within an Availability Zone.
- EBS volumes can be encrypted using AWS KMS.
- EBS snapshots provide point-in-time backups.
- A volume can be resized without recreating it.
- Most volume modifications do not require stopping or detaching the EC2 instance.
- Snapshots can be used to restore data into another Availability Zone.
- Snapshots can be copied to another AWS Region.
- Amazon Data Lifecycle Manager can automate snapshot creation and retention.

## Create and attach an EBS volume

In the AWS console:

```text
EC2
└── Elastic Block Store
    └── Volumes
        └── Create volume
```

Choose:

1. A volume type such as `gp3`.
2. The required size.
3. The same Availability Zone as the EC2 instance.
4. Encryption when required.
5. Useful tags such as `Name`, `Environment`, and `Owner`.

After creation:

```text
Volumes
└── Select volume
    └── Actions
        └── Attach volume
```

Choose the EC2 instance in the same Availability Zone.

## Verify the attached disk

Connect to the EC2 instance and run:

```bash
lsblk
```

Example:

```text
NAME        SIZE TYPE MOUNTPOINTS
nvme0n1       8G disk
└─nvme0n1p1   8G part /
nvme1n1       5G disk
```

In this example:

```text
nvme0n1 = root disk
nvme1n1 = newly attached EBS volume
```

On Nitro-based instances, EBS volumes commonly appear as NVMe devices even when a different device name was selected in the AWS console.

## Check the filesystem

Before formatting a volume, check whether it already contains a filesystem:

```bash
sudo file -s /dev/nvme1n1
```

or:

```bash
lsblk -f
```

Do not run `mkfs` on a volume that already contains data you want to keep.

## Format a new volume

For XFS:

```bash
sudo mkfs -t xfs /dev/nvme1n1
```

For ext4:

```bash
sudo mkfs -t ext4 /dev/nvme1n1
```

## Mount the volume

Create a mount directory:

```bash
sudo mkdir -p /data
```

Mount the volume:

```bash
sudo mount /dev/nvme1n1 /data
```

Verify:

```bash
df -hT
```

Create a test file:

```bash
echo "EBS test" | sudo tee /data/test.txt
```

## Persist the mount after reboot

Find the filesystem UUID:

```bash
sudo blkid /dev/nvme1n1
```

Back up `/etc/fstab`:

```bash
sudo cp /etc/fstab /etc/fstab.backup
```

Add an entry using the UUID.

Example for XFS:

```fstab
UUID=YOUR_VOLUME_UUID /data xfs defaults,nofail 0 2
```

Test before rebooting:

```bash
sudo umount /data
sudo mount -a
df -hT /data
```

Using a UUID is safer than depending on a device name.

## Resize an EBS volume

In the AWS console:

```text
EC2
└── Volumes
    └── Select volume
        └── Actions
            └── Modify volume
```

Increase the required size.

For example:

```text
5 GiB -> 10 GiB
```

Then check the Linux block device:

```bash
lsblk
```

If the filesystem is directly on the device, grow the filesystem.

For XFS:

```bash
sudo xfs_growfs -d /data
```

For ext4:

```bash
sudo resize2fs /dev/nvme1n1
```

If the filesystem is inside a partition such as `/dev/nvme1n1p1`, grow the partition first:

```bash
sudo growpart /dev/nvme1n1 1
```

Then expand the filesystem.

Verify:

```bash
df -hT
```

## Delete on termination

An EC2 block-device mapping contains a **Delete on termination** setting.

Typical behavior:

```text
Root EBS volume       -> usually deleted when the instance is terminated
Additional EBS volume -> commonly retained unless configured otherwise
```

Always verify the setting before terminating an instance containing important data.

A retained EBS volume continues to incur storage charges.

## Unmount and detach an EBS volume

Before detaching a mounted volume, stop applications writing to it and unmount it:

```bash
sudo umount /data
```

Verify:

```bash
lsblk
```

Then in AWS:

```text
EC2
└── Volumes
    └── Select volume
        └── Actions
            └── Detach volume
```

Wait until the volume state becomes `available`.

If the volume is no longer required, delete it after confirming that its data is backed up.

## EBS snapshots

An EBS snapshot is a point-in-time backup of an EBS volume.

Snapshots can be used to:

- Restore an EBS volume.
- Create a volume in another Availability Zone.
- Copy data to another AWS Region.
- Recover from accidental deletion or corruption.
- Create backup and disaster-recovery workflows.

Create a snapshot from:

```text
EC2
└── Volumes
    └── Select volume
        └── Actions
            └── Create snapshot
```

Snapshots are incremental, so later snapshots store changed blocks relative to previously stored snapshot data.

## Copy EBS data to another Availability Zone

An EBS volume cannot be directly moved between Availability Zones.

Use:

```text
EBS volume in AZ-A
       │
       ▼
   Snapshot
       │
       ▼
Create new volume in AZ-B
       │
       ▼
Attach to EC2 in AZ-B
```

After attaching the restored volume, inspect it:

```bash
lsblk -f
```

Mount the existing filesystem without formatting it.

## Copy an EBS snapshot to another Region

To move EBS data between Regions:

```text
Source volume
     │
     ▼
Source snapshot
     │
     ▼
Copy snapshot to another Region
     │
     ▼
Create a new volume
     │
     ▼
Attach to EC2
```

In the AWS console:

```text
EC2
└── Snapshots
    └── Select snapshot
        └── Actions
            └── Copy snapshot
```

Choose the destination Region.

After the copy completes, switch to that Region and create a new EBS volume from the copied snapshot.

## EBS encryption

EBS supports encryption using AWS Key Management Service (KMS).

Encryption protects:

- Data at rest on the volume.
- EBS snapshots.
- Volumes created from encrypted snapshots.
- Data transferred between supported EC2 instances and EBS storage.

You can use:

- The default AWS KMS key for EBS.
- A customer-managed KMS key.

A snapshot created from an encrypted EBS volume is also encrypted.

## Amazon Data Lifecycle Manager

Amazon Data Lifecycle Manager can automate the creation, retention, and deletion of EBS snapshots.

Example policy:

```text
Target:
Volumes tagged Backup=daily

Schedule:
Create snapshot every day

Retention:
Keep the latest 7 snapshots
```

Lifecycle policies help avoid relying on manual backups and can support consistent retention rules.

## EBS vs instance store

| Feature | EBS | Instance store |
|---|---|---|
| Persistent after EC2 stop | Yes | No |
| Persistent after termination | Depends on deletion settings | No |
| Snapshot support | Yes | No EBS snapshots |
| Detach and reattach | Yes | No |
| Typical use | Persistent application data | Cache and temporary data |

## EBS vs EFS vs S3

| Service | Storage model | Typical use |
|---|---|---|
| EBS | Block storage | EC2 disks, databases, persistent application data |
| EFS | Shared file storage | Shared Linux files across multiple instances |
| S3 | Object storage | Files, backups, logs, static content, archives |

Simple mental model:

```text
EBS = virtual disk
EFS = shared filesystem
S3  = object storage
```

## Common mistakes

- Creating the EBS volume in a different Availability Zone from the EC2 instance.
- Formatting a volume that already contains important data.
- Forgetting to add a persistent mount entry to `/etc/fstab`.
- Resizing the EBS volume but not expanding the filesystem.
- Detaching a mounted volume without unmounting it first.
- Terminating an instance without checking delete-on-termination settings.
- Treating same-AZ EBS redundancy as a backup.
- Leaving unused EBS volumes and snapshots running and accumulating charges.

## Security and operational guidance

- Enable EBS encryption for persistent data.
- Prefer IAM roles over long-lived AWS access keys.
- Use snapshots or AWS Backup for important data.
- Test restore procedures instead of assuming a snapshot is usable.
- Apply tags such as `Name`, `Environment`, `Owner`, and `Backup`.
- Check delete-on-termination settings before terminating instances.
- Delete unused volumes and snapshots after confirming retention requirements.
- Review AWS pricing before using large volumes or long snapshot-retention periods.

## Hands-on learning checklist

- [ ] Create an encrypted `gp3` EBS volume.
- [ ] Attach it to an EC2 instance in the same Availability Zone.
- [ ] Inspect the disk with `lsblk`.
- [ ] Format and mount the new volume.
- [ ] Configure `/etc/fstab` using the filesystem UUID.
- [ ] Write test data to the volume.
- [ ] Increase the volume size and extend the filesystem.
- [ ] Create an EBS snapshot.
- [ ] Restore the snapshot into another Availability Zone.
- [ ] Copy a snapshot to another AWS Region.
- [ ] Inspect EBS encryption settings.
- [ ] Safely unmount and detach the volume.
- [ ] Delete unused lab resources.

## Cleanup

After completing the lab:

1. Unmount the EBS volume.
2. Remove its `/etc/fstab` entry when it is no longer used.
3. Detach the volume.
4. Delete test volumes that are no longer required.
5. Delete test snapshots that are outside the required retention period.
6. Check other Regions for copied snapshots.
7. Review the billing dashboard for unused resources.

## References

- [Amazon EBS volumes](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volumes.html)
- [Amazon EBS volume types](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volume-types.html)
- [Attach an EBS volume](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-attaching-volume.html)
- [Amazon EBS snapshots](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-snapshots.html)
- [Amazon EBS encryption](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-encryption.html)
- [Amazon Data Lifecycle Manager](https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-lifecycle.html)
