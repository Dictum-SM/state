#!/bin/bash -xv
####################################################################
# Be very careful when modifying anything in this box              # 
# Initialize indicies must be first                                #
declare -A DELETE_INDEX                                            #
declare -A APPLY_INDEX                                             #
                                                                   #
# Get literal dir path of the state script                         #
SOURCE="${BASH_SOURCE[0]}"                                         #
while [ -h "$SOURCE" ]; do                                         #
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )" #
  SOURCE="$(readlink "$SOURCE")"                                   #
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"                     #
done                                                               #
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"   #
                                                                   #
# Functions in lib/apply and lib/delete are added to idicies       #
source ${DIR}/lib/apply                                            #
source ${DIR}/lib/delete                                           #
source ${DIR}/lib/req                                              #
####################################################################

# Find Environment Definition

export WORKDIR=$(get-workspace)

if [ -z "${WORKDIR}" ] 
then
  echo "No Dictum initialized workspace found"
  exit 1 
fi

# Set temp workspace
TEMPDIR=$(mktemp -d -t sm-XXXXXXXXXX)

# Try to get cluster state
if get-configmap > /dev/null 2>&1
then
  get-configmap | get-pairs-stdin > ${TEMPDIR}/existing.kv 
fi

# Get Incoming
get-pairs-arg ${WORKDIR}/.state/.state > ${TEMPDIR}/incoming.kv

# Temp KV locations
EXISTING_STATE="${TEMPDIR}/existing.kv"
INCOMING_STATE="${TEMPDIR}/incoming.kv"


if [ -s ${EXISTING_STATE} ]
then
  get-deletions ${EXISTING_STATE} ${INCOMING_STATE} > ${TEMPDIR}/diff.kv
  sed -i '1!G;h;$!d' ${TEMPDIR}/diff.kv
  DIFF=${TEMPDIR}/diff.kv

  # Delete Resources
  while IFS='' read -r LINE || [ -n "${LINE}" ]
  do

    name=$(get-key "${LINE}")
    filepath=$(get-value "${LINE}")
    resource="${WORKDIR}/${filepath}"
    resource="$(envsubst <<< ${resource})"
    res_type=$(grep -o "[a-zA-Z1-9]*[\:]" <<< ${name} | sed s/\://g)
    action=$(echo ${DELETE_INDEX[$res_type]})
      
    $action $resource

  done < ${DIFF}
fi

if [[ ! -f ${WORKDIR}/.state/.state.del ]]
then
  # Apply the new state
  while IFS='' read -r LINE || [ -n "${LINE}" ]
  do

    name=$(get-key "${LINE}")
    filepath=$(get-value "${LINE}")
    resource="${WORKDIR}/${filepath}"
    resource="$(envsubst <<< ${resource})"
    res_type=$(grep -o "[a-zA-Z1-9]*[\:]" <<< $name | sed s/\://g)
    action=$(echo ${APPLY_INDEX[$res_type]})
      
    $action $resource

  done < $INCOMING_STATE
  store-state
fi

