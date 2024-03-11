#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./5_merge_instance.sh
source ./0_parameters.sh


ENTRY_IP="10.0.0.51"
ENTRY_PORT=21000
FIELDS=10
FIELDLEN=100
THREADS=5
CLIENT_NUM=10
DISTRIBUTION="zipfian"
# RECORDCOUNT=30000000
RECORDCOUNT=1000000 # 1M data for test
OPERCOUNT=500000 # for 50 client each have 0.4M total 20M * 4 = 80M
# OPERCOUNT=1000000 # for 10 client each have 10M total 100M
MACH="4"
# INS="16 32 48 64 80 96"
INS="96"
REPLICA=0
WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
WORKLOADTYPES="workloada"
REPEAT=1
HG_NUM=12
HG_PORT=21100
MAIN_INSTANCE_IP=${ENTRY_IP}
MAIN_INSTANCE_PORT=21099
LOG_NAME="Exp1_${HG_NUM}HG-${THREADS}_${CLIENT_NUM}client-test"
LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

