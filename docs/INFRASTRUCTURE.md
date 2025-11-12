# 🏗️ Infraestrutura - GCB AI Agent

## 📁 Estrutura do Projeto

```
gcb-ai-agent/
├── Dockerfile                 # Container image para Lambda
├── docker-compose.yml         # Testes locais
├── .dockerignore             # Arquivos excluídos do build
│
├── build-and-push.sh         # Script: Build + Push ECR
├── deploy-full.sh            # Script: Deploy completo (Docker + Terraform)
│
├── lambdas/src/              # Código da aplicação
│   ├── main.py               # Handler Lambda
│   ├── pdf_parser.py         # Parser de PDF com Docling
│   ├── pyproject.toml        # Dependências Python (uv)
│   ├── uv.lock              # Lock de dependências
│   └── agents/               # Agentes de IA
│
└── infra/                    # Infraestrutura como código
    ├── modules/
    │   ├── ecr/              # ✨ NOVO: Módulo ECR
    │   │   ├── main.tf       # Repositório, políticas, lifecycle
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   ├── lambda/           # ✨ MODIFICADO: Usa container image
    │   │   ├── main.tf       # Lambda com ECR + IAM
    │   │   ├── variables.tf
    │   │   └── outputs.tf
    │   │
    │   └── sqs/              # Fila de mensagens
    │       ├── main.tf
    │       ├── variables.tf
    │       └── outputs.tf
    │
    └── environments/
        └── dev/              # ✨ MODIFICADO: Integra ECR
            ├── main.tf       # Orquestra todos os módulos
            ├── variables.tf
            └── dev.tfvars    # Valores específicos do ambiente
```

## 🔄 Fluxo de Dados

```
┌─────────────┐
│   S3 Bucket │  PDF carregado
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ SQS Queue   │  Mensagem com metadata
└──────┬──────┘
       │ (trigger)
       ▼
┌─────────────────────────────────────┐
│  Lambda Function                    │
│  ┌───────────────────────────────┐ │
│  │ Container Image (ECR)         │ │
│  │ - Docling (PDF parsing)       │ │
│  │ - PyMuPDF                     │ │
│  │ - OpenAI (extração)           │ │
│  │ - boto3 (S3/SNS)             │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
       │
       ├──> S3 (cutouts, resultados)
       │
       └──> SNS (notificações)
```

## 🧩 Módulos Terraform

### 1. Módulo ECR (`infra/modules/ecr/`)

**Responsabilidade**: Gerenciar repositório de imagens Docker

**Recursos criados**:
- `aws_ecr_repository`: Repositório privado para imagens
- `aws_ecr_lifecycle_policy`: Limpeza automática de imagens antigas
- `aws_ecr_repository_policy`: Permissões de acesso

**Configurações importantes**:
```hcl
# Scan de segurança automático
image_scanning_configuration {
  scan_on_push = true
}

# Criptografia
encryption_configuration {
  encryption_type = "AES256"
}

# Lifecycle: manter apenas 10 últimas imagens
# Remover imagens sem tag após 7 dias
```

**Outputs**:
- `gcb_ai_agent_ecr_repository_url`: URL do repositório
- `gcb_ai_agent_ecr_repository_arn`: ARN do repositório
- `gcb_ai_agent_ecr_image_uri`: URI completa (com `:latest`)

### 2. Módulo Lambda (`infra/modules/lambda/`)

**Responsabilidade**: Função serverless com container image

**Mudanças principais**:
```diff
- filename         = data.archive_file.*.output_path
- source_code_hash = data.archive_file.*.output_base64sha256
- handler          = "main.handler"
- runtime          = "python3.12"

+ package_type = "Image"
+ image_uri    = var.gcb_ai_agent_ecr_image_uri
+ timeout      = 900    # 15 minutos
+ memory_size  = 4096   # 4GB
```

**Políticas IAM adicionadas**:
```hcl
# Acesso ao ECR (novo)
resource "aws_iam_role_policy" "gcb_ai_agent_lambda_ecr_access" {
  # Permissões:
  # - ecr:GetDownloadUrlForLayer
  # - ecr:BatchGetImage
  # - ecr:BatchCheckLayerAvailability
  # - ecr:GetAuthorizationToken
}

# Acesso ao SQS (existente)
resource "aws_iam_role_policy" "gcb_ai_agent_lambda_sqs_access" {
  # ...
}
```

### 3. Módulo SQS (`infra/modules/sqs/`)

**Responsabilidade**: Fila de mensagens (trigger)

Sem mudanças - continua funcionando da mesma forma.

## 🔐 Permissões IAM

### Lambda Execution Role

Permissões necessárias:

1. **CloudWatch Logs** (via `AWSLambdaBasicExecutionRole`):
   - `logs:CreateLogGroup`
   - `logs:CreateLogStream`
   - `logs:PutLogEvents`

2. **SQS**:
   - `sqs:ReceiveMessage`
   - `sqs:DeleteMessage`
   - `sqs:GetQueueAttributes`

3. **ECR** (novo):
   - `ecr:GetDownloadUrlForLayer`
   - `ecr:BatchGetImage`
   - `ecr:BatchCheckLayerAvailability`
   - `ecr:GetAuthorizationToken`

4. **S3** (configurar separadamente):
   - `s3:GetObject`
   - `s3:PutObject`

5. **SNS** (configurar separadamente):
   - `sns:Publish`

### ECR Repository Policy

Permite:
- Lambda puxar imagens
- Usuários/roles específicos fazer push

## 🚀 Processo de Deploy

### 1️⃣ Primeira vez (Infraestrutura)

```bash
# 1. Criar ECR
cd infra/environments/dev
terraform init
terraform apply -target=module.gcb_ai_agent_ecr -var-file=dev.tfvars

# 2. Build e push da imagem
cd ../../..
./build-and-push.sh us-east-1 gcb-ai-agent latest

# 3. Deploy completo
cd infra/environments/dev
terraform apply -var-file=dev.tfvars
```

### 2️⃣ Atualizações (Código)

```bash
# Opção A: Script automatizado
./deploy-full.sh dev us-east-1

# Opção B: Manual
./build-and-push.sh us-east-1 gcb-ai-agent latest
aws lambda update-function-code \
    --function-name gcb-ai-agent-lambda \
    --image-uri $ECR_URI:latest
```

### 3️⃣ Atualizações (Infraestrutura)

```bash
cd infra/environments/dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

## 📊 Dependências entre Módulos

```
┌─────────────┐
│  ECR Module │
└──────┬──────┘
       │ (output: image_uri)
       ▼
┌──────────────────┐     ┌─────────────┐
│  Lambda Module   │◄────│ SQS Module  │
│ (depends_on ECR) │     │ (output: ARN/URL)
└──────────────────┘     └─────────────┘
```

**Ordem de criação**:
1. ECR (independente)
2. SQS (independente)
3. Lambda (depende de ECR e SQS)

## 🔧 Variáveis de Ambiente

### Build Time (Dockerfile)

```dockerfile
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
```

### Runtime (Lambda)

```hcl
environment {
  variables = {
    SQS_QUEUE_URL    = var.gcb_ai_agent_sqs_fifo_queue_url
    PYTHONUNBUFFERED = "1"
    PYTHONPATH       = "/app"
    
    # Adicionar conforme necessário:
    # OPENAI_API_KEY   = "..."
    # S3_BUCKET_NAME   = "..."
    # SNS_TOPIC_ARN    = "..."
  }
}
```

## 📈 Configurações de Performance

### Lambda

```hcl
timeout     = 900  # 15 minutos (máximo permitido)
memory_size = 4096 # 4GB (ajuste conforme necessário)
```

**Recomendações**:
- Para PDFs pequenos (< 10 páginas): 2048 MB
- Para PDFs médios (10-50 páginas): 3072 MB
- Para PDFs grandes (> 50 páginas): 4096 MB ou mais

### SQS

```hcl
visibility_timeout_seconds = 900  # Deve ser >= Lambda timeout
max_receive_count         = 3     # Tentativas antes de DLQ
```

### ECR

```hcl
# Lifecycle: Manter apenas 10 imagens taggeadas
# Remove imagens não taggeadas após 7 dias
```

## 💰 Estimativa de Custos (us-east-1)

### Lambda
- Requests: $0.20 por 1M requests
- Duration: $0.0000166667 por GB-segundo
- **Exemplo**: 1000 invocações/mês, 4GB, 300s cada
  - Custo: ~$20/mês

### ECR
- Storage: $0.10 por GB/mês
- Data Transfer: $0.09 por GB (saída)
- **Exemplo**: 5 imagens x 1GB cada
  - Custo: ~$0.50/mês

### SQS
- Requests: $0.40 por 1M requests (FIFO)
- **Exemplo**: 10k mensagens/mês
  - Custo: ~$0.004/mês

**Total estimado**: ~$20-25/mês (depende muito do uso)

## 🔍 Monitoramento

### CloudWatch Logs

```bash
# Lambda
/aws/lambda/gcb-ai-agent-lambda

# Consultar
aws logs tail /aws/lambda/gcb-ai-agent-lambda --follow
```

### CloudWatch Metrics

- **Lambda**:
  - Invocations
  - Errors
  - Duration
  - Throttles
  
- **SQS**:
  - ApproximateNumberOfMessagesVisible
  - ApproximateAgeOfOldestMessage
  
- **ECR**:
  - RepositoryPullCount
  - RepositoryImageCount

## 🚨 Troubleshooting

### Problema: Lambda não consegue puxar imagem

**Causa**: Política IAM incorreta

**Solução**:
```bash
# Verificar role
aws iam get-role-policy \
    --role-name gcb-ai-agent-lambda-role \
    --policy-name gcb_ai_agent_lambda_ecr_access
```

### Problema: Imagem não atualiza

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

### Problema: Timeout

**Causa**: Processamento lento ou memória insuficiente

**Solução**:
```hcl
# Aumentar timeout e memória
timeout     = 900
memory_size = 8192  # 8GB (se necessário)
```

## 📚 Recursos Adicionais

- [DEPLOY.md](./DEPLOY.md) - Guia completo de deploy
- [Terraform AWS Lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)

---

**Última atualização**: 2025-11-10

