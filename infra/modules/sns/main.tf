# ============================================================
# SNS Topic Module - GCB AI Agent
# ============================================================

# Resource to create the SNS topic for contract processing notifications
resource "aws_sns_topic" "gcb_ai_agent_topic" {
  name = var.gcb_ai_agent_sns_topic_name

  # Enable server-side encryption
  kms_master_key_id = "alias/aws/sns"

  # Message delivery retry policy
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = {
    Name        = "${var.gcb_ai_agent_sns_topic_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "GCB-AI-Agent"
    Description = "Topic for contract processing completion notifications"
  }
}

# Resource to create SNS topic policy - permite Lambda publicar
resource "aws_sns_topic_policy" "gcb_ai_agent_topic_policy" {
  arn = aws_sns_topic.gcb_ai_agent_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.gcb_ai_agent_topic.arn
      },
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.gcb_ai_agent_topic.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# ============================================================
# CloudWatch Alarms para monitoramento
# ============================================================

resource "aws_cloudwatch_metric_alarm" "sns_failed_notifications" {
  alarm_name          = "${var.gcb_ai_agent_sns_topic_name}-failed-notifications-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors failed SNS notifications"
  alarm_actions       = [] # Adicione ARNs de outros SNS topics ou ações aqui

  dimensions = {
    TopicName = aws_sns_topic.gcb_ai_agent_topic.name
  }

  tags = {
    Name        = "${var.gcb_ai_agent_sns_topic_name}-alarm-${var.environment}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

