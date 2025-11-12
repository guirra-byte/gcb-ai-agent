# PDF Document Information Extraction System

Extract structured information from PDF documents with AI, complete with visual cutouts showing exactly where each piece of data was found.

## Features

- 📄 **PDF Parsing** - Extract text with precise coordinates using Docling
- 🤖 **AI Extraction** - Use Agno agents to find specific information
- 🎯 **Source Tracking** - Know exactly where each field came from (page, bbox)
- 🖼️ **Visual Cutouts** - Automatically crop images from PDF at extraction locations
- 📊 **Table Support** - Handles complex tables and structured data
- ⚡ **Confidence Scores** - Get reliability ratings for each extraction
- 📤 **SNS Integration** - Automatically notify backend via AWS SNS when processing completes
- ☁️ **S3 Storage** - Upload cutouts to S3 with organized structure

## Quick Start

### Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) - Fast Python package manager

### 1. Installation

```bash
# Install uv if you haven't already
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync
```

### 2. Set API Key

Create a `.env` file:
```bash
OPENAI_API_KEY=your-key-here
```

Or export it:
```bash
export OPENAI_API_KEY=your-key-here
```

### 3. Run

```bash
uv run python main.py
```

## What It Does

1. **Parses PDF** → Extracts text chunks with coordinates
2. **AI Extraction** → Agent finds your specified fields
3. **Creates Cutouts** → Crops PDF regions showing where data came from

## Project Structure

```
gcb-ai-agent/
├── pdf_parser.py         # Docling PDF parsing
├── agent.py              # Agno AI agent
├── cutout_extractor.py   # Image cutout extraction
├── main.py               # Main pipeline
└── README.md
```

## Output

### Extraction Result (`extraction_result.json`)
```json
{
  "extracted_data": {
    "buyerName": "GABRIEL WITOR",
    "sellValue": 246090,
    "areaM2": 252.4
  },
  "sources": [
    {
      "field": "buyerName",
      "chunk_index": 0,
      "page": 1,
      "bbox": [60.3, 266.77, 571.17, 76.46],
      "text_excerpt": "Nome / Razão Social: GABRIEL WITOR..."
    }
  ],
  "confidence": {
    "buyerName": "high"
  }
}
```

### Cutout Images (`cutouts/`)
- `buyerName_chunk0_page1.png` - Visual proof of extracted buyer name
- `sellValue_chunk19_page2.png` - Visual proof of price
- etc.

### Cutout Manifest (`cutout_manifest.json`)
```json
{
  "buyerName": ["cutouts/buyerName_chunk0_page1.png"],
  "sellValue": ["cutouts/sellValue_chunk19_page2.png"]
}
```

## Customization

### Define Your Own Fields

Edit `main.py`:

```python
fields_to_extract = {
    "your_field": "Description of what to extract",
    "another_field": "Another description with hints"
}
```

### Change Model

```python
agent = DocumentAnalyzerAgent(model="gpt-4o")  # Default: gpt-4o-mini
```

### Adjust Cutout Settings

```python
cutout_paths = extractor.extract_cutouts(
    extraction_result=result,
    padding=10,      # Pixels around bbox
    scale=2.0        # Image quality (higher = better)
)
```

## How It Works

1. **Docling** parses PDF → text chunks with coordinates
2. **Agno agent** analyzes chunks → extracts your fields
3. **CutoutExtractor** crops PDF → visual evidence

## Use Cases

- ✅ Contract data extraction
- ✅ Invoice processing with visual verification
- ✅ Legal document analysis
- ✅ Form filling from scanned documents
- ✅ Compliance document review with audit trail

## SNS Integration

O sistema envia automaticamente uma notificação SNS após processar com sucesso um contrato, incluindo todos os dados extraídos e referências aos cutouts no S3.

### Configuração

Configure a variável de ambiente com o ARN do tópico SNS:

```bash
export SNS_TOPIC_ARN="arn:aws:sns:us-east-1:123456789012:contract-processing-topic"
```

### Estrutura do JSON de Notificação

```json
{
  "jobId": "contract_123_1730000000",
  "bucketName": "gcb-ai-agent-bucket",
  "status": "success",
  "processedAt": "2025-10-29T10:30:00Z",
  "units": [
    {
      "unit": {
        "unitCode": "LOTE Nº 29 QUADRA B",
        "sellValue": 287500.0,
        "buyerName": "ROGER DE SOUZA DA COSTA",
        "areaM2": 250,
        "pricePerM2": 1150.0,
        "signingDate": "2023-02-01",
        "installmentPlans": [
          {
            "totalInstallments": 3,
            "series": "CHAVES",
            "firstDueDate": "2023-02-01",
            "installmentAmount": 19166.66
          }
        ]
      },
      "sources": [
        {
          "field": "unitCode",
          "chunk_file_key": "s3://bucket/contracts/job_id/unit_0/unitCode.png"
        },
        {
          "field": "sellValue",
          "chunk_file_key": "s3://bucket/contracts/job_id/unit_0/sellValue.png"
        },
        {
          "field": "buyerName",
          "chunk_file_key": "s3://bucket/contracts/job_id/unit_0/buyerName.png"
        }
      ],
      "confidence": {
        "unitCode": "high",
        "sellValue": "high",
        "buyerName": "high"
      }
    }
  ]
}
```

### Propriedades do JSON

#### Nível Raiz
- **jobId**: Identificador único do processamento
- **bucketName**: Nome do bucket S3 onde os arquivos estão
- **status**: `"success"` ou `"error"`
- **processedAt**: Timestamp ISO 8601 UTC
- **units**: Array de unidades extraídas

#### Cada Unidade Contém

**`unit`** - Dados extraídos:
- `unitCode`: Código da unidade
- `sellValue`: Valor de venda (número)
- `buyerName`: Nome do comprador
- `areaM2`: Área em m² (número)
- `pricePerM2`: Preço por m² (número)
- `signingDate`: Data de assinatura (YYYY-MM-DD)
- `installmentPlans`: Array de planos de parcelamento

**`sources`** - Referências aos cutouts no S3:
- `field`: Nome do campo
- `chunk_file_key`: URI S3 do arquivo PNG (`null` se calculado)

**`confidence`** - Níveis de confiança:
- Valores: `"high"`, `"medium"`, `"low"`

### Estrutura de Arquivos S3

Os cutouts são organizados no S3 seguindo o padrão:

```
s3://{bucketName}/contracts/{jobId}/unit_{index}/{fieldName}.png
```

**Exemplos:**
```
s3://gcb-ai-agent-bucket/contracts/contract_123/unit_0/buyerName.png
s3://gcb-ai-agent-bucket/contracts/contract_123/unit_0/sellValue.png
s3://gcb-ai-agent-bucket/contracts/contract_123/unit_0/unitCode.png
s3://gcb-ai-agent-bucket/contracts/contract_123/unit_1/buyerName.png
```

### Comportamento

A notificação SNS é enviada quando:
- ✅ Processamento completo e bem-sucedido
- ✅ Upload de cutouts para S3 concluído
- ✅ `bucket_name` foi fornecido
- ✅ `SNS_TOPIC_ARN` está configurado

A notificação **NÃO** é enviada quando:
- ❌ `SNS_TOPIC_ARN` não configurado
- ❌ `bucket_name` não fornecido
- ❌ Upload S3 falhou
- ❌ Erro no processamento

### Arquivo Local de Debug

Independente do envio SNS, o payload sempre é salvo localmente:
```
output/merged_notification_payload.json
```

### Permissões IAM Necessárias

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["sns:Publish"],
      "Resource": "arn:aws:sns:us-east-1:123456789012:contract-processing-topic"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::gcb-ai-agent-bucket/*"
    }
  ]
}
```

### Exemplo de Consumo (Python)

```python
import json

def process_sns_notification(event, context):
    for record in event['Records']:
        message = json.loads(record['Sns']['Message'])
        
        job_id = message['jobId']
        units = message['units']
        
        for unit in units:
            # Salvar dados no banco
            save_to_database(unit['unit'])
            
            # Processar cutouts
            for source in unit['sources']:
                if source['chunk_file_key']:
                    # Fazer algo com a imagem S3
                    process_cutout(source['chunk_file_key'])
```