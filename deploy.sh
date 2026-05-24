#!/bin/zsh

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first."
    echo "You can install it by running: brew install azure-cli"
    exit 1
fi

# Check if user is logged in to Azure
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "You are not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Configuration
RESOURCE_GROUP="sharonjhuntington-rg"
LOCATION="westus2"
APP_NAME="sharonjhuntington"
SKU="Free"

# Create resource group if it doesn't exist
echo "Creating resource group if it doesn't exist..."
az group create --name $RESOURCE_GROUP --location "eastus"

# Create static web app if it doesn't exist
echo "Creating/updating static web app..."
az staticwebapp create \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku $SKU \

# Wait a moment for the app to be created
echo "Waiting for app creation..."
sleep 10

# Build the deployment token
echo "Deploying content..."
TOKEN=$(az staticwebapp secrets list \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query 'properties.apiKey' -o tsv)

# Deploy using the CLI from a clean empty working dir so swa doesn't
# recursively scan large folders (~/ or /tmp) looking for config files.
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="$(mktemp -d)"
echo "Deploying from $REPO_DIR (cwd: $WORK_DIR)..."
cd "$WORK_DIR"
swa deploy "$REPO_DIR" \
    --deployment-token $TOKEN \
    --env production
cd /
rm -rf "$WORK_DIR"

echo "Deployment complete! Your static web app is being deployed."
echo "You can find your deployment token in the Azure Portal or use this value:"
echo $DEPLOYMENT_TOKEN
echo "\nYour app will be available at: https://$APP_NAME.azurestaticapps.net"
