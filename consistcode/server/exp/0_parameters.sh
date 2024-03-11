#!/bin/bash

# Default
# LOG_NAME="150thr-128"
# ENTRY_IP="10.0.0.51"
# ENTRY_PORT=21000
# FIELDS=1
# FIELDLEN=100
# THREADS=1
# CLIENT_NUM=80
# DISTRIBUTION="zipfian"
# RECORDCOUNT=20000000
# # RECORDCOUNT=100000000
# OPERCOUNT=10000000 # for 10 client each have 10M total 100M
# WORKLOADTYPES="read wrbalance write"
# MACH="4"
# # INS="8 16 24 32 40 48 56 64 72 80 88 96 104 112 120 128"
# INS="64"
# REPLICA=0
# REPEAT=2




# Parameter for EXP3

# # Test
# REPEAT=1
# RECORDCOUNT=100
# OPERCOUNT=100
# LOG_NAME="test"
# # WORKLOADTYPES="read wrbalance "
# WORKLOADTYPES="read "
# MACH="4"
# INS="8"
# # INS="8 "


# Public


# Redis_Cluster

# REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server-clean"
REDIS_CLI_BIN="/home/wangep/share/bin/redis-cli"
# NODELIST="node1 node4 node5 node6"
NODELIST="node2 node3 node8 node9"
# NODELIST="node2 node3 "
REDIS_CONF_DIR="/home/wangep/share/redis/conf/instance"
BASEPORT=${ENTRY_PORT}
HG_BASEPORT=${HG_PORT}


# YCSB

YCSB_DIR="/home/wangep/share/redis/YCSB-cpp"
# YCSB_DIR="/home/wangep/share/redis/YCSB-cpp_normal"
YCSB_BIN="${YCSB_DIR}/ycsb"
TYPE="load"
WORKLOAD_DIR="${YCSB_DIR}/workloads"
WORKLOADTYPE="wrbalance"
OUTPUTDIR="/home/wangep/tmp"

CLIENTNODES="n1 n4 n5 n6 n7"
SERVERNODES=${NODELIST}
BASEDIR="/home/wangep/share/redis/utils"
# LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"

# Monitor

PIDSTAT_BIN=pidstat
MONITOR_DIR="/home/wangep/data/redis-monitor"


