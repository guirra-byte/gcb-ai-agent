# ================================================================================
# Variáveis do Módulo ECR - Repositório Existente
# ================================================================================

# ------------------- ECR Image URI (OBRIGATÓRIO) -------------------
variable "gcb_ai_agent_ecr_image_uri" {
  type        = string
  description = "URI completa da imagem ECR existente (inclui registry, repositório e tag)"
  
  # Exemplo: 123456789012.dkr.ecr.us-east-1.amazonaws.com/gcb-ai-agent-lambda:latest
  default = "046801216531.dkr.ecr.us-east-1.amazonaws.com/gcb/ai-agent-test:latest"
  
  validation {
    condition     = can(regex("^[0-9]+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/.+:.+$", var.gcb_ai_agent_ecr_image_uri))
    error_message = "A URI do ECR deve estar no formato: {account-id}.dkr.ecr.{region}.amazonaws.com/{repo-name}:{tag}"
  }
}

# ------------------- ECR Repository Name (OPCIONAL) -------------------
variable "gcb_ai_agent_ecr_repository_name" {
  type        = string
  description = "Nome do repositório ECR (extraído da URI se não fornecido)"
  default     = ""
}

# ------------------- Environment -------------------
variable "environment" {
  type        = string
  description = "Ambiente de deploy (dev, staging, prod)"
  default     = "dev"
}

