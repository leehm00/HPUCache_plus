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
