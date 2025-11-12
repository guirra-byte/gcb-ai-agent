# 🚀 Guia de Deploy - GCB AI Agent

Guia completo para fazer deploy da aplicação usando Docker, ECR, Lambda e Terraform.

## 📋 Pré-requisitos

### Ferramentas Necessárias

```bash
# Verificar instalações
aws --version      # AWS CLI
docker --version   # Docker
terraform --version # Terraform >= 1.0.0
```

### Configuração AWS

```bash
# Configurar credenciais
aws configure

# Verificar acesso
aws sts get-caller-identity
```

### Permissões IAM Necessárias

Sua conta AWS precisa das seguintes permissões:

- `ecr:*` - Gerenciar repositórios ECR
- `lambda:*` - Gerenciar funções Lambda
- `sqs:*` - Gerenciar filas SQS
- `iam:*` - Gerenciar roles e políticas
- `logs:*` - CloudWatch Logs

## ⚡ Quick Start (5 minutos)

### 1️⃣ Configurar Variáveis

Edite `infra/environments/dev/dev.tfvars`:

```hcl
aws_region = "us-east-1"

# Credenciais AWS (ou use profile)
aws_access_key_id     = "AKIAXXXXXXXX"
aws_secret_access_key = "xxxxxxxxxxxxx"

# ARNs das roles IAM (já devem existir)
gcb_ai_agent_role_arn        = "arn:aws:iam::123456789:role/your-role"
gcb_ai_agent_lambda_role_arn = "arn:aws:iam::123456789:role/lambda-role"

# Nomes dos recursos (ajuste se quiser)
gcb_ai_agent_lambda_function_name = "gcb-ai-agent-lambda"
gcb_ai_agent_lambda_role_name     = "gcb-ai-agent-lambda-role"
gcb_ai_agent_sqs_fifo_queue_name  = "gcb-ai-agent-queue.fifo"
gcb_ai_agent_sqs_dlq_queue_fifo_name = "gcb-ai-agent-dlq.fifo"

# ECR
gcb_ai_agent_ecr_repository_name = "gcb-ai-agent"

# Environment
environment = "dev"
```

### 2️⃣ Dar Permissões aos Scripts

```bash
chmod +x build-and-push.sh
chmod +x deploy-full.sh
```

### 3️⃣ Executar Deploy

```bash
./deploy-full.sh dev us-east-1
```

**Pronto!** 🎉

O script vai:
- ✅ Validar pré-requisitos
- ✅ Criar repositório ECR
- ✅ Build da imagem Docker
- ✅ Push para ECR
- ✅ Criar/atualizar infraestrutura (SQS, Lambda, IAM)
- ✅ Atualizar função Lambda

## 🔧 Deploy Manual (Passo a Passo)

### Passo 1: Inicializar Terraform e Criar ECR

```bash
cd infra/environments/dev

# Inicializar
terraform init

# Criar apenas ECR primeiro
terraform apply -target=module.gcb_ai_agent_ecr -var-file=dev.tfvars
```

### Passo 2: Build e Push da Imagem

```bash
cd ../../..  # Voltar para raiz do projeto

# Login no ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

# Build
docker build --platform linux/amd64 -t gcb-ai-agent:latest .

# Tag
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/gcb-ai-agent"
docker tag gcb-ai-agent:latest ${ECR_REPO}:latest

# Push
docker push ${ECR_REPO}:latest
```

### Passo 3: Deploy Completo com Terraform

```bash
cd infra/environments/dev

# Plan
terraform plan -var-file=dev.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

### Passo 4: Verificar Deploy

```bash
# Obter outputs
terraform output

# Testar Lambda
aws lambda invoke \
    --function-name gcb-ai-agent-lambda \
    --payload '{"test": true}' \
    response.json
```

## 🐳 Docker e ECR

### Build Local

```bash
# Build da imagem
docker build -t gcb-ai-agent:latest .

# Build para arquitetura específica
docker build --platform linux/amd64 -t gcb-ai-agent:latest .  # x86_64
docker build --platform linux/arm64 -t gcb-ai-agent:latest .  # ARM/Graviton
```

### Testes Locais

#### Usando Docker Run

```bash
docker run -it --rm \
  -e OPENAI_API_KEY="your-api-key" \
  -e AWS_ACCESS_KEY_ID="your-access-key" \
  -e AWS_SECRET_ACCESS_KEY="your-secret-key" \
  -e AWS_REGION="us-east-1" \
  -v $(pwd)/output:/app/output \
  gcb-ai-agent:latest
```

#### Usando Docker Compose (recomendado)

1. Crie um arquivo `.env` na raiz do projeto:

```bash
OPENAI_API_KEY=sk-your-key-here
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_SESSION_TOKEN=your-session-token  # Opcional
S3_BUCKET_NAME=gcb-ai-agent-bucket
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456789:topic-name  # Opcional
```

2. Execute com docker-compose:

```bash
docker-compose up

# Para rebuild após mudanças
docker-compose up --build
```

### Deploy para ECR

#### Opção 1: Script Automatizado (Recomendado)

```bash
# Dar permissão de execução
chmod +x build-and-push.sh

# Executar (usa valores padrão)
./build-and-push.sh

# Ou especificar parâmetros
./build-and-push.sh us-east-1 gcb-ai-agent v1.0.0
```

#### Opção 2: Manual

```bash
# 1. Obter Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
REPOSITORY_NAME="gcb-ai-agent"

# 2. Criar repositório ECR (se não existir)
aws ecr create-repository \
    --repository-name $REPOSITORY_NAME \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true

# 3. Login no ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 4. Build da imagem
docker build --platform linux/amd64 -t ${REPOSITORY_NAME}:latest .

# 5. Tag da imagem
docker tag ${REPOSITORY_NAME}:latest \
    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest

# 6. Push para ECR
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:latest
```

## 🔄 Atualizações

### Apenas Código da Aplicação

Se você mudou apenas o código Python (sem mudanças de infraestrutura):

```bash
# Build, push e atualiza Lambda
./build-and-push.sh us-east-1 gcb-ai-agent latest

# Ou manualmente:
docker build --platform linux/amd64 -t gcb-ai-agent:latest .
docker tag gcb-ai-agent:latest ${ECR_REPO}:latest
docker push ${ECR_REPO}:latest

# Atualizar Lambda
aws lambda update-function-code \
    --function-name gcb-ai-agent-lambda \
    --image-uri ${ECR_REPO}:latest
```

### Mudanças de Infraestrutura

Se você mudou arquivos `.tf`:

```bash
cd infra/environments/dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Deploy Completo (Código + Infra)

```bash
./deploy-full.sh dev us-east-1
```

## 🧪 Testes

### Testar Localmente com Docker

```bash
# Build
docker build -t gcb-ai-agent:latest .

# Run
docker run -it --rm \
    -e OPENAI_API_KEY="your-key" \
    -e AWS_ACCESS_KEY_ID="your-key" \
    -e AWS_SECRET_ACCESS_KEY="your-secret" \
    -v $(pwd)/output:/app/output \
    gcb-ai-agent:latest
```

### Testar Lambda na AWS

```bash
# Invocar diretamente
aws lambda invoke \
    --function-name gcb-ai-agent-lambda \
    --payload '{"Records":[{"body":"{\"file_key\":\"test.pdf\",\"contract_id\":\"123\"}"}]}' \
    response.json

# Ver logs
aws logs tail /aws/lambda/gcb-ai-agent-lambda --follow
```

### Testar via SQS

```bash
# Enviar mensagem para fila
SQS_QUEUE_URL=$(cd infra/environments/dev && terraform output -raw sqs_queue_url)

aws sqs send-message \
    --queue-url "$SQS_QUEUE_URL" \
    --message-body '{"file_key":"contracts/test.pdf","contract_id":"123"}' \
    --message-group-id "test-group" \
    --message-deduplication-id "$(date +%s)"
```

## 📊 Monitoramento

### CloudWatch Logs

```bash
# Tail dos logs
aws logs tail /aws/lambda/gcb-ai-agent-lambda --follow

# Buscar erros
aws logs filter-log-events \
    --log-group-name /aws/lambda/gcb-ai-agent-lambda \
    --filter-pattern "ERROR"
```

### CloudWatch Métricas

Acesse o console AWS e monitore:
- **Lambda**: Invocações, Erros, Duração, Throttles
- **SQS**: Mensagens Visíveis, Mensagens em Voo, DLQ
- **ECR**: Push/Pull de imagens

### Custos

Principais componentes de custo:
- Lambda: Por invocação e GB-segundo
- ECR: Armazenamento de imagens
- SQS: Por requisição
- CloudWatch: Logs e métricas

**Exemplo**: 1000 contratos/mês, 4GB, 5min cada
- **Lambda**: ~$20/mês
- **ECR**: ~$0.50/mês
- **SQS**: ~$0.01/mês
- **Total**: ~$20-25/mês

## 🐛 Troubleshooting

### Erro: "Image not found"

```bash
# Verificar se imagem existe no ECR
aws ecr describe-images \
    --repository-name gcb-ai-agent \
    --image-ids imageTag=latest
```

### Erro: "Access Denied" no ECR

```bash
# Verificar políticas do repositório
aws ecr get-repository-policy --repository-name gcb-ai-agent

# Verificar role da Lambda
aws iam get-role --role-name gcb-ai-agent-lambda-role
```

### Lambda timeout

Ajuste no `infra/modules/lambda/main.tf`:

```hcl
timeout     = 900  # 15 minutos (máximo)
memory_size = 4096 # 4GB
```

### Imagem Docker muito grande

```bash
# Verificar tamanho
docker images gcb-ai-agent:latest

# Analisar layers
docker history gcb-ai-agent:latest

# Limpar cache do Docker
docker system prune -a
```

### Lambda não consegue puxar imagem

**Causa**: Política IAM incorreta

**Solução**:
```bash
# Verificar role
aws iam get-role-policy \
    --role-name gcb-ai-agent-lambda-role \
    --policy-name gcb_ai_agent_lambda_ecr_access
```

### Imagem não atualiza

**Causa**: Lambda cache

**Solução**:
```bash
# Forçar atualização
aws lambda update-function-code \
    --function-name gcb-ai-agent-lambda \
    --image-uri $ECR_URI:latest

# Aguardar
aws lambda wait function-updated \
    --function-name gcb-ai-agent-lambda
```

### Permissões ECR

```bash
# Verifique as políticas do IAM
aws ecr get-repository-policy --repository-name gcb-ai-agent

# Adicione permissão se necessário
aws ecr set-repository-policy --repository-name gcb-ai-agent --policy-text file://policy.json
```

### Erro de dependências

```bash
# Teste localmente primeiro
docker run -it gcb-ai-agent:latest python -c "import docling; import pymupdf; import boto3"
```

## 🔐 Permissões IAM

### Lambda Execution Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/gcb-ai-agent"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::your-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:*:*:gcb-ai-agent-queue.fifo"
    },
    {
      "Effect": "Allow",
      "Action": ["sns:Publish"],
      "Resource": "arn:aws:sns:*:*:your-topic"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

## 🔧 Otimizações

### Multi-stage Build

O Dockerfile usa multi-stage build para:
- Reduzir o tamanho final da imagem
- Separar dependências de build das de runtime
- Melhorar segurança (menos ferramentas na imagem final)

### Uso do UV

- `uv` é usado para instalação rápida de dependências (10-100x mais rápido que pip)
- Compatível com `pyproject.toml` e `uv.lock`

### Dependências de Sistema

Inclui apenas as bibliotecas necessárias para runtime:
- `libmupdf-dev`: Para PyMuPDF (parsing de PDF)
- `libgl1`, `libglib2.0-0`: Para OpenCV (processamento de imagens)
- `ca-certificates`: Para conexões HTTPS (boto3/S3)

## 🎯 Próximos Passos

1. ✅ Deploy da infraestrutura base
2. ✅ Integração com S3 e SNS (se necessário)
3. ✅ Configurar alarmes no CloudWatch
4. ✅ Implementar CI/CD com GitHub Actions
5. ✅ Deploy em produção

## 📚 Recursos Adicionais

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Dúvidas?** Consulte os logs no CloudWatch ou revise o [INFRASTRUCTURE.md](./INFRASTRUCTURE.md) para detalhes técnicos.

