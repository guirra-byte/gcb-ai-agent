variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

# ------------------- AWS ACCESS KEY ID -------------------
variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID"
}

# ------------------- AWS SECRET ACCESS KEY -------------------
variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key"
}

# ------------------- ENVIRONMENT -------------------
variable "environment" {
  type        = string
  description = "Environment"
  default     = "prod"
}

# ------------------- ROLE -------------------
variable "gcb_ai_agent_role_arn" {
  type        = string
  description = "ARN of the GCB AI Agent role"
}

variable "gcb_ai_agent_lambda_role_arn" {
  type        = string
  description = "ARN of the Lambda role"
}

# ------------------- LAMBDA -------------------
variable "gcb_ai_agent_lambda_role_name" {
  type        = string
  description = "Name of the Lambda role"
}

variable "gcb_ai_agent_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
}

# ------------------- SQS -------------------
variable "gcb_ai_agent_sqs_fifo_queue_name" {
  type        = string
  description = "Name of the SQS FIFO queue"
}

variable "gcb_ai_agent_sqs_dlq_queue_fifo_name" {
  type        = string
  description = "Name of the SQS deadletter FIFO queue"
}

# ------------------- SQS SSM PARAMETERS -------------------
variable "gcb_ai_agent_sqs_fifo_queue_ssm_name" {
  type        = string
  description = "Name of the SQS FIFO queue SSM"
}

variable "gcb_ai_agent_sqs_fifo_queue_ssm" {
  type        = string
  description = "Name of the SQS FIFO queue SSM"
}

variable "gcb_ai_agent_sqs_dlq_queue_fifo_ssm_name" {
  type        = string
  description = "Name of the SQS deadletter FIFO queue SSM"
}

variable "gcb_ai_agent_sqs_dlq_queue_fifo_ssm" {
  type        = string
  description = "Name of the SQS deadletter FIFO queue SSM"
}

# ------------------- ECR -------------------
variable "gcb_ai_agent_ecr_repository_name" {
  type        = string
  description = "Name of the ECR repository"
  default     = "gcb-ai-agent"
}

variable "ecr_principal_arns" {
  type        = list(string)
  description = "List of ARNs that can push/pull images from ECR"
  default     = []
}

variable "gcb_ai_agent_ecr_image_uri" {
  type        = string
  description = "URI of the ECR image"
}

# ------------------- LAMBDA ENVIRONMENT VARIABLES -------------------
variable "openai_api_key" {
  type        = string
  description = "OpenAI API key"
  sensitive   = true
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN"
}

variable "s3_endpoint" {
  type        = string
  description = "S3 endpoint"
  default     = "https://s3.us-east-1.amazonaws.com"
}