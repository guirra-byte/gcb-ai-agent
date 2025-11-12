terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key

  assume_role {
    role_arn     = var.gcb_ai_agent_role_arn
    session_name = "gcb_ai_agent_iam_role_session"
  }
}

# ECR module (deve ser criado primeiro para ter a imagem disponível)
module "gcb_ai_agent_ecr" {
  source = "../../modules/ecr"

  environment = var.environment

  gcb_ai_agent_ecr_repository_name = var.gcb_ai_agent_ecr_repository_name
  gcb_ai_agent_ecr_image_uri      = var.gcb_ai_agent_ecr_image_uri
}

# SQS module
module "gcb_ai_agent_sqs" {
  source = "../../modules/sqs"

  environment = var.environment

  gcb_ai_agent_sqs_fifo_queue_name = var.gcb_ai_agent_sqs_fifo_queue_name
  gcb_ai_agent_sqs_fifo_queue_ssm_name = var.gcb_ai_agent_sqs_fifo_queue_ssm_name
  gcb_ai_agent_sqs_fifo_queue_ssm  = var.gcb_ai_agent_sqs_fifo_queue_ssm

  gcb_ai_agent_sqs_dlq_queue_fifo_name = var.gcb_ai_agent_sqs_dlq_queue_fifo_name
  gcb_ai_agent_sqs_dlq_queue_fifo_ssm_name = var.gcb_ai_agent_sqs_dlq_queue_fifo_ssm_name
  gcb_ai_agent_sqs_dlq_queue_fifo_ssm  = var.gcb_ai_agent_sqs_dlq_queue_fifo_ssm
}

# SNS module - para notificações de sucesso
module "gcb_ai_agent_sns" {
  source = "../../modules/sns"

  environment = var.environment

  gcb_ai_agent_sns_topic_name = var.gcb_ai_agent_sns_topic_name
  
  # Opcional: descomente para adicionar subscriptions
  # notification_email = var.notification_email
}

# Lambda module (consumes outputs from SQS and ECR)
module "gcb_ai_agent_lambda" {
  source = "../../modules/lambda"

  environment = var.environment

  gcb_ai_agent_lambda_function_name = var.gcb_ai_agent_lambda_function_name
  gcb_ai_agent_lambda_role_name     = var.gcb_ai_agent_lambda_role_name

  # Gives access to the SQS queue outputs to the Lambda function
  gcb_ai_agent_sqs_fifo_queue_arn = module.gcb_ai_agent_sqs.gcb_ai_agent_sqs_queue_fifo_arn
  gcb_ai_agent_sqs_fifo_queue_url = module.gcb_ai_agent_sqs.gcb_ai_agent_sqs_queue_fifo_id

  # Gives access to the ECR image URI to the Lambda function
  gcb_ai_agent_ecr_image_uri = module.gcb_ai_agent_ecr.gcb_ai_agent_ecr_image_uri

  gcb_ai_agent_lambda_role_arn = var.gcb_ai_agent_lambda_role_arn

  # Gives access to the environment variables to the Lambda function
  openai_api_key = var.openai_api_key
  s3_bucket_name = var.s3_bucket_name
  sns_topic_arn  = module.gcb_ai_agent_sns.gcb_ai_agent_sns_topic_arn  # Agora usa o output do módulo SNS
  s3_endpoint    = var.s3_endpoint

  # Dependências: Lambda precisa esperar ECR e SNS estarem prontos
  depends_on = [module.gcb_ai_agent_ecr, module.gcb_ai_agent_sns]
}

# ------------------- Outputs -------------------
output "ecr_repository_url" {
  value       = module.gcb_ai_agent_ecr.gcb_ai_agent_ecr_repository_url
  description = "URL do repositório ECR"
}

output "ecr_repository_name" {
  value       = module.gcb_ai_agent_ecr.gcb_ai_agent_ecr_repository_name
  description = "Nome do repositório ECR"
}

output "ecr_image_uri" {
  value       = module.gcb_ai_agent_ecr.gcb_ai_agent_ecr_image_uri
  description = "URI completa da imagem Docker (com tag latest)"
}

output "lambda_function_name" {
  value       = var.gcb_ai_agent_lambda_function_name
  description = "Nome da função Lambda"
}

output "sqs_queue_url" {
  value       = module.gcb_ai_agent_sqs.gcb_ai_agent_sqs_queue_fifo_id
  description = "URL da fila SQS"
}

output "sns_topic_arn" {
  value       = module.gcb_ai_agent_sns.gcb_ai_agent_sns_topic_arn
  description = "ARN do tópico SNS para notificações"
}

output "sns_topic_name" {
  value       = module.gcb_ai_agent_sns.gcb_ai_agent_sns_topic_name
  description = "Nome do tópico SNS"
}
