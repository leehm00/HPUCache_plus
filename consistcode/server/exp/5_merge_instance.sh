#!/bin/bash

source ./0_parameters.sh
POLICY_FILE=merge_policy

getNodeNameFromIPPort() {
    ip_port=$1
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster nodes | \
        grep ${ip_port} | awk '{print $1}'
}

doMerge() {
    for i in $(cat ${POLICY_FILE}); do
        cmd="--cluster-to "
        to=$(echo ${i} | awk -F_ '{print $2}')
        cmd="$cmd $(getNodeNameFromIPPort $to)"
        froms=$(echo ${i} | awk -F_ '{print $1}' | tr ',' ' ')
        echo ${froms[@]} to ${to}
        for from in $froms; do
            run_cmd="$cmd --cluster-from $(getNodeNameFromIPPort ${from})"
            ${REDIS_CLI_BIN} --cluster move 10.0.0.51:21000 ${run_cmd}
            # sleep 5
        done
    done
}
