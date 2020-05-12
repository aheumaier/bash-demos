#!/bin/bash

get_storage_key() {
  local resource_group=$1
  local storage_account=$2
  local storage_key=$(az.cmd storage account keys list -g "$resource_group" -n "$storage_account" --query [0].value -o tsv)
  if [ -z $storage_key ]; then
    echo "[ERROR]Got an empty storage key , exiting..."
    exit 1
  fi
  echo ${storage_key} # this returns to STDOUT which is insecure 
}


A=$(get_storage_key "rg-shared-dev" "devstor0987897")

# echo $A
