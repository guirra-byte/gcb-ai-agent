#!/bin/bash

# Script completo de deploy: Build Docker -> Push ECR -> Apply Terraform
# 
# Uso:
#   ./deploy-full.sh [ambiente] [região]
#
# Exemplo:
#   ./deploy-full.sh dev us-east-1

set -e  # Parar em caso de erro

# ============================================================
# Configuração
# ============================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parâmetros com valores padrão
ENVIRONMENT="${1:-dev}"
AWS_REGION="${2:-us-east-1}"
IMAGE_TAG="${3:-latest}"

# Diretórios
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFRA_DIR="${SCRIPT_DIR}/infra/environments/${ENVIRONMENT}"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🚀 Deploy Completo - GCB AI Agent              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Ambiente:${NC} $ENVIRONMENT"
echo -e "${GREEN}Região:${NC}    $AWS_REGION"
echo -e "${GREEN}Tag:${NC}       $IMAGE_TAG"
echo ""

# ============================================================
# Validações
# ============================================================

echo -e "${YELLOW}[1/5] 🔍 Validando pré-requisitos...${NC}"

# Verificar se AWS CLI está instalado
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/${NC}"
    exit 1
fi

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado. Instale: https://www.docker.com/${NC}"
    exit 1
fi

# Verificar se Terraform está instalado
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform não encontrado. Instale: https://www.terraform.io/${NC}"
    exit 1
fi

# Verificar se o diretório do ambiente existe
if [ ! -d "$INFRA_DIR" ]; then
    echo -e "${RED}❌ Diretório do ambiente não encontrado: $INFRA_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Todos os pré-requisitos atendidos${NC}"

# ============================================================
# Terraform Init/Plan (para criar ECR se não existir)
# ============================================================

echo -e "\n${YELLOW}[2/5] 📋 Inicializando Terraform e criando ECR...${NC}"

cd "$INFRA_DIR"

# Inicializar Terraform
terraform init

# Criar apenas o módulo ECR primeiro (se não existir)
echo -e "${YELLOW}Criando repositório ECR (se necessário)...${NC}"
terraform apply -target=module.gcb_ai_agent_ecr -auto-approve

# Obter informações do ECR
ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")

if [ -z "$ECR_REPOSITORY_URL" ]; then
    echo -e "${RED}❌ Erro ao obter URL do repositório ECR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Repositório ECR pronto: $ECR_REPOSITORY_URL${NC}"

# Obter Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ============================================================
# Build e Push da Imagem Docker
# ============================================================

echo -e "\n${YELLOW}[3/5] 🐳 Building e pushing imagem Docker...${NC}"

cd "$SCRIPT_DIR"

# Login no ECR
echo -e "${YELLOW}🔐 Fazendo login no ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build da imagem
echo -e "${YELLOW}🏗️  Building Docker image...${NC}"
docker build \
    --platform linux/amd64 \
    -t "gcb-ai-agent:${IMAGE_TAG}" \
    -f Dockerfile \
    .

# Tag da imagem para ECR
echo -e "${YELLOW}🏷️  Tagging image...${NC}"
docker tag "gcb-ai-agent:${IMAGE_TAG}" "${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
docker tag "gcb-ai-agent:${IMAGE_TAG}" "${ECR_REPOSITORY_URL}:latest"

# Push para ECR
echo -e "${YELLOW}📤 Pushing para ECR...${NC}"
docker push "${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
docker push "${ECR_REPOSITORY_URL}:latest"

echo -e "${GREEN}✅ Imagem Docker disponível no ECR${NC}"

# ============================================================
# Terraform Apply Completo
# ============================================================

echo -e "\n${YELLOW}[4/5] 🏗️  Aplicando infraestrutura completa com Terraform...${NC}"

cd "$INFRA_DIR"

# Plan
echo -e "${YELLOW}Gerando plano de execução...${NC}"
terraform plan -out=tfplan

# Apply
echo -e "${YELLOW}Aplicando mudanças...${NC}"
terraform apply tfplan

echo -e "${GREEN}✅ Infraestrutura atualizada${NC}"

# ============================================================
# Atualizar Lambda (força a usar nova imagem)
# ============================================================

echo -e "\n${YELLOW}[5/5] 🔄 Atualizando função Lambda...${NC}"

LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name)

# Forçar atualização da Lambda para pegar a nova imagem
aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --image-uri "${ECR_REPOSITORY_URL}:latest" \
    --region "$AWS_REGION" \
    > /dev/null

# Aguardar a atualização ser concluída
echo -e "${YELLOW}Aguardando atualização da Lambda...${NC}"
aws lambda wait function-updated \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --region "$AWS_REGION"

echo -e "${GREEN}✅ Função Lambda atualizada${NC}"

# ============================================================
# Resumo Final
# ============================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ✅ Deploy Completo com Sucesso!                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Imagem Docker:${NC}"
echo "   ${ECR_REPOSITORY_URL}:${IMAGE_TAG}"
echo ""
echo -e "${GREEN}⚡ Função Lambda:${NC}"
echo "   ${LAMBDA_FUNCTION_NAME}"
echo ""
echo -e "${GREEN}📊 SQS Queue:${NC}"
SQS_QUEUE_URL=$(terraform output -raw sqs_queue_url)
echo "   ${SQS_QUEUE_URL}"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "   1. Envie mensagens para a fila SQS para testar"
echo "   2. Monitore logs no CloudWatch: /aws/lambda/${LAMBDA_FUNCTION_NAME}"
echo "   3. Verifique métricas no console da AWS"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════${NC}"

