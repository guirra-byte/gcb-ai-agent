# 🤖 GCB AI Agent

Sistema de extração inteligente de informações de contratos em PDF usando IA, com rastreamento visual e deploy serverless na AWS.

## 📝 Visão Geral

Este projeto processa contratos em PDF, extrai informações estruturadas usando IA (OpenAI GPT), e fornece recortes visuais mostrando exatamente onde cada dado foi encontrado. Totalmente integrado com AWS (Lambda, ECR, SQS, S3, SNS).

### ✨ Funcionalidades Principais

- 📄 **Parsing de PDF** - Extração de texto com coordenadas precisas usando Docling
- 🤖 **Extração com IA** - Agentes Agno para encontrar informações específicas
- 🎯 **Rastreamento de Origem** - Saber exatamente de onde cada campo veio (página, bbox)
- 🖼️ **Recortes Visuais** - Imagens automáticas das regiões extraídas
- 📊 **Suporte a Tabelas** - Processa tabelas e dados estruturados complexos
- ⚡ **Scores de Confiança** - Avaliação de confiabilidade para cada extração
- ☁️ **Infraestrutura Serverless** - Deploy completo via Lambda com containers
- 📤 **Notificações SNS** - Integração automática com backend

## 🏗️ Arquitetura

```
┌─────────────┐      ┌─────────────┐      ┌──────────────────────┐
│  S3 Bucket  │─────>│  SQS Queue  │─────>│  Lambda (Container)  │
│   (PDFs)    │      │   (FIFO)    │      │  - Docling Parser    │
└─────────────┘      └─────────────┘      │  - OpenAI GPT        │
                                           │  - Image Cutouts     │
                                           └──────────┬───────────┘
                                                      │
                                           ┌──────────┴───────────┐
                                           ▼                      ▼
                                    ┌──────────┐         ┌──────────┐
                                    │    S3    │         │   SNS    │
                                    │ (Output) │         │ (Notify) │
                                    └──────────┘         └──────────┘
```

### Componentes AWS

- **ECR (Elastic Container Registry)**: Repositório Docker privado para imagens Lambda
- **Lambda**: Função serverless usando container image (até 10GB, 15min timeout)
- **SQS FIFO**: Fila de mensagens com Dead Letter Queue (DLQ)
- **S3**: Armazenamento de PDFs (input) e recortes (output)
- **SNS**: Notificações automáticas de sucesso via Lambda Destinations
- **CloudWatch**: Logs, métricas e alarmes
- **IAM**: Roles e policies para permissões granulares

## 🚀 Quick Start

### Pré-requisitos

```bash
# Verificar ferramentas instaladas
aws --version      # AWS CLI
docker --version   # Docker
terraform --version # Terraform >= 1.0.0
```

### Deploy em 3 Passos

#### 1️⃣ Configurar Variáveis

Edite o arquivo de configuração do ambiente desejado:
- **Dev**: `infra/environments/dev/dev.tfvars`
- **Prod**: `infra/environments/prod/prod.tfvars`

Exemplo de configuração (`dev.tfvars`):

```hcl
aws_region = "us-east-1"

# ARNs das roles IAM (devem existir previamente)
gcb_ai_agent_role_arn        = "arn:aws:iam::123456789:role/your-role"
gcb_ai_agent_lambda_role_arn = "arn:aws:iam::123456789:role/lambda-role"

# Nomes dos recursos
gcb_ai_agent_lambda_function_name = "gcb-ai-agent-lambda"
gcb_ai_agent_ecr_repository_name  = "gcb-ai-agent"
gcb_ai_agent_sqs_fifo_queue_name  = "gcb-ai-agent-queue.fifo"

environment = "dev"
```

#### 2️⃣ Build e Push da Imagem Docker

```bash
# O script automaticamente faz build e push para ECR
./build-and-push.sh us-east-1 gcb-ai-agent latest
```

#### 3️⃣ Provisionar Infraestrutura

```bash
# Para Dev
cd infra/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Para Prod
cd infra/environments/prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

**Ou use o script automatizado:**

```bash
# Deploy em Dev
./deploy-full.sh dev us-east-1

# Deploy em Prod
./deploy-full.sh prod us-east-1
```

**Pronto!** 🎉 O script vai criar toda a infraestrutura e fazer deploy da aplicação no ambiente escolhido.

## 📁 Estrutura do Projeto

```
gcb-ai-agent/
├── README.md                     # ← Você está aqui
├── docker-compose.yml            # Testes locais
├── build-and-push.sh             # Script: Build + Push ECR
├── deploy-full.sh                # Script: Deploy completo
│
├── lambdas/                      # ⭐ Lambda autocontida
│   ├── Dockerfile                # Container image para Lambda
│   ├── entry.sh                  # Entrypoint (local vs AWS)
│   └── src/                      # Código da aplicação
│       ├── main.py               # Handler Lambda (main.handler)
│       ├── pdf_parser.py         # Parser de PDF (Docling)
│       ├── agents/               # Agentes de IA
│       │   ├── contract_information_agent.py
│       │   └── installment_series_agent.py
│       ├── s3_provider.py        # Cliente S3
│       ├── sns_provider.py       # Cliente SNS
│       ├── pyproject.toml        # Dependências Python (uv)
│       └── uv.lock
│
├── infra/                        # Infraestrutura como código
│   ├── modules/
│   │   ├── ecr/                  # Repositório Docker
│   │   ├── lambda/               # Função Lambda + Permissions
│   │   ├── sqs/                  # Fila de mensagens + DLQ
│   │   └── sns/                  # ⭐ Tópico SNS (notificações)
│   └── environments/             # ⭐ Ambientes isolados (dev e prod)
│       ├── dev/                  # Ambiente de desenvolvimento
│       │   ├── main.tf           # Orquestração dos módulos
│       │   ├── variables.tf      # Definição de variáveis
│       │   └── dev.tfvars        # Configurações específicas do dev
│       └── prod/                 # Ambiente de produção
│           ├── main.tf           # Orquestração dos módulos
│           ├── variables.tf      # Definição de variáveis
│           └── prod.tfvars       # Configurações específicas do prod
│
└── docs/
    ├── INFRASTRUCTURE.md         # Documentação completa da arquitetura
    └── DEPLOY.md                 # Guia detalhado de deploy
```

## 🌍 Ambientes (Dev e Prod)

O projeto está estruturado com dois ambientes completamente isolados:

### 📂 Desenvolvimento (`dev`)

```bash
cd infra/environments/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

**Configurações em `dev.tfvars`:**
- Recursos com menor capacidade
- Nomes de recursos com sufixo `-dev`
- Ideal para testes e desenvolvimento

### 🚀 Produção (`prod`)

```bash
cd infra/environments/prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

**Configurações em `prod.tfvars`:**
- Recursos otimizados para produção
- Nomes de recursos com sufixo `-prod`
- Configurações de alta disponibilidade

Cada ambiente possui seu próprio:
- ✅ Arquivo `.tfvars` com variáveis específicas
- ✅ Estado Terraform isolado
- ✅ Recursos AWS independentes
- ✅ Configurações de plan e apply separadas

## 📚 Documentação

| Documento | Descrição |
|-----------|-----------|
| **[INFRASTRUCTURE.md](./docs/INFRASTRUCTURE.md)** | Arquitetura completa, módulos Terraform, configurações |
| **[DEPLOY.md](./docs/DEPLOY.md)** | Guia completo de deploy, troubleshooting, monitoramento |
| **[lambdas/src/README.md](./lambdas/src/README.md)** | Documentação da aplicação Python |

## 🔄 Atualizações

### Atualizar Código

```bash
# Desenvolvimento
./deploy-full.sh dev us-east-1

# Produção
./deploy-full.sh prod us-east-1
```

### Atualizar Infraestrutura

```bash
# Desenvolvimento
cd infra/environments/dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Produção
cd infra/environments/prod
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## 🔧 Desenvolvimento Local

### Testar com Docker

```bash
# Build local (contexto correto: lambdas/)
cd lambdas
docker build -t gcb-ai-agent:latest .

# Rodar container localmente (simula Lambda)
docker run -d --name lambda-test -p 9000:8080 gcb-ai-agent:latest

# Enviar evento de teste
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -d '{
    "Records": [{
      "body": "{\"file_key\":\"test.pdf\",\"contract_id\":\"test-123\",\"bucket_name\":\"test-bucket\"}"
    }]
  }'

# Ver logs
docker logs lambda-test

# Parar container
docker stop lambda-test && docker rm lambda-test
```

### Usar Docker Compose (alternativa)

```bash
# Na raiz do projeto
docker-compose up --build
```

### Configurar Ambiente Python

```bash
cd lambdas/src

# Instalar uv (gerenciador rápido de pacotes)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Instalar dependências
uv sync

# Rodar localmente (requer variáveis de ambiente)
export OPENAI_API_KEY="your-key"
export S3_BUCKET_NAME="test-bucket"
export SNS_TOPIC_ARN="arn:aws:sns:..."

python main.py --pdf-path /path/to/contract.pdf
```

## ✨ Funcionalidades Implementadas

- ✅ Extração de contratos com IA (OpenAI GPT-4)
- ✅ Parser de PDF com coordenadas (Docling)
- ✅ Recortes visuais automáticos
- ✅ Upload de recortes para S3
- ✅ Container image otimizado (multi-stage build)
- ✅ Lambda Destinations (SNS para sucesso)
- ✅ Dead Letter Queue (DLQ) para falhas
- ✅ CloudWatch Alarms para monitoramento
- ✅ Infraestrutura completa com Terraform
- ✅ Permissões IAM granulares
- ✅ Suporte a testes locais (Docker + RIE)

---

**Stack**: Python 3.12 + Docling + OpenAI GPT-4 + AWS Lambda (Container) + Terraform  
**Arquitetura**: Serverless (Lambda + SQS FIFO + SNS + S3 + ECR)  
**Status**: ✅ Produção  
**Última atualização**: 2025-11-11

## 🏗️ Módulos Terraform

| Módulo | Descrição | Status |
|--------|-----------|--------|
| **ECR** | Repositório Docker para imagens Lambda | ✅ |
| **Lambda** | Função serverless com container image | ✅ |
| **SQS** | Fila FIFO + Dead Letter Queue | ✅ |
| **SNS** | Notificações via Lambda Destinations | ✅ |
