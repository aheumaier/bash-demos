#!/bin/bash
set -u
# Test script that sets secrets for VW simulation pipeline.

export TEST_TMP_DIR=$(mktemp -d -t tmp.XXXXXXXXXX)
cleanExit() {
  rm -rf $TEST_TMP_DIR
}
trap cleanExit EXIT

# Test harness
# Args: $test_name, $got, $expected, $message
assertEquals() {
  if [ "$#" -ne 4 ]; then
      echo "Illegal number of parameters to assertEquals"
      echo 'Args: $test_name, $got, $expected, $message'
      exit 1
  fi
  printf "  $1"
  if [ "$2" != "$3" ]; then
    echo " [FAIL] $4"
    echo "    Got:"
    echo "    $2"
    echo "    Expected:"
    echo "    $3"
    exit 1
  fi
  echo " [OK]"
}

echo "Test failure modes".
echo "  Running without Devstack variables"
output=$(./set-secrets.sh)
assertEquals "Check exit code" "$?" "1" "Exit code was wrong" 
usage="Environment variables DEVSTACK_USERNAME and DEVSTACK_PASSWORD must be set." 
# assertEquals "Check usage message" "$output" "$usage" "Usage message was wrong"

echo "  Running with missing devstack variable"
output=$(DEVSTACK_USERNAME=user ./set-secrets.sh)
assertEquals "Check exit code" "$?" "1" "Exit code was wrong"
assertEquals "Check usage message" "$output" "$usage" "Usage message was wrong"

echo "  Running with missing environment variables"
expected='One or more variables from the variable group were not set.
commonAzureKeyVaultName=
simulationResultsStorageAccountName=
simulationDataStorageAccountName='
output=$(DEVSTACK_USERNAME=user DEVSTACK_PASSWORD=password ./set-secrets.sh)
assertEquals "Check exit code" "$?" "1" "Exit code was wrong"
assertEquals "Check usage message" "$output" "$expected" "Usage message was wrong"
export commonAzureKeyVaultName="commonAzureKeyVaultName"
export simulationResultsStorageAccountName="simulationResultsStorageAccountName"
output=$(DEVSTACK_USERNAME=user DEVSTACK_PASSWORD=password ./set-secrets.sh)
assertEquals "Check exit code" "$?" "1" "Exit code was wrong"
expected='One or more variables from the variable group were not set.
commonAzureKeyVaultName=commonAzureKeyVaultName
simulationResultsStorageAccountName=simulationResultsStorageAccountName
simulationDataStorageAccountName='
output=$(DEVSTACK_USERNAME=user DEVSTACK_PASSWORD=password ./set-secrets.sh)
assertEquals "Check exit code" "$?" "1" "Exit code was wrong"
assertEquals "Check usage message" "$output" "$expected" "Usage message was wrong"
unset commonAzureKeyVaultName
unset simulationResultsStorageAccountName

echo "Test az calls"
export commonAzureKeyVaultName="commonAzureKeyVaultName"
export simulationResultsStorageAccountName="simulationResultsStor"
export simulationDataStorageAccountName="simulationDataStorageAccountName"
export DEVSTACK_USERNAME="USERNAME"
# NB special characters in the password.
export DEVSTACK_PASSWORD='PA$$WORD'
# Poor man's dummy of az cli, logs all calls to a file.
az.cmd() {
  echo "az $@" >> ${TEST_TMP_DIR}/az_calls.log
  if [[ $@ == storage* ]]; then
    echo "storageKey"
  fi
}
export -f az.cmd
./set-secrets.sh > /dev/null
assertEquals "Check exit code" "$?" "0" "Exit code was wrong"
# Validate that only allowed calls were made.
expected_calls=("az storage account keys list -g rg-adp-simulation-results -n simulationResultsStor --query [0].value -o tsv" \
"az storage account keys list -g rg-adp-simulation-data -n simulationDataStorageAccountName --query [0].value -o tsv" \
"az keyvault secret set -o none --name adpresults0000001 --vault-name commonAzureKeyVaultName --value storageKey" \
"az keyvault secret set -o none --name adpdata0000001Key --vault-name commonAzureKeyVaultName --value storageKey" \
"az keyvault secret set -o none --name DevstackPW --vault-name commonAzureKeyVaultName --value PA\$\$WORD" \
"az keyvault secret set -o none --name DevstackUSER --vault-name commonAzureKeyVaultName --value USERNAME")

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" =~ "$match" ]] && return 0; done
  return 1
}
# Check each call in the logfile against the array of expected calls.
while IFS= read -r line
do
  printf "  Check az cli call against allowed list"
  # Special handling for the explicit password generation line.
  if [[ "$line" =~ 'az keyvault secret set -o none --name simulationEnvironmentPassword --vault-name commonAzureKeyVaultName --value ' ]]; then
    echo "  [OK]"
    continue
  fi
  # Special handling for the RSA key line that uses a random path.
  if [[ "$line" =~ 'az keyvault secret set -o none --name simulationprivatekey --vault-name commonAzureKeyVaultName --file' ]]; then
    echo "  [OK]"
    continue
  fi
  containsElement "$line" "${expected_calls[@]}"
  if [ $? -eq 1 ]; then
    echo " [FAIL] Unrecognized line \"$line\""
    exit 1
  fi
  echo "  [OK]"
done < "$TEST_TMP_DIR/az_calls.log"

exit 0