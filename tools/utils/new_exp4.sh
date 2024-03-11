#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./7_public_func.sh
source ./8_new_public_func.sh

ENTRY_IP="10.0.0.52"
ENTRY_PORT=21000
FIELDS=10
FIELDLEN=100
THREADS=1
DISTRIBUTION="zipfian"
RECORDCOUNT=10000000
# RECORDCOUNT=1000000 # 1M data for test
OPERCOUNT=10000000
# OPERCOUNT=1000000
MACH="4"
INS="96"
REPLICA=0
WORKLOAD="workloadc"
# WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
CLIENT_NUM=100

HG_PORT=27100
MAIN_INSTANCE_NODE="n2"
MAIN_INSTANCE_IP=${ENTRY_IP}
MAIN_INSTANCE_PORT=27099
HG_NUM=2

moveOneSlot() {
    slot=$1
    to=$2
    ${REDIS_CLI_BIN} --cluster slot ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromSlot ${slot}) \
        --cluster-to $(getNodeNameFromIPPort ${to}) \
        --cluster-aim-slot ${slot}
}

normalMove() {
    from=$1
    to=$2
    ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromIPPort ${from}) \
        --cluster-to $(getNodeNameFromIPPort ${to})
}

advMove() {
    from=$1
    to=$2
    from_ip=$(echo ${from} | awk -F: '{print $1}')
    from_port=$(echo ${from} | awk -F: '{print $2}')
    to_ip=$(echo ${to} | awk -F: '{print $1}')
    to_port=$(echo ${to} | awk -F: '{print $2}')

    ${REDIS_CLI_BIN} -h ${to_ip} -p ${to_port} slaveof ${from_ip} ${from_port}
    while true ; do
        sleep 1
        a=$(${REDIS_CLI_BIN} -h ${to_ip} -p ${to_port} dbsize)
        b=$(${REDIS_CLI_BIN} -h ${from_ip} -p ${from_port} dbsize)
        if [ "$a" == "$b" ]; then
            # ${REDIS_CLI_BIN} -h ${from_ip} -p ${from_port} flushall
            ${REDIS_CLI_BIN} -h ${to_ip} -p ${to_port} slaveof no one
            break
        fi
    done

    ${REDIS_CLI_BIN} -h ${to_ip} -p ${to_port} cluster setallslot importing \
        $(getNodeNameFromIPPort $from) $(getNodeNameFromIPPort ${to})
    ${REDIS_CLI_BIN} -h ${from_ip} -p ${from_port} cluster setallslot migrating \
        $(getNodeNameFromIPPort $from) $(getNodeNameFromIPPort ${to})

    nodenum=${MACH}
    instance_num=${INS}
    based_port=${ENTRY_PORT}
    nodelist=$(selectNode ${nodenum})
    let end_port=based_port+instance_num/4-1
    echo ${based_port} ${instance_num} ${end_port}
    for p in $(seq ${based_port} ${end_port}); do
        for n in $nodelist; do
            ip=$(nodeToIP ${n})
            ${REDIS_CLI_BIN} -h ${ip} -p ${p} cluster setallslot node \
                $(getNodeNameFromIPPort $from) $(getNodeNameFromIPPort ${to})
        done
    done

}

runTest() {
    multiClientRun "workload${1}" ${OPERCOUNT} \
            "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
            ${ENTRY_IP} ${ENTRY_PORT} no
}
bdTest() {
    buildClusterWithHG 95
    # loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
    # setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} immd avg
}

run() {
    buildClusterWithHG 95
    loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
    setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} immd avg
    runTest c &
    sleep 100
    tmp=$(date)
    echo  normal begin ${tmp} >> merge_time.log
    normalMove 10.0.0.61:21001 10.0.0.61:21023
    tmp=$(date)
    echo  normal end ${tmp} >> merge_time.log
    sleep 100
    stopClient
    moveData normal workloadc
    cleanLog


    runTest c &
    sleep 100
    tmp=$(date)
    echo  adv begin ${tmp} >> merge_time.log
    advMove 10.0.0.61:21023 10.0.0.61:21001
    tmp=$(date)
    echo  adv end ${tmp} >> merge_time.log
    sleep 100
    stopClient
    moveData adv workloadc
    cleanLog

    stopCluster ${MACH}
}

# LOG_NAME="6_MERGE_TEST"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
# run

