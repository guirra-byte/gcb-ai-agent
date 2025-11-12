# Módulo ECR - AWS Elastic Container Registry

Este módulo Terraform cria e gerencia um repositório ECR (Elastic Container Registry) para armazenar imagens Docker da aplicação GCB AI Agent.

## 📋 Propósito

Este módulo cria um repositório ECR completo com:

1. ✅ Repositório ECR privado
2. ✅ Lifecycle policies (limpeza automática de imagens antigas)
3. ✅ Repository policies (permissões de acesso)
4. ✅ Scan de segurança automático
5. ✅ Criptografia AES256

## 🚀 Uso

### Exemplo Básico

```hcl
module "ecr" {
  source = "../../modules/ecr"
  
  gcb_ai_agent_ecr_repository_name = "gcb-ai-agent"
  environment                      = "dev"
}
```

### Exemplo Completo

```hcl
module "ecr" {
  source = "../../modules/ecr"
  
  gcb_ai_agent_ecr_repository_name = "gcb-ai-agent"
  ecr_principal_arns = [
    "arn:aws:iam::123456789012:role/deployment-role",
    "arn:aws:iam::123456789012:role/lambda-execution-role"
  ]
  environment = "production"
}
```

## 📥 Variáveis de Entrada

| Nome | Tipo | Obrigatório | Padrão | Descrição |
|------|------|-------------|--------|-----------|
| `gcb_ai_agent_ecr_repository_name` | string | ✅ Sim | - | Nome do repositório ECR |
| `ecr_principal_arns` | list(string) | ❌ Não | `[]` | ARNs de IAM roles/users que podem acessar o repositório |
| `environment` | string | ❌ Não | `"dev"` | Ambiente de deploy (dev, staging, prod) |

## 📤 Outputs

| Nome | Descrição | Exemplo |
|------|-----------|---------|
| `gcb_ai_agent_ecr_repository_url` | URL do repositório sem tag | `123456789012.dkr.ecr.us-east-1.amazonaws.com/gcb-ai-agent` |
| `gcb_ai_agent_ecr_repository_arn` | ARN do repositório | `arn:aws:ecr:us-east-1:123456789012:repository/gcb-ai-agent` |
| `gcb_ai_agent_ecr_image_uri` | URI completa da imagem com tag latest | `123456789012.dkr.ecr.us-east-1.amazonaws.com/gcb-ai-agent:latest` |
| `gcb_ai_agent_ecr_repository_name` | Nome do repositório | `gcb-ai-agent` |

## 🔧 Recursos Criados

### 1. aws_ecr_repository

Repositório privado com:

```hcl
image_scanning_configuration {
  scan_on_push = true  # Scan de segurança automático
}

encryption_configuration {
  encryption_type = "AES256"  # Criptografia
}
```

### 2. aws_ecr_lifecycle_policy

Política de limpeza automática:

- ✅ Mantém apenas as 10 últimas imagens taggeadas
- ✅ Remove imagens sem tag após 7 dias

Isso economiza custos de armazenamento e mantém o repositório organizado.

### 3. aws_ecr_repository_policy

Permissões de acesso para:

- ✅ Lambda puxar imagens
- ✅ Roles especificadas fazerem push/pull
- ✅ Serviços AWS autorizados

## 🔐 Permissões Necessárias

### Para Criar o Repositório (Terraform)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:PutLifecyclePolicy",
        "ecr:SetRepositoryPolicy",
        "ecr:DeleteRepository"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/gcb-ai-agent"
    }
  ]
}
```

### Para Lambda Acessar o ECR

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/gcb-ai-agent"
    },
    {
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    }
  ]
}
```

### Para Deploy (Push de Imagens)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/gcb-ai-agent"
    },
    {
      "Effect": "Allow",
      "Action": ["ecr:GetAuthorizationToken"],
      "Resource": "*"
    }
  ]
}
```

## 📝 Como Usar Após Criar

### 1. Login no ECR

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"

aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

### 2. Build e Push

```bash
# Build
docker build -t gcb-ai-agent:latest .

# Tag
docker tag gcb-ai-agent:latest \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/gcb-ai-agent:latest

# Push
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/gcb-ai-agent:latest
```

### 3. Usar em Lambda

```hcl
resource "aws_lambda_function" "example" {
  function_name = "my-function"
  package_type  = "Image"
  image_uri     = module.ecr.gcb_ai_agent_ecr_image_uri
  role          = aws_iam_role.lambda.arn
  
  timeout     = 900
  memory_size = 4096
}
```

## 🔄 Lifecycle Policy

O módulo configura automaticamente uma política de lifecycle que:

### Regra 1: Imagens Taggeadas
- Mantém apenas as **10 últimas imagens** com tags
- Mais antigas são removidas automaticamente
- Economiza custos de armazenamento

### Regra 2: Imagens Sem Tag
- Remove imagens sem tag após **7 dias**
- Limpa imagens de build intermediário
- Mantém o repositório organizado

**Exemplo prático:**

```
Dia 1:  push v1.0.0, v1.0.1, v1.0.2, ... v1.0.10  ✅ Todas mantidas
Dia 2:  push v1.0.11                             ✅ v1.0.0 removida (11ª mais antiga)
Dia 3:  push latest (sem tag permanente)         ✅ Mantida por 7 dias
Dia 10: -                                         ❌ latest removida (7 dias)
```

## 📊 Monitoramento

### CloudWatch Metrics

O ECR automaticamente envia métricas para CloudWatch:

- `RepositoryPullCount` - Número de pulls
- `RepositoryImageCount` - Número de imagens
- `RepositoryImageScanFindings` - Vulnerabilidades encontradas

### Verificar Imagens

```bash
# Listar imagens
aws ecr list-images --repository-name gcb-ai-agent

# Descrever imagens com detalhes
aws ecr describe-images --repository-name gcb-ai-agent

# Ver resultados de scan de segurança
aws ecr describe-image-scan-findings \
    --repository-name gcb-ai-agent \
    --image-id imageTag=latest
```

## 💰 Custos

### Armazenamento
- **$0.10 por GB/mês** na us-east-1
- Lifecycle policy ajuda a economizar removendo imagens antigas

### Data Transfer
- **Gratuito** dentro da mesma região
- **$0.09 por GB** para fora da AWS

### Scan de Segurança
- **Primeiro scan gratuito** por imagem
- **$0.09 por scan** adicional

**Exemplo de custo:**
- 5 imagens × 1GB cada = **$0.50/mês**
- 1000 pulls/mês dentro da região = **$0.00**
- Scan automático = **$0.00** (primeiro scan)

## 🐛 Troubleshooting

### Erro: "Repository already exists"

```bash
# Verificar se já existe
aws ecr describe-repositories --repository-names gcb-ai-agent

# Importar para Terraform se necessário
terraform import module.ecr.aws_ecr_repository.gcb_ai_agent gcb-ai-agent
```

### Erro: "Access Denied" ao fazer push

```bash
# Verificar permissões
aws ecr get-repository-policy --repository-name gcb-ai-agent

# Fazer login novamente
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### Lambda não consegue puxar imagem

1. Verificar se a image URI está correta
2. Confirmar que a role da Lambda tem permissões ECR
3. Verificar se a imagem existe com a tag especificada

```bash
# Verificar imagem
aws ecr describe-images \
    --repository-name gcb-ai-agent \
    --image-ids imageTag=latest
```

### Imagens sendo removidas muito rápido

Ajuste a lifecycle policy no arquivo `main.tf` do módulo:

```json
{
  "rules": [{
    "rulePriority": 1,
    "selection": {
      "tagStatus": "tagged",
      "countType": "imageCountMoreThan",
      "countNumber": 20  // ← Aumentar este número
    }
  }]
}
```

## 📚 Recursos Relacionados

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [ECR Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
- [Script de Build: ../../../build-and-push.sh](../../../build-and-push.sh)
- [Módulo Lambda](../lambda/)

---

**Última atualização**: 2025-11-10
