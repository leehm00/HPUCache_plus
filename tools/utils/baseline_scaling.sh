#!/bin/bash
# scaling

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./7_public_func.sh
source ./8_new_public_func.sh
source ./10_prometheus.sh

ENTRY_IP="10.0.0.62"
ENTRY_PORT=21000
FIELDS=10
FIELDLEN=100
THREADS=1
CLIENT_NUM=200
# WORKLOADTYPES="workloada workloadc"
WORKLOADTYPES="workloada workloadf workloadb workloadd workloadc"
DISTRIBUTION="zipfian"
RECORDCOUNT=10000000 # 10M
OPERCOUNT=400000 # for 50 client epach have 0.5M total 20M * 4 = 80M
# WORKLOADTYPES="workloadb workloadd workloadc"

# DISTRIBUTION="zipfian"

MACH="4"
INS="25 50 75 100 125 150 175 200 225 250 275 300"
HG_NUM="0" # HG instance number
# 和之前的跑出来的结果是一样的，证明只要是一样的load产生的hotslot会一样
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
    ins_num=$3
    # for ins_num in ${INS};do
        for hg in ${HG_NUM}; do
            let c_size=ins_num-hg
            echo ">> Create the Cluster (Scale: ${c_size})"
            buildClusterWithHG ${c_size}
            echo ">> Create Finished"
            setAllInstanceRunMode ${MACH} ${ins_num} ${ENTRY_PORT} ${consist} skew
            sleep 5
            loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}

            LAST_COPY_NUM=0
            for WLT in ${WORKLOADTYPES}; do
                # homierodo:figure out the logic of docopy
                # sleep 20
                # doCopy ${c_size} ${WLT}
                # sleep 20
                # getRedisStat $WLT $DISTRIBUTION
                sleep 5
                startMonitor
                multiClientRun ${WLT} ${OPERCOUNT} \
                            "$DISTRIBUTION" ${RECORDCOUNT} ${CLIENT_NUM} \
                            ${ENTRY_IP} ${ENTRY_PORT} ${is_skew} 1000
                stopMonitor
                getRedisStat $WLT $DISTRIBUTION
                moveData ${hg} ${WLT}
                cleanLog
            done
            stopCluster ${MACH}
        done
    # done
}
# stopmount
# startmount
for ins_num in ${INS}; do
    LOG_NAME="scaling${ins_num}"
    LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
    HG_DIR="/home/homie/share/redis/utils/HG_no"
    runWorkload yes no ${ins_num}
done

# LOG_NAME="2_HOT_DATA_COPY_1"
# LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"

# limitall
# LOG_NAME="no_copy_96"
# LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
# runWorkload yes immd 
# stopmount
# startmount
# cancellimit
# LOG_NAME="testbase"
# LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
# HG_DIR="/home/homie/share/redis/utils/HG_no"
# runWorkload yes no

# echo ">> Create the Cluster (Scale: 96)"
# buildClusterWithHG 96
# echo ">> Create Finished"
# setAllInstanceRunMode ${MACH} ${INS} ${ENTRY_PORT} 1s skew
# sleep 5
# runprometheus 4 300 21000
# stopprometheus

# loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
# TOMSG="1 2 3 4"
# for i in $TOMSG; do
#    HG_INSTANCE="10.0.0.62:2100$i 10.0.0.61:2100${i}" 
# HG_INSTANCE="10.0.0.62:21004 10.0.0.61:21004"
# for hg_ins in ${HG_INSTANCE}; do
#         name=$(getNodeNameFromIPPort ${hg_ins});
#         echo ${name}
#         to_msg="${to_msg}${name},"
#     done
#     ${REDIS_CLI_BIN} --cluster copyone ${ENTRY_IP}:${ENTRY_PORT} \
#         --cluster-from $(getNodeNameFromSlot 3297) \
#         --cluster-to ${to_msg} \
#         --cluster-aim-slot 3297

# getRedisStat workloada zipfian
#             sleep 5
#             startMonitor
#             multiClientRun workloada ${OPERCOUNT} \
#                            "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
#                            ${ENTRY_IP} ${ENTRY_PORT} yes
#             stopMonitor
#             getRedisStat workloada zipfian
#             moveData 5 workloada
            # cleanLog
# c_size=95
# WLT=workloada
# moveData ${hg} ${WLT}
# cleanLog
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
    LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
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
# LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"

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
#     LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
#     dataCopyCost
# done


# for i in {10..12}; do
#     mode=immd
#     HG_DIR="/home/homie/share/redis/utils/HG_${mode}"
#     LOG_NAME="3_CONSISTENCTY_${mode}${i}"
#     LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
#     runWorkload no ${mode}
# done



