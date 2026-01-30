# Azure AI RAG Demo

This project demonstrates how to use Azure AI Studio with your own data (Retrieval-Augmented Generation - RAG).

## Overview

This demo shows how to:
- Create Azure AI resources (AI Hub, AI Project, Azure OpenAI, Azure AI Search)
- Upload and index your own data
- Use RAG (Retrieval-Augmented Generation) to ground AI responses in your data
- Build a chat experience that answers questions based on your documents

## Prerequisites

- Azure subscription with access to Azure OpenAI
- Azure CLI installed

## Deployment Instructions

### Step 1: Login to Azure

```bash
az login --tenant <tenant-id> --use-device-code
```

Replace `<tenant-id>` with your Azure tenant ID.

### Step 2: Set Environment Variables

Configure the deployment by setting these environment variables:

```bash
# Required: Set resource group name and location
export RESOURCE_GROUP="rg-ai-rag-demo"
export LOCATION="swedencentral"
```

### Step 3: Create Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 4: Deploy Infrastructure

```bash
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file infra/main.bicep \
    --parameters infra/main.bicepparam
```

### Step 5: Get Deployment Outputs

After deployment, retrieve the resource names:

```bash
# Get all deployment outputs
az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name <deployment-name> \
    --query properties.outputs

# Or get specific values
export OPENAI_ENDPOINT=$(az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name <deployment-name> \
    --query properties.outputs.openAiEndpoint.value -o tsv)

export SEARCH_ENDPOINT=$(az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name <deployment-name> \
    --query properties.outputs.searchEndpoint.value -o tsv)

export AI_PROJECT_NAME=$(az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name <deployment-name> \
    --query properties.outputs.aiProjectName.value -o tsv)
```

### Alternative: Use the Deploy Script

You can also use the provided deployment script which handles all steps:

```bash
# Set variables (optional - defaults will be used if not set)
export RESOURCE_GROUP="rg-ai-rag-demo"
export LOCATION="swedencentral"

# Run deployment
./deploy.sh
```

## Resources Created

The deployment creates the following Azure resources:

| Resource | Description |
|----------|-------------|
| Azure AI Hub | Central hub for AI projects |
| Azure AI Project | Your working project |
| Azure OpenAI Service | With GPT-4o and text-embedding-ada-002 models |
| Azure AI Search | For vector indexing your data |
| Storage Account | For storing your documents |
| Key Vault | For secrets management |
| Application Insights | For monitoring |
| Log Analytics Workspace | For logs |

## Using the Demo

### Upload Your Data

1. Go to [Azure AI Studio](https://ai.azure.com)
2. Select your project
3. Go to **Data + indexes** > **New index**
4. Upload your data files
5. Configure the embedding model (text-embedding-ada-002)
6. Wait for indexing to complete

### Test in Playground

1. In Azure AI Studio, go to **Playground** > **Chat**
2. Click **Add your data**
3. Select your index
4. Start asking questions about your data!

## Project Structure

```
azure-ai-rag-demo/
├── README.md                    # This file
├── deploy.sh                    # Bicep deployment script
├── cleanup-resources.sh         # Script to delete all resources
├── infra/                       # Infrastructure as Code (Bicep)
│   ├── main.bicep               # Main Bicep template
│   ├── main.bicepparam          # Parameter file
│   └── modules/                 # Bicep modules
│       ├── storage.bicep        # Storage Account
│       ├── keyvault.bicep       # Key Vault
│       ├── loganalytics.bicep   # Log Analytics
│       ├── appinsights.bicep    # Application Insights
│       ├── search.bicep         # Azure AI Search
│       ├── openai.bicep         # Azure OpenAI
│       ├── aihub.bicep          # Azure AI Hub
│       └── aiproject.bicep      # Azure AI Project
└── .env                         # Created after deployment (contains config)
```

## Cleanup

To delete all Azure resources when done:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

Or use the cleanup script:

```bash
./cleanup-resources.sh
```

**Tip**: Delete the resource group after completing the demo to avoid ongoing charges.


## Troubleshooting

### Model Availability
GPT-4o and text-embedding-ada-002 availability varies by region. The deployment uses `swedencentral` by default. You can override this in `main.bicepparam`:
```bicep
using './main.bicep'

param location = 'eastus2'  // Alternative region
```

### Bicep Deployment Errors
If deployment fails, check the Azure portal for detailed error messages:
```bash
az deployment group show \
    --name <deployment-name> \
    --resource-group rg-ai-rag-demo \
    --query properties.error
```