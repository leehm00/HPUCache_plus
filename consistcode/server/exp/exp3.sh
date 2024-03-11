#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./5_merge_instance.sh
source ./0_parameters.sh

LOG_NAME="Exp3"
ENTRY_IP="10.0.0.51"
ENTRY_PORT=27000
FIELDS=10
FIELDLEN=100
THREADS=10
CLIENT_NUM=10
DISTRIBUTION="zipfian"
RECORDCOUNT=30000000
# RECORDCOUNT=1000000 # 1M data for test
# OPERCOUNT=400000 # for 50 client each have 0.4M total 20M * 4 = 80M
OPERCOUNT=2000000 # for 10 client each have 10M total 100M
MACH="4"
INS="32 48 64 80 96"
REPLICA=0
# WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
WORKLOADTYPES="workloadb"
REPEAT=1
LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

getAverageCpuUsage() {
    cpulogfile=$1
    # cpulogfile=${LOG_DIR}/96_4/workloadb/monitor/node1/node1_21003_cpu.log
    cat $cpulogfile | awk '{print $8}' | \
        awk 'NR>10 && NR<20{print}' | \
        awk '{sum+=$0}END{print sum/NR}'
}

getHotnessFile() {
    nodenum=$1
    instancenum=$2
    wkld=$3
    rm *.log
    base=${LOG_DIR}/${instancenum}_${nodenum}_origin/${wkld}/monitor
    nodelist=$(selectNode ${nodenum})
    baseport=${ENTRY_PORT}
    let eachmach=instancenum/nodenum
    let endport=baseport+eachmach-1
    for n in $nodelist; do
        for f in $(ls ${base}/${n} | grep cpu); do
            p=$(echo ${f} | awk -F_ '{print $2}')
            echo $(nodeToIP $n):${p} $(getAverageCpuUsage ${base}/${n}/${f}) >> hotness.log
        done
    done
}

for M in $MACH; do
    for I in ${INS}; do
        buildCluster ${M} ${I} ${REPLICA}
        loadData ${RECORDCOUNT}
        for WLT in ${WORKLOADTYPES}; do

            # Run Plase for hotness dectecting
            getRedisStat
            startMonitor
            echo ${THREADS} ${CLIENT_NUM}
            multiClientRun ${WLT} ${OPERCOUNT} \
                ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
            stopMonitor
            getRedisStat
            moveData ${I}_${M}_origin ${WLT}
            cleanLog

            # merge phase
            getHotnessFile ${M} ${I} ${WLT}
            sleep 1
            ./merge.py > merge_policy
            doMerge

            # Run Phase for Opt
            getRedisStat
            startMonitor
            echo ${THREADS} ${CLIENT_NUM}
            multiClientRun ${WLT} ${OPERCOUNT} \
                ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
            stopMonitor
            getRedisStat
            moveData ${I}_${M}_opt ${WLT}
            cleanLog

        done
        stopCluster ${M}
    done
done

# getHotnessFile 4 96 workloadb

run





