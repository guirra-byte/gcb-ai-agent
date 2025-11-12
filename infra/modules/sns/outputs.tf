# ------------------- SNS Topic ARN -------------------
output "gcb_ai_agent_sns_topic_arn" {
  value       = aws_sns_topic.gcb_ai_agent_topic.arn
  description = "ARN of the SNS topic for contract processing notifications"
}

# ------------------- SNS Topic Name -------------------
output "gcb_ai_agent_sns_topic_name" {
  value       = aws_sns_topic.gcb_ai_agent_topic.name
  description = "Name of the SNS topic"
}

# ------------------- SNS Topic ID -------------------
output "gcb_ai_agent_sns_topic_id" {
  value       = aws_sns_topic.gcb_ai_agent_topic.id
  description = "ID of the SNS topic"
}

