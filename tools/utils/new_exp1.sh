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
CLIENT_NUM=100
WORKLOADTYPES="workloada workloadf workloadb workloadd workloadc"
DISTRIBUTION="zipfian"
RECORDCOUNT=10000000 # 10M
OPERCOUNT=100000 # for 50 client each have 0.5M total 20M * 4 = 80M
# WORKLOADTYPES="workloadb workloadd workloadc"

DISTRIBUTION="zipfian"

MACH="4"
INS="96"
HG_NUM="3" # HG instance number

HOTSLOT="3297 1219 6555 5171 7820 13691 5139 15716 5702 8562 7279 3411 8111 5110 7703 13257 5261 12509 9304 7072 9729 6726 14962 2019 10073 3272 8677 2469 4461 6961 8847 267 14286 1440 6451 13060 10480 13905 4107 1654 10714 11000 12772 6358 1758 5826 2794 10316 2459 11712 "


# HOTSLOT="16112 5993 3468 3418 15335 9995 8905 10072 2571 1439 5459 3411 11931 15541 8791 13257 13386 1269 11427 1100"
# RECORDCOUNT=1000000 # 10M
# OPERCOUNT=50000 # for 60 client each have 0.5M total 20M * 4 = 80M
# INS="96"
# HG_NUM="1 2" # HG instance number
# WORKLOADTYPES="workloada workloadb"



runWorkload() {
    is_skew=$1
    consist=$2
    for hg in ${HG_NUM}; do
        let c_size=INS-hg
        echo ">> Create the Cluster (Scale: ${c_size})"
        buildClusterWithHG ${c_size}
        echo ">> Create Finished"
        setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} ${consist} skew
        sleep 5
        loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

        LAST_COPY_NUM=0
        for WLT in ${WORKLOADTYPES}; do
            doCopy ${c_size} ${WLT}
            sleep 5
            multiClientRun ${WLT} ${OPERCOUNT} \
                           "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
                           ${ENTRY_IP} ${ENTRY_PORT} ${is_skew}
            moveData ${hg} ${WLT}
            cleanLog
        done
        stopCluster ${MACH}
    done
}

# for i in {4..4}; do
#     LAST_COPY_NUM=0
#     LOG_NAME="2_HOT_DATA_COPY_SKEW_${i}"
#     LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
#     HG_DIR="/home/wangep/share/redis/utils/HG_skew"
#     runWorkload yes immd
# done

# LOG_NAME="2_HOT_DATA_COPY_1"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
# LOG_NAME="Hot_Copy_Perf"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
# runWorkload no

# buildClusterWithHG 95
# loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

# multiClientRun workloada ${OPERCOUNT} \
#         "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
#         ${ENTRY_IP} ${ENTRY_PORT} yes

# c_size=95
# WLT=workloada
# is_skew=no
# buildClusterWithHG 95
# loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
# doCopy ${c_size} ${WLT}

budTest() {
    c_size=$1
    buildClusterWithHG ${c_size}
    sleep 5;
    loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
    setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} immd avg
}

move() {
    LOG_NAME="9_ADDED_PERF_SKEW_0"
    LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
    moveData $1 $2
    cleanLog

}

runTest() {
    multiClientRun "workload${1}" ${OPERCOUNT} \
            ${2} ${RECORDCOUNT} ${3} \
            ${ENTRY_IP} ${ENTRY_PORT} no
}
# cp2Cl() {
# moveData 1 workloadf
# }

# HG_NUM="1 2 3"
# OPERCOUNT=10000000
# LOG_NAME="5_COPY_COST_SKEW_2"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

dataCopyCost() {
    for hg in ${HG_NUM}; do
        let c_size=INS-hg
        echo ">> Create the Cluster (Scale: ${c_size})"
        buildClusterWithHG ${c_size}
        echo ">> Create Finished"
        setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} immd skew
        sleep 5
        loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

        runTest c &
        sleep 30
        case ${hg} in
            1) num=2 ;;
            2) num=4 ;;
            3) num=6 ;;
            *) num=0 ;;
        esac
        tmp=$(date)
        echo hg:${hg} begin ${tmp} >> time.log
        copySlotRange ${c_size} 0 ${num}
        tmp=$(date)
        echo hg:${hg} finish ${tmp} >> time.log
        sleep 30;
        stopClient
        moveData ${hg} ${WLT}
        cleanLog
        stopCluster ${MACH}
    done
}

# for i in {0..3}; do
#     LOG_NAME="5_COPY_COST_SKEW${i}"
#     LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
#     dataCopyCost
# done


# for i in {10..12}; do
#     mode=immd
#     HG_DIR="/home/wangep/share/redis/utils/HG_${mode}"
#     LOG_NAME="3_CONSISTENCTY_${mode}${i}"
#     LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
#     runWorkload no ${mode}
# done



