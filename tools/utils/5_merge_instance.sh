#!/bin/bash

source ./0_parameters.sh

getNodeNameFromIPPort() {
    ip_port=$1
    ${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | \
        grep ${ip_port} | awk '{print $1}'
}

# merge $1 to $2
mergeTwoIns() {
    src=$1
    dest=$2
    src_name=$(getNodeNameFromIPPort ${src})
    dest_name=$(getNodeNameFromIPPort ${dest})
    ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from ${src_name} --cluster-to ${dest_name}

}

doMerge() {
    POLICY_FILE=$1
    for i in $(cat ${POLICY_FILE}); do
        cmd="--cluster-to "
        to=$(echo ${i} | awk -F_ '{print $2}')
        cmd="$cmd $(getNodeNameFromIPPort $to)"
        froms=$(echo ${i} | awk -F_ '{print $1}' | tr ',' ' ')
        echo ${froms[@]} to ${to}
        for from in $froms; do
            run_cmd="$cmd --cluster-from $(getNodeNameFromIPPort ${from})"
            ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} ${run_cmd}
            # sleep 5
        done
    done
}
