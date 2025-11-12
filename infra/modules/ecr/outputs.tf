# ================================================================================
# Outputs do Módulo ECR - Repositório Existente
# ================================================================================

# Output da URI da imagem ECR (passthrough da variável de entrada)
output "gcb_ai_agent_ecr_image_uri" {
  value       = var.gcb_ai_agent_ecr_image_uri
  description = "URI completa da imagem Docker no ECR (ex: 123456789012.dkr.ecr.us-east-1.amazonaws.com/repo:tag)"
}

# Output da URL do repositório (extraída da URI)
output "gcb_ai_agent_ecr_repository_url" {
  value       = split(":", var.gcb_ai_agent_ecr_image_uri)[0]
  description = "URL do repositório ECR sem a tag (ex: 123456789012.dkr.ecr.us-east-1.amazonaws.com/repo)"
}

# Output do nome do repositório (extraído da URI)
output "gcb_ai_agent_ecr_repository_name" {
  value = length(var.gcb_ai_agent_ecr_repository_name) > 0 ? var.gcb_ai_agent_ecr_repository_name : (
    split("/", split(":", var.gcb_ai_agent_ecr_image_uri)[0])[1]
  )
  description = "Nome do repositório ECR"
}

# Output do registry (account ID e região)
output "gcb_ai_agent_ecr_registry" {
  value       = split("/", var.gcb_ai_agent_ecr_image_uri)[0]
  description = "Registry do ECR (ex: 123456789012.dkr.ecr.us-east-1.amazonaws.com)"
}

# Output da tag da imagem
output "gcb_ai_agent_ecr_image_tag" {
  value       = split(":", var.gcb_ai_agent_ecr_image_uri)[1]
  description = "Tag da imagem Docker (ex: latest, v1.0.0)"
}

