#!/bin/bash


source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh

LOG_NAME="Baseline-1M"
ENTRY_IP="10.0.0.51"
ENTRY_PORT=27000
FIELDS=10
FIELDLEN=100
THREADS=1
CLIENT_NUM=100
DISTRIBUTION="zipfian"
# RECORDCOUNT=30000000
RECORDCOUNT=1000000 # 1M data for test
OPERCOUNT=500000 # for 50 client each have 0.4M total 20M * 4 = 80M
# OPERCOUNT=1000000 # for 10 client each have 10M total 100M
MACH="4"
INS="16 32 48 64 80 96 112 128"
REPLICA=0
WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf workloadd_mod"
REPEAT=1
LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"


runWorkload() {
    for M in $MACH; do
        for I in ${INS}; do
            buildCluster ${M} ${I} ${REPLICA}
            sleep 10
            echo "Instance num = $I"
            loadData ${RECORDCOUNT}
            sleep 5
            for WLT in ${WORKLOADTYPES}; do
                getRedisStat
                startMonitor
                echo ${THREADS} ${CLIENT_NUM}
                multiClientRun ${WLT} ${OPERCOUNT} \
                    ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
                stopMonitor
                getRedisStat
                moveData ${I}_${M} ${WLT}
                cleanLog
            done
            stopCluster ${M}
        done
    done
}

runWorkload
