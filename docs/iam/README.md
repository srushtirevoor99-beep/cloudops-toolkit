# IAM policy reference

JSON policies for the roles described in the main README. Replace `<ACCOUNT_ID>`
and `<INSTANCE_ID>` before using them, and compare the deploy files with the
roles you already created in your account.

| File | Attach to | Purpose |
|---|---|---|
| `ec2-s3-backup-policy.json` | `cloudops-ec2-s3-role` (replaces `AmazonS3FullAccess`) | List, upload and download objects under `backups/` in one bucket, nothing else |
| `ec2-sns-notify-policy.json` | `cloudops-ec2-s3-role` (only if you use `NOTIFY_TOPIC_ARN`) | Publish failure messages to one SNS topic |
| `github-actions-trust-policy.json` | Trust policy of `github-actions-deploy` | Only this repository's `main` branch can assume the role through OIDC |
| `github-deploy-ssm-policy.json` | `github-actions-deploy` | Run shell commands on one instance and read the command result |

`s3:ListBucket` is a bucket-level action, so it needs the bucket ARN and a
`s3:prefix` condition. `s3:PutObject` and `s3:GetObject` are object-level, so
they need `bucket/prefix/*`. Mixing these up is the most common reason a scoped
S3 policy fails with `AccessDenied`.

## Apply the scoped S3 policy

1. IAM console, roles, `cloudops-ec2-s3-role`, add permissions, create inline policy, JSON, paste `ec2-s3-backup-policy.json`.
2. Run a backup on the instance and a restore (`scripts/restore.sh`) and check both still work.
3. Only then remove `AmazonS3FullAccess` from the role.
