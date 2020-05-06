#!/bin/bash
# 
# This script is part of the azure-pipline.yaml in src/piplines/infra 
# setting  secrets for VW simulation pipeline
# used as follows:
#  ------------------------------------------------------------------------------------------------setsec
# - stage: KeyvaultSecrets
#     displayName: Set Keyvault Secrets
#     jobs:
#       - job: KeyvaultSecrets
#         displayName: Set secrets in Keyvault
#         pool: SimulationPool
#         steps:
#           - bash: ./set-secrets-test.sh
#             workingDirectory: src/pipelines/infra
#             name: ValidateKeyvaultScript
#           - task: AzureCLI@2
#             displayName: Get Azure Credentials for Bash
#             inputs:
#               azureSubscription: '$(serviceConnection)'
#               scriptType: 'ps'
#               scriptLocation: 'inlineScript'
#               inlineScript: |
#                 $subscriptionId=$(az account show --query id -o tsv)
#                 Write-Host "##vso[task.setvariable variable=SP_ID;issecret=true]$env:servicePrincipalId"
#                 Write-Host "##vso[task.setvariable variable=SP_SECRET;issecret=true]$env:servicePrincipalKey"
#                 Write-Host "##vso[task.setvariable variable=SP_TENANT_ID]$env:tenantId"
#               addSpnToEnvironment: true
#           - task: Bash@3
#             displayName: 'Set Keyvault Secrets'
#             name: SetKeyvaultSecrets
#             inputs:
#               targetType: 'inline'
#               workingDirectory: "$(System.DefaultWorkingDirectory)/src/pipelines/infra"
#               script: az.cmd login --service-principal --username="$(SP_ID)" --password="$(SP_SECRET)" --tenant="$(SP_TENANT_ID)" && ./set-secrets.sh
#             env:
#               commonAzureKeyVaultName: $(commonAzureKeyVaultName)
#               simulationResultsStorageAccountName: $(simulationResultsStorageAccountName)
#               simulationDataStorageAccountName: $(simulationDataStorageAccountName)
#               DEVSTACK_USERNAME: $(DEVSTACK_USER)
#               DEVSTACK_PASSWORD: $(DEVSTACK_PASSWORD)
#           - task: DeleteFiles@1
#             name: RemoveBuildDirectory
#             inputs:
#               SourceFolder: $(Agent.BuildDirectory)
#               Content: "**/"
#               RemoveSourceFolder: true
#             condition: always()
#  ------------------------------------------------------------------------------------------------
# 
# Exit on any error as on unset vars
set -eu

# Names of secrets to set.
ResultsStorageKeySecretName="adpresults0000001"
DataStorageKeySecretName="adpdata0000001Key"
DeployStorageSecretName="storadpterraformKey"
SimEnvPasswordSecretName="simulationEnvironmentPassword"
SimEnvPrivateKeySecretName="simulationprivatekey"
DevstackPWSecretName="DevstackPW"
DevstackUSERSecretName="DevstackUSER"

# # This is passed by environment vars
declare -a vars=(DEVSTACK_USERNAME DEVSTACK_PASSWORD commonAzureKeyVaultName simulationResultsStorageAccountName)


# Names of resources to use.
ResultsStorageResourceGroup="rg-adp-simulation-results"
DataStorageResourceGroup="rg-adp-simulation-data"
TMP_DIR=$(mktemp -d -t tmp.XXXXXXXXXX)
SSHKeyPath="$TMP_DIR/temp.key"

# Cleanup and exit.
clean_exit() {
  rm -rf $TMP_DIR
}
trap clean_exit EXIT

if [ -z "$DEVSTACK_USERNAME" ] || [ -z "$DEVSTACK_PASSWORD" ]; then
  echo "Environment variables DEVSTACK_USERNAME and DEVSTACK_PASSWORD must be set."
  exit 1
fi

# Make sure we have all values from the variable group.
if [ -z "$commonAzureKeyVaultName" ] || [ -z "$simulationResultsStorageAccountName" ] || [ -z "$simulationDataStorageAccountName" ]; then
  echo "One or more variables from the variable group were not set."
  echo "commonAzureKeyVaultName=$commonAzureKeyVaultName"
  echo "simulationResultsStorageAccountName=$simulationResultsStorageAccountName"
  echo "simulationDataStorageAccountName=$simulationDataStorageAccountName"
  exit 1
fi

# Prevents bash-on-win from doing forced path expansion on any variables which happen to start with `/`.
# This is necessary for all the `keyvault secret set` invocations with inline secrets.
export MSYS2_ARG_CONV_EXCL="*"

# Create results key secret.
ResultStorageKey=$(az.cmd storage account keys list -g "$ResultsStorageResourceGroup" -n "$simulationResultsStorageAccountName" --query [0].value -o tsv)
if [ -z "$ResultStorageKey" ]; then
  echo "Got an empty key, exiting..."
  exit 1
fi
az.cmd keyvault secret set -o none --name "$ResultsStorageKeySecretName" --vault-name "$commonAzureKeyVaultName" --value "$ResultStorageKey"

# Create data key secret.
DataStorageKey=$(az.cmd storage account keys list -g "$DataStorageResourceGroup" -n "$simulationDataStorageAccountName" --query [0].value -o tsv)
if [ -z "$DataStorageKey" ] || [ ]; then
  echo "Got an empty key, exiting..."
  exit 1
fi
az.cmd keyvault secret set -o none --name "$DataStorageKeySecretName" --vault-name "$commonAzureKeyVaultName" --value "$DataStorageKey"

# Generate a random 32 char alphanumeric string password,
password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
# Creating sim environment password secret.
az.cmd keyvault secret set -o none --name "$SimEnvPasswordSecretName" --vault-name "$commonAzureKeyVaultName" --value "$password"

# Create Devstack password secret.
az.cmd keyvault secret set -o none --name "$DevstackPWSecretName" --vault-name "$commonAzureKeyVaultName" --value "$DEVSTACK_PASSWORD"

# Create Devstack username secret.
az.cmd keyvault secret set -o none --name "$DevstackUSERSecretName" --vault-name "$commonAzureKeyVaultName" --value "$DEVSTACK_USERNAME"

# Generate private Key for sim environments and create the secret.
unset MSYS2_ARG_CONV_EXCL # On bash-on-windows shell path expansion is necessary to use tmpdirs.
ssh-keygen -t rsa -b 2048 -f "$SSHKeyPath" -N "" -q
# Creating sim environment private key secret
az.cmd keyvault secret set -o none --name "$SimEnvPrivateKeySecretName" --vault-name "$commonAzureKeyVaultName" --file "$SSHKeyPath" --encoding 'utf-8'

echo "Done!"

exit 0
