# Cleanup script - Delete all Azure resources
source .env 2>/dev/null || true

if [ -z "$RESOURCE_GROUP" ]; then
    RESOURCE_GROUP="rg-ai-rag-demo"
fi

echo "This will delete the resource group: $RESOURCE_GROUP"
echo "All resources within this group will be permanently deleted."
read -p "Are you sure? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting resource group $RESOURCE_GROUP..."
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    echo "Deletion initiated. Resources will be removed in the background."
fi
