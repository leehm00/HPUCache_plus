#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./5_merge_instance.sh
source ./7_public_func.sh
source ./8_new_public_func.sh

ENTRY_IP="10.0.0.52"
ENTRY_PORT=21000
FIELDS=10
FIELDLEN=100
THREADS=1
CLIENT_NUM=100
WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
DISTRIBUTION="zipfian"
RECORDCOUNT=10000000 # 10M
OPERCOUNT=300000 # for 50 client each have 0.5M total 20M * 4 = 80M

MACH="4"
INS="96"
HG_NUM="1 2 3" # HG instance number
IS_SKEW="yes"

HOTSLOT="3297 1219 6555 5171 7820 13691 5139 15716 5702 8562 7279 3411 8111 5110 7703 13257 5261 12509 9304 7072 9729 6726 14962 2019 10073 3272 8677 2469 4461 6961 8847 267 14286 1440 6451 13060 10480 13905 4107 1654 10714 11000 12772 6358 1758 5826 2794 10316 2459 11712 "


LOG_NAME="Exp3-skew"
LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

buildClusterWithHG 96
sleep 5
loadData ${RECORDCOUNT} ${ENTRY_IP} ${ENTRY_PORT}
sleep 5

# normal run phase
for wlt in ${WORKLOADTYPES}; do
    startMonitor
    multiClientRun ${wlt} ${OPERCOUNT} \
             "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
             ${ENTRY_IP} ${ENTRY_PORT} ${IS_SKEW}
    stopMonitor
    moveData zipfian ${wlt}
    cleanLog
done

for wlt in ${WORKLOADTYPES}; do
    getHotnessFile zipfian ${wlt}
    ./merge.py > merge_policy_${wlt}
done
# merge phase

doMerge merge_policy_workloadb

# advance phase

for wlt in ${WORKLOADTYPES}; do
    startMonitor
    multiClientRun ${wlt} ${OPERCOUNT} \
             "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
             ${ENTRY_IP} ${ENTRY_PORT} ${IS_SKEW}
    stopMonitor
    moveData zipfian_opt ${wlt}
    cleanLog
done


# runSingle() {
#     for wlt in ${WORKLOADTYPES}; do
#         startMonitor
#         echo run ${wlt}
#         multiClientRun ${WLT} ${OPERCOUNT} \
#                  "zipfian" ${RECORDCOUNT} ${CLIENT_NUM} \
#                  ${ENTRY_IP} ${ENTRY_PORT} ${IS_SKEW}
#     done

# }


