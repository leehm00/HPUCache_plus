#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./7_public_func.sh

ENTRY_IP="10.0.0.52"
ENTRY_PORT=27000
FIELDS=10
FIELDLEN=100
THREADS=1
DISTRIBUTION="zipfian"
RECORDCOUNT=1000000
# RECORDCOUNT=1000000 # 1M data for test
OPERCOUNT=10000000
# OPERCOUNT=1000000
MACH="4"
INS="128"
REPLICA=0
WORKLOAD="workloadc"
# WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
CLIENT_NUM=50

MOVEINS_IP=10.0.0.53
MOVEINS_PORT=27098
REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server"

HG_PORT=27100
MAIN_INSTANCE_NODE="n2"
MAIN_INSTANCE_IP=${ENTRY_IP}
MAIN_INSTANCE_PORT=27099
HG_NUM=2

getNodeNameFromIPPort() {
    ip=$1
    port=$2
    ${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | \
        grep ${ip}:${port} | awk '{print $1}'
    }

getNodeNameFromSlot() {
    slot=$1
    ${REDIS_CLI_BIN} -c -p ${ENTRY_PORT} -h ${ENTRY_IP} cluster getnodebyslot ${slot}
}

normalMove() {
    ip=$1
    port=$2
    from_ip_port=${ip}:${port}
    ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromIPPort ${from_ip_port}) \
        --cluster-to $(getNodeNameFromIPPort ${MOVEINS_IP}:${MOVEINS_PORT})
}

moveSlotInfo() {
    fromip=$1
    fromport=$2
    toip=$3
    toport=$4
    from=${fromip}:${fromport}
    to=${toip}:${toport}
    a=$(${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | grep ${from} | awk '{print $9}')
    begin=$(echo $a | awk -F- '{print $1}')
end=$(echo $a | awk -F- '{print $2}')
to_nodename=$(${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | grep ${to} | awk '{print $1}')
echo ${to_nodename}
for i in $(seq $begin $end); do
    echo ${i}
    ${REDIS_CLI_BIN} -h ${toip} -p ${toport} cluster setslot $i importing $(getNodeNameFromIPPort $to)
    ${REDIS_CLI_BIN} -h ${fromip} -p ${fromport} cluster setslot $i migrating $(getNodeNameFromIPPort $from)
    ${REDIS_CLI_BIN} -h ${toip} -p ${toport} cluster setslot $i node $(getNodeNameFromIPPort $to)
done
}
advanceMove() {
    ip=$1
    port=$2
    from_ip_port=${ip}:${port}
    ${REDIS_CLI_BIN} -h ${MOVEINS_IP} -p ${MOVEINS_PORT} slaveof ${ip} ${port}
    while true ; do
        a=$(${REDIS_CLI_BIN} -h ${MOVEINS_IP} -p ${MOVEINS_PORT} dbsize)
        b=$(${REDIS_CLI_BIN} -h ${ip} -p ${port} dbsize)
        if [ "$a" == "$b" ]; then
            ${REDIS_CLI_BIN} -h ${ip} -p ${port} flushall
            ${REDIS_CLI_BIN} -h ${MOVEINS_IP} -p ${MOVEINS_PORT} slaveof no one
            break
        fi
        sleep 1
    done
    sleep 1
    moveSlotInfo ${ip} ${port} ${MOVEINS_IP} ${MOVEINS_PORT}
}

moveOneSlot() {
    slot=$1
    to_ip=$2
    to_port=$3
    ${REDIS_CLI_BIN} --cluster slot ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromSlot ${slot}) \
        --cluster-to $(getNodeNameFromIPPort ${to_ip} ${to_port}) \
        --cluster-aim-slot ${slot}

    }

stopClient() {
    for n in ${CLIENTNODES}; do
        ssh $n "pgrep ycsb | xargs kill -9"
    done
}

runWorkload() {
    m=$1
    ins=$2
    wlt=$3
    # getRedisStat
    # startMonitor
    echo "Run ${wlt} in CLIENT:${CLIENT_NUM} OP_NUM:${OPERCOUNT}"
    multiClientRun ${wlt} ${OPERCOUNT} \
        ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
            # stopMonitor
            # getRedisStat
        }

runTest1() {
    # buildCluster ${MACH} ${INS} 0
    # loadData ${RECORDCOUNT}
    # ssh ${MOVEINS_IP} "nohup ${REDIS_SERVER_BIN} ${REDIS_CONF_DIR}/cluster/conf-${MOVEINS_PORT}.conf > /dev/null 2>&1 &"
    # sleep 2
    # ${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} -c cluster meet ${MOVEINS_IP} ${MOVEINS_PORT}

    runWorkload ${MACH} ${INS} ${WORKLOAD} &

    sleep 30
    moveOneSlot 16112 ${MOVEINS_IP} ${MOVEINS_PORT}
    # sleep 2
    # moveOneSlot 16112 10.0.0.53 27031
    sleep 30
    stopClient
    LOG_NAME="Exp4"
    LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
    moveData "${INS}_${MACH}" ${WORKLOAD}
    cleanLog
    moveOneSlot 16112 10.0.0.53 27031
    # moveOneSlot 16112 10.0.0.53 27023
}

runTest1

runTest2() {
    # buildHGCluster ${MACH} ${INS}
    # loadData ${RECORDCOUNT}
    # setReplicaStatus add ${MACH}
    # sleep 5
    # addHG ${MACH} add
    # sleep 5

    runWorkload ${MACH} ${INS} ${WORKLOAD} &

    sleep 30
    moveOneSlot 16112 ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT}
    sleep 30
    # moveOneSlot 16112 10.0.0.53 27031
    # sleep 60
    stopClient
    LOG_NAME="Exp4-test2"
    LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
    moveData "${INS}_${MACH}" ${WORKLOAD}
    cleanLog
    # moveOneSlot 16112 10.0.0.53 27030
    # moveOneSlot 16112 10.0.0.53 27023

}

# runTest2


# buildCluster 4 96 0
# loadData ${RECORDCOUNT}

# buildCluster 4 64 0
# ${REDIS_SERVER_BIN} ${REDIS_CONF_DIR}/cluster/conf-${MOVEINS_PORT}.conf &
# ${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} -c cluster meet ${MOVEINS_IP} ${MOVEINS_PORT}
# loadData ${RECORDCOUNT}
# sleep 10

# multiClientRun workloada ${OPERCOUNT} \
#     ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM} &
# sleep 10

# echo "xxx"
# echo Begin: $(date) >> time.log
# # normalMove 10.0.0.52 21000
# advanceMove 10.0.0.52 ${ENTRY_PORT}
# echo End: $(date) >> time.log

# while true ; do
#         n5=$(ssh node5 "pgrep ycsb")
#         n6=$(ssh node6 "pgrep ycsb")
#         n7=$(ssh node7 "pgrep ycsb")
#         n8=$(ssh node8 "pgrep ycsb")
#         if [ ! -n "${n5}" -a ! -n "${n6}" -a ! -n "${n8}" -a ! -n "${n7}" ]; then break; fi;
#         sleep 10
# done

# moveData 64_4 workloada
# cp ./time.log ${LOG_DIR}
# rm ./time.log


# moveSlotInfo 10.0.0.52 21000 ${MOVEINS_IP} ${MOVEINS_PORT}




