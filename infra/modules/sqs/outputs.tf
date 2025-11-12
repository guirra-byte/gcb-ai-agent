# Exporting the ARN of the SQS queue
output "gcb_ai_agent_sqs_queue_fifo_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.gcb_ai_agent_sqs_queue_fifo.arn
}

# Exporting the ID (URL) of the SQS queue
output "gcb_ai_agent_sqs_queue_fifo_id" {
  description = "ID (URL) of the SQS queue"
  value       = aws_sqs_queue.gcb_ai_agent_sqs_queue_fifo.id
}

# Exporting the ARN of the SQS DLQ
output "gcb_ai_agent_sqs_dlq_fifo_queue_arn" {
  description = "ARN of the SQS Dead Letter Queue"
  value       = aws_sqs_queue.gcb_ai_agent_sqs_dlq_fifo_queue.arn
}

# Exporting the ID (URL) of the SQS DLQ
output "gcb_ai_agent_sqs_dlq_fifo_queue_id" {
  description = "ID (URL) of the SQS Dead Letter Queue"
  value       = aws_sqs_queue.gcb_ai_agent_sqs_dlq_fifo_queue.id
}