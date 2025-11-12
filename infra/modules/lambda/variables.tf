# ------------------- Environment -------------------
variable "environment" {
  type        = string
  description = "Environment to deploy the infrastructure"
  default     = "dev"
}

# ------------------- OpenAI API Key Environment Variable -------------------
variable "openai_api_key" {
  type        = string
  description = "OpenAI API key"
  default     = "sk-proj-1234567890"
}

# ------------------- S3 Bucket Name Environment Variable -------------------
variable "s3_bucket_name" {
  type        = string
  description = "S3 bucket name"
  default     = "gcb-ai-agent-dev"
}

# ------------------- SNS Topic ARN Environment Variable -------------------
variable "sns_topic_arn" {
  type        = string
  description = "SNS topic ARN"
  default     = "arn:aws:sns:us-east-1:046801216531:gcb-ai-agent-dev"
}

# ------------------- S3 Endpoint Environment Variable -------------------
variable "s3_endpoint" {
  type        = string
  description = "S3 endpoint"
  default     = "https://s3.us-east-1.amazonaws.com"
}

# ------------------- Lambda Role Name -------------------
variable "gcb_ai_agent_lambda_role_name" {
  type        = string
  description = "Name of the Lambda role"
  default     = "gcb_ai_agent_lambda_role"
}

# ------------------- Lambda Role ARN -------------------
variable "gcb_ai_agent_lambda_role_arn" {
  type        = string
  description = "ARN of the Lambda role"
  default     = "arn:aws:iam::123456789012:role/gcb_ai_agent_lambda_role"
}

# ------------------- Lambda Function Name -------------------
variable "gcb_ai_agent_lambda_function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "gcb_ai_agent_lambda_function"
}

# ------------------- Inherit Outputs from SQS module -------------------
variable "gcb_ai_agent_sqs_fifo_queue_arn" {
  type        = string
  description = "ARN of the SQS queue"
}

variable "gcb_ai_agent_sqs_fifo_queue_url" {
  type        = string
  description = "URL of the SQS queue"
}

# ------------------- Inherit Output from ECR module -------------------
variable "gcb_ai_agent_ecr_image_uri" {
  type        = string
  description = "URI da imagem Docker no ECR (ex: 123456789.dkr.ecr.us-east-1.amazonaws.com/gcb-ai-agent:latest)"
}