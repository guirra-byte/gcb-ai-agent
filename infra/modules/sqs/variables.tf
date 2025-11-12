variable "environment" {
  type        = string
  description = "Environment to deploy the infrastructure"
  default     = "dev"
}

# ------------------- ROLE ARN -------------------
variable "gcb_ai_agent_role_arn" {
  type        = string
  description = "ARN of the GCB AI Agent role"
  default     = "arn:aws:iam::123456789012:role/gcb_ai_agent_role"
}

# ------------------- SQS FIFO Queue Name -------------------
variable "gcb_ai_agent_sqs_fifo_queue_name" {
  type        = string
  description = "Name of the SQS queue"
  default     = "gcb_ai_agent_sqs_queue_fifo.fifo"
}

# ------------------- SQS Deadletter FIFO Queue Name -------------------
variable "gcb_ai_agent_sqs_dlq_queue_fifo_name" {
  type        = string
  description = "Name of the SQS queue deadletter"
  default     = "gcb_ai_agent_sqs_dlq_queue_fifo.fifo"
}

# ------------------- SQS FIFO Queue SSM -------------------
variable "gcb_ai_agent_sqs_fifo_queue_ssm_name" {
  type        = string
  description = "Name of the SQS FIFO queue SSM parameter"
  default     = "gcb_ai_agent_sqs_fifo_queue_ssm"
}

variable "gcb_ai_agent_sqs_fifo_queue_ssm" {
  type        = string
  description = "SSM Parameter Store Path to expose the SQS queue URL"
  default     = "/gcb-ai-agent/dev/sqs/gcb_ai_agent_sqs_queue_fifo_url"
}

# ------------------- SQS Deadletter FIFO Queue SSM -------------------
variable "gcb_ai_agent_sqs_dlq_queue_fifo_ssm_name" {
  type        = string
  description = "Name of the SQS Deadletter FIFO queue SSM parameter"
  default     = "gcb_ai_agent_sqs_deadletter_fifo_queue_ssm"
}

variable "gcb_ai_agent_sqs_dlq_queue_fifo_ssm" {
  type        = string
  description = "SSM Parameter Store Path to expose the SQS Deadletter queue URL"
  default     = "/gcb-ai-agent/dev/sqs/gcb_ai_agent_sqs_dlq_queue_fifo_url"
}