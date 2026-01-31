#!/bin/bash

# Azure AI RAG Demo - Bicep Deployment Script
# Based on: https://microsoftlearning.github.io/mslearn-ai-studio/Instructions/04-Use-own-data.html

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-rag-demo}"
LOCATION="${LOCATION:-swedencentral}"
DEPLOYMENT_NAME="ai-rag-demo-$(date +%Y%m%d%H%M%S)"

echo "=============================================="
echo "Azure AI RAG Demo - Bicep Deployment"
echo "=============================================="
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Deployment: $DEPLOYMENT_NAME"
echo ""
echo "=============================================="

# Check if user is logged in to Azure
echo "Checking Azure CLI login status..."
if ! az account show &>/dev/null; then
    echo "Please login to Azure first using: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")
echo "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
if [ -n "$PRINCIPAL_ID" ]; then
    echo "User Principal ID: $PRINCIPAL_ID (will be granted OpenAI access)"
fi
echo ""

# Prompt for confirmation
read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "Step 1: Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output none
echo "✓ Resource Group created: $RESOURCE_GROUP"

echo ""
echo "Step 2: Deploying Bicep template..."
echo "This may take 10-15 minutes..."
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --name $DEPLOYMENT_NAME \
    --resource-group $RESOURCE_GROUP \
    --template-file infra/main.bicep \
    --parameters infra/main.bicepparam \
    --parameters principalId="$PRINCIPAL_ID" \
    --query properties.outputs \
    --output json)

echo ""
echo "✓ Deployment completed successfully!"
echo ""

# Extract outputs
AI_HUB_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.aiHubName.value')
AI_PROJECT_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.aiProjectName.value')
OPENAI_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.openAiName.value')
OPENAI_ENDPOINT=$(echo $DEPLOYMENT_OUTPUT | jq -r '.openAiEndpoint.value')
SEARCH_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.searchName.value')
SEARCH_ENDPOINT=$(echo $DEPLOYMENT_OUTPUT | jq -r '.searchEndpoint.value')
STORAGE_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.storageName.value')

echo "=============================================="
echo "Deployment Complete!"
echo "=============================================="
echo ""
echo "Resources created:"
echo "  Resource Group:      $RESOURCE_GROUP"
echo "  AI Hub:              $AI_HUB_NAME"
echo "  AI Project:          $AI_PROJECT_NAME"
echo "  Azure OpenAI:        $OPENAI_NAME"
echo "  Azure AI Search:     $SEARCH_NAME"
echo "  Storage Account:     $STORAGE_NAME"
echo ""
echo "Endpoints:"
echo "  Azure OpenAI:        $OPENAI_ENDPOINT"
echo "  Azure AI Search:     $SEARCH_ENDPOINT"
echo ""
echo "Next Steps:"
echo "1. Go to Azure AI Studio: https://ai.azure.com"
echo "2. Select your project: $AI_PROJECT_NAME"
echo "3. Go to Playground > Chat and add your data"
echo ""
echo "To delete all resources when done:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""

# Save configuration to .env file
cat > .env << EOF
# Azure AI RAG Demo Configuration
# Generated on $(date)

RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION
AI_HUB_NAME=$AI_HUB_NAME
AI_PROJECT_NAME=$AI_PROJECT_NAME
OPENAI_NAME=$OPENAI_NAME
OPENAI_ENDPOINT=$OPENAI_ENDPOINT
SEARCH_NAME=$SEARCH_NAME
SEARCH_ENDPOINT=$SEARCH_ENDPOINT
STORAGE_NAME=$STORAGE_NAME
EOF

echo "Configuration saved to .env file"

# Ask if user wants to upload data and create index
echo ""
read -p "Do you want to upload data and create the search index now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "./setup-data.sh" ]; then
        ./setup-data.sh
    else
        echo "setup-data.sh not found. Run it manually after deployment."
    fi
fi
