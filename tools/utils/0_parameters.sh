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


# CORE_NUM=22 # 4core for monitor

# Redis_Cluster

# REDIS_SERVER_BIN="/home/homie/share/bin/clean_build/redis-server"
REDIS_SERVER_BIN="/home/homie/share/bin/copy_build/redis-server"
REDIS_CLI_BIN="/home/homie/share/bin/redis-cli"
# NODELIST="knode2"
NODELIST="knode2 knode3 knode4 knode7"
REDIS_CONF_DIR="/home/homie/share/redis/conf/instance"
BASEPORT=${ENTRY_PORT}
HG_BASEPORT=${HG_PORT}


# YCSB

# YCSB_DIR="/home/homie/share/redis/YCSB-cpp"
# YCSB_DIR="/home/homie/share/redis/YCSB-cpp_normal"
# YCSB_BIN="${YCSB_DIR}/ycsb"
TYPE="load"
WORKLOADTYPE="read"
OUTPUTDIR="/home/homie/tmp"
# CLIENT_NUM=20
# CLIENTNODES="knode4"
CLIENTNODES="knode6 knode1"
# CLIENTNODES="knode4 knode3"
SERVERNODES=${NODELIST}
BASEDIR="/home/homie/share/redis/utils"
# LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"

# Monitor
PIDSTAT_BIN=pidstat 
MONITOR_DIR="/home/homie/data/redis-monitor"
PROMETHEUS_DIR="/home/homie/share/prometheus"
EXPORTER_DIR="/home/homie/share/exporter"

# Bandwidth
# NETCARD="ens4f1"

