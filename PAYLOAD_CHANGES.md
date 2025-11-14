# 🚨 BREAKING CHANGE: SQS Payload Structure Updated

## Summary

The Lambda function no longer accepts `bucket_name` in the SQS message payload. The S3 bucket is now configured via the `S3_BUCKET_NAME` environment variable (set by Terraform).

## Why This Change?

### Security & Architecture Benefits:
1. **🔒 Security:** Prevents malicious payloads from specifying unauthorized S3 buckets
2. **🏗️ Architecture:** Bucket configuration is infrastructure concern, not runtime data
3. **🌍 Environment Isolation:** Cleaner separation between dev/prod environments
4. **✅ Validation:** Easier to validate and audit S3 access patterns
5. **📦 Simpler Payload:** Reduces message size and complexity

## What Changed

### ❌ OLD Payload (No Longer Works)
```json
{
  "Records": [
    {
      "body": "{\"file_key\": \"path/to/file.pdf\", \"contract_id\": \"contract-123\", \"bucket_name\": \"gcb-ai-agent-test\"}"
    }
  ]
}
```

### ✅ NEW Payload (Required)
```json
{
  "Records": [
    {
      "body": "{\"file_key\": \"path/to/file.pdf\", \"contract_id\": \"contract-123\"}"
    }
  ]
}
```

## Required Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file_key` | string | ✅ Yes | S3 object key (path to file within bucket) |
| `contract_id` | string | ✅ Yes | Unique identifier for the contract |
| ~~`bucket_name`~~ | ~~string~~ | ❌ Removed | Now comes from `S3_BUCKET_NAME` env var |

## Environment Variable Configuration

The Lambda function now reads the bucket from the `S3_BUCKET_NAME` environment variable:

```bash
# Example: Set in Lambda Configuration (via Terraform)
S3_BUCKET_NAME=gcb-ai-agent-test
```

This is automatically configured by Terraform in `infra/modules/lambda/main.tf`:

```hcl
environment {
  variables = {
    S3_BUCKET_NAME = var.s3_bucket_name
    # ... other vars
  }
}
```

## Migration Guide

### If You're Sending Messages to SQS

**Update your code to remove `bucket_name` from the message:**

**Before:**
```python
message = {
    "file_key": "path/to/file.pdf",
    "contract_id": "contract-123",
    "bucket_name": "gcb-ai-agent-test"  # ❌ Remove this
}
```

**After:**
```python
message = {
    "file_key": "path/to/file.pdf",
    "contract_id": "contract-123"
    # bucket_name is now set via Lambda environment variable
}
```

### If You're Testing Locally

Make sure to set the `S3_BUCKET_NAME` environment variable:

```bash
# In docker-compose.yml or .env file
S3_BUCKET_NAME=gcb-ai-agent-test
```

### If You're Using API/SDK

Update any API calls or SDK usage that sends messages to the SQS queue:

**Before:**
```javascript
const message = {
  file_key: "path/to/file.pdf",
  contract_id: "contract-123",
  bucket_name: "gcb-ai-agent-test"  // ❌ Remove
};
```

**After:**
```javascript
const message = {
  file_key: "path/to/file.pdf",
  contract_id: "contract-123"
  // Bucket is configured in Lambda environment
};
```

## Error Messages

### Missing Environment Variable
If `S3_BUCKET_NAME` is not set in Lambda configuration:
```
❌ Error: S3_BUCKET_NAME environment variable not set
ValueError: S3_BUCKET_NAME environment variable is required
```

**Solution:** Ensure Terraform has deployed the environment variable correctly.

### Missing contract_id
If `contract_id` is missing from the message:
```
❌ Error: 'contract_id' not found in message: {...}
```

**Solution:** Add `contract_id` to your SQS message payload.

### Missing file_key
If `file_key` is missing from the message:
```
❌ Error: 'file_key' not found in message: {...}
```

**Solution:** Add `file_key` to your SQS message payload.

## Testing

### Test Payload for Lambda Console

```json
{
  "Records": [
    {
      "messageId": "test-message-1",
      "receiptHandle": "test-receipt-handle",
      "body": "{\"file_key\": \"documents-extraction/gcb-bucket/dev/contracts-to-extract/7350ace0-f067-4dd6-9c97-35bbeedd8b32/2-aditivo-gran-vellas.pdf.pdf\", \"contract_id\": \"7350ace0-f067-4dd6-9c97-35bbeedd8b32\"}",
      "attributes": {
        "ApproximateReceiveCount": "1",
        "SentTimestamp": "1523232000000",
        "SenderId": "123456789012",
        "ApproximateFirstReceiveTimestamp": "1523232000001"
      },
      "messageAttributes": {},
      "md5OfBody": "test-md5",
      "eventSource": "aws:sqs",
      "eventSourceARN": "arn:aws:sqs:us-east-1:123456789012:test-queue",
      "awsRegion": "us-east-1"
    }
  ]
}
```

### Expected Log Output

```
📦 Using S3 bucket: gcb-ai-agent-test
📥 Processing file: s3://gcb-ai-agent-test/documents-extraction/.../file.pdf
⬇️  Downloading from S3 to /tmp/file.pdf...
✓ File downloaded successfully
```

## Backwards Compatibility

⚠️ **This is a BREAKING CHANGE** - There is NO backwards compatibility.

If you try to use the old payload format with `bucket_name`, the Lambda will:
1. ✅ Still work (the `bucket_name` field will be ignored)
2. ✅ Use the `S3_BUCKET_NAME` environment variable instead
3. ⚠️ Log a warning that the field is being ignored (future implementation)

## Deployment Checklist

- [ ] Deploy updated Lambda code (with `main.py` changes)
- [ ] Verify `S3_BUCKET_NAME` is set in Lambda environment variables
- [ ] Update all systems that send messages to SQS (remove `bucket_name`)
- [ ] Test with new payload format
- [ ] Monitor CloudWatch logs for errors
- [ ] Update API documentation
- [ ] Notify team members of the change

## Questions?

If you encounter issues:
1. Check Lambda environment variables: `S3_BUCKET_NAME` should be set
2. Check CloudWatch logs for error messages
3. Verify IAM permissions for the bucket specified in `S3_BUCKET_NAME`
4. Ensure message payload has both `file_key` and `contract_id`

---

**Date:** November 14, 2025  
**Status:** ✅ Ready for Deployment  
**Impact:** 🚨 BREAKING CHANGE

