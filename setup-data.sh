#!/bin/bash

# Post-deployment script to upload data and create search index
# Run this after the Bicep deployment completes

set -e

# Source configuration if available
if [ -f .env ]; then
    source .env
fi

# Required environment variables
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-rag-demo}"

echo "=============================================="
echo "Azure AI RAG Demo - Data & Index Setup"
echo "=============================================="
echo ""

# Get resource names from deployment or environment
if [ -z "$STORAGE_NAME" ]; then
    echo "Retrieving resource names from Azure..."
    STORAGE_NAME=$(az storage account list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
fi

if [ -z "$SEARCH_NAME" ]; then
    SEARCH_NAME=$(az search service list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
fi

if [ -z "$OPENAI_NAME" ]; then
    OPENAI_NAME=$(az cognitiveservices account list --resource-group $RESOURCE_GROUP --query "[?kind=='OpenAI'].name | [0]" -o tsv)
fi

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_NAME"
echo "  Search Service: $SEARCH_NAME"
echo "  OpenAI Service: $OPENAI_NAME"
echo ""

# Get connection strings and keys
echo "Step 1: Getting credentials..."
STORAGE_CONNECTION=$(az storage account show-connection-string --name $STORAGE_NAME --resource-group $RESOURCE_GROUP --query connectionString -o tsv)
STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_NAME --resource-group $RESOURCE_GROUP --query "[0].value" -o tsv)
SEARCH_KEY=$(az search admin-key show --service-name $SEARCH_NAME --resource-group $RESOURCE_GROUP --query primaryKey -o tsv)
SEARCH_ENDPOINT="https://${SEARCH_NAME}.search.windows.net"
OPENAI_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --query properties.endpoint -o tsv)
OPENAI_KEY=$(az cognitiveservices account keys list --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --query key1 -o tsv)

echo "✓ Credentials retrieved"

# Create blob container for data
echo ""
echo "Step 2: Creating blob container..."
az storage container create \
    --name "documents" \
    --account-name $STORAGE_NAME \
    --auth-mode key \
    --account-key "$STORAGE_KEY" \
    --output none 2>/dev/null || true
echo "✓ Container 'documents' ready"

# Upload data files
echo ""
echo "Step 3: Uploading data files..."
if [ -d "data" ] && [ "$(ls -A data 2>/dev/null)" ]; then
    for file in data/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            echo "  Uploading: $filename"
            az storage blob upload \
                --container-name "documents" \
                --file "$file" \
                --name "$filename" \
                --account-name $STORAGE_NAME \
                --account-key "$STORAGE_KEY" \
                --overwrite \
                --output none
        fi
    done
    echo "✓ All files uploaded"
else
    echo "⚠ No files found in data/ folder"
fi

# Create the search index with vector configuration
echo ""
echo "Step 4: Creating search index..."

INDEX_NAME="rag-index"

# Create index schema
cat > /tmp/index-schema.json << 'EOF'
{
  "name": "rag-index",
  "fields": [
    {"name": "id", "type": "Edm.String", "key": true, "searchable": false, "filterable": true},
    {"name": "content", "type": "Edm.String", "searchable": true, "filterable": false, "sortable": false, "facetable": false, "analyzer": "standard.lucene"},
    {"name": "title", "type": "Edm.String", "searchable": true, "filterable": true, "sortable": true, "facetable": false},
    {"name": "filepath", "type": "Edm.String", "searchable": false, "filterable": true, "sortable": false, "facetable": false},
    {"name": "url", "type": "Edm.String", "searchable": false, "filterable": false, "sortable": false, "facetable": false},
    {"name": "chunk_id", "type": "Edm.String", "searchable": false, "filterable": true, "sortable": false, "facetable": false},
    {"name": "content_vector", "type": "Collection(Edm.Single)", "searchable": true, "dimensions": 1536, "vectorSearchProfile": "vector-profile"}
  ],
  "vectorSearch": {
    "algorithms": [
      {
        "name": "hnsw-algorithm",
        "kind": "hnsw",
        "hnswParameters": {
          "m": 4,
          "efConstruction": 400,
          "efSearch": 500,
          "metric": "cosine"
        }
      }
    ],
    "profiles": [
      {
        "name": "vector-profile",
        "algorithm": "hnsw-algorithm"
      }
    ]
  },
  "semantic": {
    "configurations": [
      {
        "name": "semantic-config",
        "prioritizedFields": {
          "contentFields": [{"fieldName": "content"}],
          "titleField": {"fieldName": "title"}
        }
      }
    ]
  }
}
EOF

# Create or update the index
curl -s -X PUT "${SEARCH_ENDPOINT}/indexes/${INDEX_NAME}?api-version=2024-07-01" \
    -H "Content-Type: application/json" \
    -H "api-key: ${SEARCH_KEY}" \
    -d @/tmp/index-schema.json > /dev/null

echo "✓ Search index '${INDEX_NAME}' created"

# Create data source for blob storage
echo ""
echo "Step 5: Creating data source..."

cat > /tmp/datasource.json << EOF
{
  "name": "blob-datasource",
  "type": "azureblob",
  "credentials": {
    "connectionString": "DefaultEndpointsProtocol=https;AccountName=${STORAGE_NAME};AccountKey=${STORAGE_KEY};EndpointSuffix=core.windows.net"
  },
  "container": {
    "name": "documents"
  }
}
EOF

curl -s -X PUT "${SEARCH_ENDPOINT}/datasources/blob-datasource?api-version=2024-07-01" \
    -H "Content-Type: application/json" \
    -H "api-key: ${SEARCH_KEY}" \
    -d @/tmp/datasource.json > /dev/null

echo "✓ Data source created"

# Create skillset with text splitting and embedding
echo ""
echo "Step 6: Creating skillset with embeddings..."

cat > /tmp/skillset.json << EOF
{
  "name": "embedding-skillset",
  "description": "Skillset for chunking and embedding documents",
  "skills": [
    {
      "@odata.type": "#Microsoft.Skills.Text.SplitSkill",
      "name": "split-skill",
      "description": "Split documents into chunks",
      "textSplitMode": "pages",
      "maximumPageLength": 2000,
      "pageOverlapLength": 500,
      "context": "/document",
      "inputs": [
        {"name": "text", "source": "/document/content"}
      ],
      "outputs": [
        {"name": "textItems", "targetName": "chunks"}
      ]
    },
    {
      "@odata.type": "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill",
      "name": "embedding-skill",
      "description": "Generate embeddings using Azure OpenAI",
      "resourceUri": "${OPENAI_ENDPOINT}",
      "apiKey": "${OPENAI_KEY}",
      "deploymentId": "text-embedding-ada-002",
      "modelName": "text-embedding-ada-002",
      "context": "/document/chunks/*",
      "inputs": [
        {"name": "text", "source": "/document/chunks/*"}
      ],
      "outputs": [
        {"name": "embedding", "targetName": "content_vector"}
      ]
    }
  ],
  "indexProjections": {
    "selectors": [
      {
        "targetIndexName": "${INDEX_NAME}",
        "parentKeyFieldName": "id",
        "sourceContext": "/document/chunks/*",
        "mappings": [
          {"name": "content", "source": "/document/chunks/*"},
          {"name": "content_vector", "source": "/document/chunks/*/content_vector"},
          {"name": "title", "source": "/document/metadata_storage_name"},
          {"name": "filepath", "source": "/document/metadata_storage_path"},
          {"name": "url", "source": "/document/metadata_storage_path"},
          {"name": "chunk_id", "source": "/document/chunks/*"}
        ]
      }
    ],
    "parameters": {
      "projectionMode": "generatedKeyAsId"
    }
  }
}
EOF

curl -s -X PUT "${SEARCH_ENDPOINT}/skillsets/embedding-skillset?api-version=2024-07-01" \
    -H "Content-Type: application/json" \
    -H "api-key: ${SEARCH_KEY}" \
    -d @/tmp/skillset.json > /dev/null

echo "✓ Skillset created"

# Create indexer
echo ""
echo "Step 7: Creating indexer..."

cat > /tmp/indexer.json << EOF
{
  "name": "document-indexer",
  "dataSourceName": "blob-datasource",
  "targetIndexName": "${INDEX_NAME}",
  "skillsetName": "embedding-skillset",
  "parameters": {
    "configuration": {
      "dataToExtract": "contentAndMetadata",
      "parsingMode": "default"
    }
  },
  "fieldMappings": [
    {"sourceFieldName": "metadata_storage_path", "targetFieldName": "id", "mappingFunction": {"name": "base64Encode"}}
  ]
}
EOF

curl -s -X PUT "${SEARCH_ENDPOINT}/indexers/document-indexer?api-version=2024-07-01" \
    -H "Content-Type: application/json" \
    -H "api-key: ${SEARCH_KEY}" \
    -d @/tmp/indexer.json > /dev/null

echo "✓ Indexer created"

# Run the indexer
echo ""
echo "Step 8: Running indexer..."
curl -s -X POST "${SEARCH_ENDPOINT}/indexers/document-indexer/run?api-version=2024-07-01" \
    -H "api-key: ${SEARCH_KEY}" > /dev/null

echo "✓ Indexer started"

# Clean up temp files
rm -f /tmp/index-schema.json /tmp/datasource.json /tmp/skillset.json /tmp/indexer.json

echo ""
echo "=============================================="
echo "Setup Complete!"
echo "=============================================="
echo ""
echo "Index Name: ${INDEX_NAME}"
echo "Search Endpoint: ${SEARCH_ENDPOINT}"
echo ""
echo "The indexer is now processing your documents."
echo "This may take a few minutes depending on the number of files."
echo ""
echo "To check indexer status:"
echo "  curl -s '${SEARCH_ENDPOINT}/indexers/document-indexer/status?api-version=2024-07-01' -H 'api-key: ${SEARCH_KEY}' | jq '.lastResult.status'"
echo ""
echo "Next Steps:"
echo "1. Go to Azure AI Studio: https://ai.azure.com"
echo "2. Select your project"
echo "3. Go to Playground > Chat"
echo "4. Add your data using index: ${INDEX_NAME}"
echo ""
