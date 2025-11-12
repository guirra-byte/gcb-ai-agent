#!/bin/bash

# Script para fazer build e push da imagem Docker para o ECR
# 
# Uso:
#   ./build-and-push.sh [região] [nome-repositório] [tag]
#
# Exemplo:
#   ./build-and-push.sh us-east-1 gcb-ai-agent latest

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parâmetros com valores padrão
AWS_REGION="${1:-us-east-1}"
REPOSITORY_NAME="${2:-gcb-ai-agent}"
IMAGE_TAG="${3:-latest}"

echo -e "${GREEN}🚀 Build and Push para ECR${NC}"
echo "================================"
echo "Região: $AWS_REGION"
echo "Repositório: $REPOSITORY_NAME"
echo "Tag: $IMAGE_TAG"
echo "================================"

# Obter o Account ID da AWS
echo -e "\n${YELLOW}📋 Obtendo AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $AWS_ACCOUNT_ID"

# Nome completo do repositório ECR
ECR_REPOSITORY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}"

# Verificar se o repositório existe
echo -e "\n${YELLOW}🔍 Verificando se o repositório ECR existe...${NC}"
if ! aws ecr describe-repositories --repository-names "$REPOSITORY_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Repositório não encontrado. Criando...${NC}"
    aws ecr create-repository \
        --repository-name "$REPOSITORY_NAME" \
        --region "$AWS_REGION" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    echo -e "${GREEN}✅ Repositório criado com sucesso!${NC}"
else
    echo -e "${GREEN}✅ Repositório encontrado${NC}"
fi

# Login no ECR
echo -e "\n${YELLOW}🔐 Fazendo login no ECR...${NC}"
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo -e "${GREEN}✅ Login realizado com sucesso${NC}"

# Build da imagem
echo -e "\n${YELLOW}🏗️  Building Docker image...${NC}"
docker build \
    --platform linux/amd64 \
    -t "${REPOSITORY_NAME}:${IMAGE_TAG}" \
    -f lambdas/Dockerfile \
    lambdas/
echo -e "${GREEN}✅ Build concluído${NC}"

# Tag da imagem para ECR
echo -e "\n${YELLOW}🏷️  Tagging image...${NC}"
docker tag "${REPOSITORY_NAME}:${IMAGE_TAG}" "${ECR_REPOSITORY}:${IMAGE_TAG}"
docker tag "${REPOSITORY_NAME}:${IMAGE_TAG}" "${ECR_REPOSITORY}:latest"
echo -e "${GREEN}✅ Tag aplicada${NC}"

# Push para ECR
echo -e "\n${YELLOW}📤 Pushing para ECR...${NC}"
docker push "${ECR_REPOSITORY}:${IMAGE_TAG}"
docker push "${ECR_REPOSITORY}:latest"
echo -e "${GREEN}✅ Push concluído${NC}"

# Informações finais
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Imagem disponível em:"
echo "  ${ECR_REPOSITORY}:${IMAGE_TAG}"
echo "  ${ECR_REPOSITORY}:latest"
echo ""
echo "URI da imagem:"
echo "  ${ECR_REPOSITORY}:${IMAGE_TAG}"
echo ""
echo -e "${YELLOW}Para usar em ECS/Fargate, use o URI acima na sua task definition.${NC}"
echo -e "${YELLOW}Para usar em Lambda, crie uma função Lambda com container image usando o URI acima.${NC}"

