#!/bin/bash -xv

# Initialize indicies must be first
declare -A DELETE_INDEX
declare -A APPLY_INDEX

# Functions in lib/apply and lib/delete are added to idicies
source lib/apply
source lib/delete
source lib/req

# Set workspace
TEMPDIR=$(mktemp -d -t sm-XXXXXXXXXX)

# Find Environment Definition

WORKDIR=$(get-workdir)

# Try to get cluster state
if get-configmap > /dev/null 2>&1
then
  get-configmap | get-pairs-stdin > ${TEMPDIR}/existing.kv 
fi

# Get Incoming
get-pairs-arg ${WORKDIR}/.state > ${TEMPDIR}/incoming.kv

# Temp KV locations
EXISTING_STATE="${TEMPDIR}/existing.kv"
INCOMING_STATE="${TEMPDIR}/incoming.kv"


if [ -s ${EXISTING_STATE} ]
then
  get-deletions ${EXISTING_STATE} ${INCOMING_STATE} > ${TEMPDIR}/diff.kv
  DIFF=${TEMPDIR}/diff.kv

  # Delete Resources
    while IFS='' read -r LINE || [ -n "${LINE}" ]
    do

      name=$(get-key "${LINE}")
      filepath=$(get-value "${LINE}")
      resource="${WORKDIR}/${filepath}"
      res_type=$(grep -o "[a-zA-Z1-9]*[\:]" <<< $name | sed s/\://g)
      action=$(echo ${DELETE_INDEX[$res_type]})
      
      $action $resource

    done < ${DIFF}
fi

  # Apply the new state
    while IFS='' read -r LINE || [ -n "${LINE}" ]
    do

      name=$(get-key "${LINE}")
      filepath=$(get-value "${LINE}")
      resource="${WORKDIR}/${filepath}"
      res_type=$(grep -o "[a-zA-Z1-9]*[\:]" <<< $name | sed s/\://g)
      action=$(echo ${APPLY_INDEX[$res_type]})
      
      $action $resource

    done < $INCOMING_STATE

