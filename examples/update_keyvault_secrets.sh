#!/bin/bash
#
# This script is part of the azure-pipline.yaml in src/piplines/infra
# setting  secrets for a azure pipeline
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
#               COMMON_AZURE_KEYVAULT_NAME: $(COMMON_AZURE_KEYVAULT_NAME)
#               RESULTS_SA_NAME: $(RESULTS_SA_NAME)
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
set -eo pipefail

# Prevents bash-on-win from doing forced path expansion on any variables which happen to start with `/`.
# This is necessary for all the `keyvault secret set` invocations with inline secrets.
export MSYS2_ARG_CONV_EXCL="*"

clean_exit() {
  rm -rf "${TMP_DIR}"
}
trap clean_exit EXIT

get_storage_key() {
  local -r resource_group=$1
  local -r storage_account=$2
  local -r storage_key=$(az.cmd storage account keys list -g "${resource_group}" -n "${storage_account}" --query [0].value -o tsv)
  if [ -z "$storage_key" ] || false; then
    echo "Got an empty key, exiting..."
    exit 1
  fi
}

set_keyvault_secret() {
  local -r -r vault_name=$1
  local -r secret_name=$2
  local -r secret_value=$3
  az.cmd keyvault secret set --vault-name "${vault_name}" --name "${secret_name}" --value "${secret_value}" -o none
}

set_secret_from_storagekey() {
  local -r resource_group=$1
  local -r storage_account=$2
  local -r vault_name=$3
  local -r secret_name=$4
  local -r storage_key=$(get_storage_key "${resource_group}" "${storage_account}")
  set_keyvault_secret "${vault_name}" "${secret_name}" "${storage_key}"
}

# Generate private Key for sim environments and create the secret.
set_secret_from_sshkey() {
  local -r vault_name=$1
  local -r secret_name=$2
  unset MSYS2_ARG_CONV_EXCL # On bash-on-windows shell path expansion is necessary to use tmpdirs.
  ssh-keygen -t rsa -b 2048 -f "$SSH_KEY_PATH" -N "" -q
  az.cmd keyvault secret set --name "${secret_name}" --vault-name "${vault_name}" --file "${SSH_KEY_PATH}" --encoding 'utf-8' -o none
}

run_main() {
  # Ensure az.cmd command exists(will break on LINUX)
  command -v "az.cmd" >/dev/null || {
    echo "[ERROR]: az.cmd command not found."
    exit 1
  }
  # This is passed by environment vars - we set it readonly just to be sure 
  declare -ra required_env_vars=("${DEVSTACK_USERNAME}" "${DEVSTACK_PASSWORD}" "${COMMON_AZURE_KEYVAULT_NAME}" "${RESULTS_SA_NAME}" "${DATA_SA_NAME}")

  for var in "${required_env_vars[@]}"; do
    if [ -z "${var}" ]; then
    var_name=(${!var@})
      "Empty required env var found: $var_name. ABORT"
      exit 1
    fi
  done

  TMP_DIR=$(mktemp -d -t tmp.XXXXXXXXXX)
  SSH_KEY_PATH="$TMP_DIR/temp.key"

  # Names of resources to use. Since this is given we set it just to any random value
  local -r simenv_password_secret_same="${RANDOM}"
  local -r simenv_private_key_secret_name="${RANDOM}"
  local -r devstack_pw_secret_name="${RANDOM}"
  local -r devstack_user_secret_name="${RANDOM}"
  local -r results_storage_rg="${RANDOM}"
  local -r results_storage_key_name="${RANDOM}"
  local -r data_storage_rg="${RANDOM}"
  local -r data_storage_key_name="${RANDOM}"
  local -r deploy_storage_name="${RANDOM}"
  local -r password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

  # Create results key secret.
  set_secret_from_storagekey "$results_storage_rg" "$RESULTS_SA_NAME" "$COMMON_AZURE_KEYVAULT_NAME" "$results_storage_key_name"

  # Create data key secret.
  set_secret_from_storagekey "$data_storage_rg" -n "$DATA_SA_NAME" "$COMMON_AZURE_KEYVAULT_NAME" "$data_storage_key_name"

  # Creating sim environment password secret.
  set_keyvault_secret "$COMMON_AZURE_KEYVAULT_NAME" "$simenv_password_secret_same" "$password"

  # Create Devstack password secret.
  set_keyvault_secret "$COMMON_AZURE_KEYVAULT_NAME" "$devstack_pw_secret_name" "$DEVSTACK_PASSWORD"

  # Create Devstack username secret.
  set_keyvault_secret "$COMMON_AZURE_KEYVAULT_NAME" "$devstack_user_secret_name" "$DEVSTACK_USERNAME"

  set_secret_from_sshkey "$COMMON_AZURE_KEYVAULT_NAME" "$simenv_private_key_secret_name"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_main
fi
