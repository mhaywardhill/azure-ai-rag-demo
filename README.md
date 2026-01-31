# Azure AI RAG Demo

[![Azure](https://img.shields.io/badge/Azure-AI%20Foundry-0078D4?logo=microsoft-azure)](https://ai.azure.com)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-orange)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready demonstration of **Retrieval-Augmented Generation (RAG)** using Azure AI Foundry, Azure OpenAI, and Azure AI Search. Deploy your own AI-powered chat experience that answers questions based on your documents.

![Architecture](https://learn.microsoft.com/azure/search/media/retrieval-augmented-generation-overview/architecture-diagram.png)

---

## Overview

This project provides infrastructure-as-code (Bicep) and automation scripts to:

- Deploy a complete Azure AI environment with a single command
- Automatically upload and index your PDF documents
- Create vector embeddings for semantic search
- Enable RAG-powered chat using GPT-4o grounded in your data

## Prerequisites

| Requirement | Description |
|-------------|-------------|
| **Azure Subscription** | With access to Azure OpenAI ([Request access](https://aka.ms/oai/access)) |
| **Azure CLI** | Version 2.50+ ([Install](https://learn.microsoft.com/cli/azure/install-azure-cli)) |
| **Permissions** | Contributor role on the subscription |

---

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/mhaywardhill/azure-ai-rag-demo.git
cd azure-ai-rag-demo
```

### 2. Login to Azure

```bash
az login --tenant <tenant-id> --use-device-code
```

### 3. Set Environment Variables

```bash
export RESOURCE_GROUP="rg-ai-rag-demo"
export LOCATION="swedencentral"
```

### 4. Deploy Infrastructure

```bash
# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Get your user principal ID for role assignment
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

# Deploy all Azure resources
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file infra/main.bicep \
    --parameters infra/main.bicepparam \
    --parameters principalId=$PRINCIPAL_ID
```

> **💡 Note:** The `principalId` parameter grants your user the **Cognitive Services OpenAI User** role, required to run the Python chat app.

### 5. Upload Data and Create Index

```bash
./setup-data.sh
```

> **💡 Tip:** Place your PDF files in the `data/` folder before running the setup script.

---

## Architecture

The deployment creates the following Azure resources:

```
┌────────────────────────────────────────────────────────────────┐
│                        Resource Group                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Azure AI    │    │    Azure     │    │   Azure AI   │      │
│  │     Hub      │───>│    OpenAI    │    │    Search    │      │
│  └──────────────┘    │   (GPT-4o)   │    │   (Vector)   │      │
│         |            └──────────────┘    └──────────────┘      │
│         v                                       ^              │
│  ┌──────────────┐                               |              │
│  │  AI Project  │-------------------------------+              │
│  └──────────────┘                                              │
│                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Storage    │    │  Key Vault   │    │ App Insights │      │
│  │   Account    │    │              │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

| Resource | Purpose |
|----------|---------|
| **Azure AI Hub** | Central management for AI projects and connections |
| **Azure AI Project** | Workspace for building and testing AI solutions |
| **Azure OpenAI** | GPT-4o for chat, text-embedding-ada-002 for embeddings |
| **Azure AI Search** | Vector index for semantic document search |
| **Storage Account** | Document storage for PDFs |
| **Key Vault** | Secure secrets management |
| **Application Insights** | Monitoring and diagnostics |

---

## Using the Demo

### Test in Azure AI Foundry Playground

1. Navigate to [Azure AI Foundry](https://ai.azure.com)
2. Select your project
3. Go to **Playground** → **Chat**
4. Click **Add your data** → Select `rag-index`
5. Start chatting with your documents!

### Example Questions

> *"What are the main topics covered in the documents?"*
>
> *"Summarize the key points from the travel brochures."*
>
> *"What destinations are mentioned?"*

### Run the Python Chat App

You can also run a local Python chat application that connects to your deployed Azure AI resources.

#### 1. Create Python Environment

```bash
cd chat-app
python3 -m venv labenv
source labenv/bin/activate
```

#### 2. Install Dependencies

Use the Makefile to install all required packages:

```bash
make install
```

#### 3. Set Environment Variables

Create a `.env` file in the `chat-app` directory with your Azure AI project settings:

```bash
PROJECT_ENDPOINT=https://<your-ai-project>.cognitiveservices.azure.com/
MODEL_DEPLOYMENT=gpt-4o
```

> **💡 Tip:** Find your project endpoint in Azure AI Foundry under your project's **Overview** page.

#### 4. Run the Chat App

```bash
python chat-app.py
```

Type your questions at the prompt and type `quit` to exit.

### Run the RAG App (with Azure AI Search)

The RAG app demonstrates Retrieval-Augmented Generation using Azure OpenAI with Azure AI Search as a data source.

#### 1. Create Python Environment

```bash
cd rag-app
python3 -m venv labenv
source labenv/bin/activate
```

#### 2. Install Dependencies

```bash
make install
```

#### 3. Set Environment Variables

Create a `.env` file in the `rag-app` directory or export the variables:

```bash
export OPEN_AI_ENDPOINT="https://<your-openai-resource>.openai.azure.com/"
export OPEN_AI_KEY="<your-openai-api-key>"
export CHAT_MODEL="gpt-4o"
export EMBEDDING_MODEL="text-embedding-ada-002"
export SEARCH_ENDPOINT="https://<your-search-service>.search.windows.net"
export SEARCH_KEY="<your-search-admin-key>"
export INDEX_NAME="rag-index"
```

> **💡 Tip:** Get these values from your Azure portal or use Azure CLI:
> ```bash
> # OpenAI endpoint and key
> az cognitiveservices account show --name <openai-name> --resource-group <rg> --query "properties.endpoint" -o tsv
> az cognitiveservices account keys list --name <openai-name> --resource-group <rg> --query "key1" -o tsv
> 
> # Search key
> az search admin-key show --service-name <search-name> --resource-group <rg> --query "primaryKey" -o tsv
> ```

#### 4. Run the RAG App

```bash
python rag-app.py
```

Type your questions about the indexed documents and type `quit` to exit.

---

## Project Structure

```
azure-ai-rag-demo/
├── README.md                    # Documentation
├── deploy.sh                    # Deployment automation
├── setup-data.sh                # Data upload & indexing
├── cleanup-resources.sh         # Resource cleanup
├── data/                        # Your PDF documents
├── chat-app/                    # Python chat application (AI Foundry SDK)
│   ├── chat-app.py              # Main chat application
│   ├── requirements.txt         # Python dependencies
│   ├── Makefile                 # Build automation
│   └── .env                     # Environment variables (configure)
├── rag-app/                     # RAG application (Azure OpenAI + AI Search)
│   ├── rag-app.py               # RAG chat application
│   ├── requirements.txt         # Python dependencies
│   ├── Makefile                 # Build automation
│   └── .env                     # Environment variables (configure)
├── infra/                       # Infrastructure as Code
│   ├── main.bicep               # Main orchestration
│   ├── main.bicepparam          # Parameters
│   └── modules/                 # Modular Bicep templates
│       ├── storage.bicep
│       ├── keyvault.bicep
│       ├── loganalytics.bicep
│       ├── appinsights.bicep
│       ├── search.bicep
│       ├── openai.bicep
│       ├── aihub.bicep
│       └── aiproject.bicep
└── .devcontainer/               # GitHub Codespaces config
```

---

## Cleanup

Delete all resources to avoid ongoing charges:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

---

## Troubleshooting

<details>
<summary><strong>Model availability issues</strong></summary>

GPT-4o and text-embedding-ada-002 availability varies by region. Change the location in `main.bicepparam`:

```bicep
using './main.bicep'

param location = 'eastus2'  // Try alternative regions
```

</details>

<details>
<summary><strong>Deployment errors</strong></summary>

Check detailed error messages:

```bash
az deployment group show \
    --name <deployment-name> \
    --resource-group $RESOURCE_GROUP \
    --query properties.error
```

</details>

<details>
<summary><strong>Index not showing in AI Foundry</strong></summary>

1. Verify the indexer completed: Check Azure Portal → AI Search → Indexers
2. Ensure the search connection exists in the AI Hub
3. Refresh the Azure AI Foundry page

</details>

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <sub>Built with ❤️ for the Azure community</sub>
</p>