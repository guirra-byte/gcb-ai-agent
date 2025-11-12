# ------------------- Environment -------------------
variable "environment" {
  type        = string
  description = "Environment to deploy the infrastructure (dev, staging, prod)"
  default     = "dev"
}

# ------------------- SNS Topic Name -------------------
variable "gcb_ai_agent_sns_topic_name" {
  type        = string
  description = "Name of the SNS topic for contract processing notifications"
  default     = "gcb-ai-agent-notifications"
}

# ------------------- Optional: Email for Notifications -------------------
variable "notification_email" {
  type        = string
  description = "Email address to receive SNS notifications (optional)"
  default     = ""
}

# ------------------- Optional: SQS Queue ARN for Subscription -------------------
variable "notification_queue_arn" {
  type        = string
  description = "ARN of SQS queue to subscribe to SNS topic (optional)"
  default     = ""
}

