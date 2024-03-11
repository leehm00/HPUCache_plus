#!/bin/bash

source /home/homie/share/redis/utils/0_parameters.sh

helpMsg() {
    echo "
$0 <opts> <args>
    <opts>
    -t  YCSB Type, have two types
        load -> load data(default)
        run  -> run the workload
    -w  workload type, have three types
        write -> 100% write(update) (default)
        read  -> 100% read
        wrbalance -> 50% write(update) + 50% read
    -r  Record count, a number (default 1000000)
    -o  Operation count, a number (default 100000000)
    -d  Request Distribution, two types
        zipfian (default)
        uniform
    -p  Other Options, use -p <subopt> <args>
        <subopts>
        ip (default knode2(192.168.1.102))
        port (default 21000)
        thread (default 1)
        fieldcount (default 10)
        fieldlen (default 100)
            default value size = fieldcount * fieldlen = 1000B
    -c  Client Numbers, used with thread
        e.g.: if use 10Client and 10Thr, means have 10 Client, Each have 10 Threads
    -h  Help messages(This Message)
    "
}

runYCSB_JAVA() {
    clientid=$1
    ${YCSB_BIN} ${TYPE} redis -s -P ${WORKLOAD_DIR}/$WORKLOADTYPE \
        -p redis.host=${ENTRY_IP} \
        -p redis.port=${ENTRY_PORT} \
        -p redis.cluster=true \
        -p recordcount=${RECORDCOUNT} -p operationcount=${OPERCOUNT} \
        -p fieldlength=${FIELDLEN} -p fieldcount=$FIELDS \
        -p threadcount=${THREADS} > ${OUTPUTDIR}/${TYPE}_${WORKLOADTYPE}_${clientid}.txt 2>&1

}

runYCSB() {
    clientid=$1
    cpu_num=$2
    is_skewed=$3
    # FIELDLEN=$4
    # if [ ${is_skewed} == "yes" ]; then
    #     YCSB_DIR="/home/homie/share/redis/YCSB-cpp-skew"
    # else
        YCSB_DIR="/home/homie/share/redis/YCSB-cpp"
    # fi
    # YCSB_BIN="${YCSB_DIR}/ycsb"
    ycsbbase="/home/homie/share/redis/ycsbdir/ycsb"
    case ${is_skewed} in
        no) YCSB_BIN="${ycsbbase}01" ;;
        01) YCSB_BIN="${ycsbbase}01" ;;
        02) YCSB_BIN="${ycsbbase}02" ;;
        03) YCSB_BIN="${ycsbbase}03" ;;
        04) YCSB_BIN="${ycsbbase}04" ;;
        05) YCSB_BIN="${ycsbbase}05" ;;
        06) YCSB_BIN="${ycsbbase}06" ;;
        07) YCSB_BIN="${ycsbbase}07" ;;
        08) YCSB_BIN="${ycsbbase}08" ;;
        09) YCSB_BIN="${ycsbbase}09" ;;
        095) YCSB_BIN="${ycsbbase}095" ;;
        099) YCSB_BIN="${ycsbbase}099" ;;
        105) YCSB_BIN="${ycsbbase}105" ;;
        110) YCSB_BIN="${ycsbbase}110" ;;
        115) YCSB_BIN="${ycsbbase}115" ;;
        120) YCSB_BIN="${ycsbbase}120" ;;
        yes) YCSB_BIN="${ycsbbase}122" ;;
        130) YCSB_BIN="${ycsbbase}130" ;;
        140) YCSB_BIN="${ycsbbase}140" ;;
        150) YCSB_BIN="${ycsbbase}150" ;;
        160) YCSB_BIN="${ycsbbase}160" ;;
        170) YCSB_BIN="${ycsbbase}170" ;;
        180) YCSB_BIN="${ycsbbase}180" ;;
        190) YCSB_BIN="${ycsbbase}190" ;;
        200) YCSB_BIN="${ycsbbase}200" ;;

        *) echo "Error" ;;
    esac
    WORKLOAD_DIR="${YCSB_DIR}/workloads"
    echo ${YCSB_BIN}
    TASKSET_CMD="taskset -c ${cpu_num}"
    # echo ${TASKSET_CMD}
    if [ ${TYPE} == "load" ]; then TASKSET_CMD="";fi
    # echo "${YCSB_BIN} -${TYPE} -db redis -s -P ${WORKLOAD_DIR}/$WORKLOADTYPE \
    #     -p redis.hostport=${ENTRY_IP}:${ENTRY_PORT} \
    #     -p redis.cluster=true \
    #     -p recordcount=${RECORDCOUNT} -p operationcount=${OPERCOUNT} \
    #     -p fieldlength=${FIELDLEN} -p fieldcount=$FIELDS \
    #     -p status.interval=1 -p requestdistribution=${DISTRIBUTION}\
    #     -p threadcount=${THREADS} > \
    #     ${OUTPUTDIR}/${TYPE}_${WORKLOADTYPE}_${clientid}.txt 2>&1"
    ${TASKSET_CMD} ${YCSB_BIN} -${TYPE} -db redis -s -P ${WORKLOAD_DIR}/$WORKLOADTYPE \
        -p redis.hostport=${ENTRY_IP}:${ENTRY_PORT} \
        -p redis.cluster=true \
        -p recordcount=${RECORDCOUNT} -p operationcount=${OPERCOUNT} \
        -p fieldlength=${FIELDLEN} -p fieldcount=$FIELDS \
        -p status.interval=1 -p requestdistribution=${DISTRIBUTION}\
        -p threadcount=${THREADS} > \
        ${OUTPUTDIR}/${TYPE}_${WORKLOADTYPE}_${clientid}.txt 2>&1
}

cmdProcessing() {
    cmd_line=$1
    cmd_array=(`echo ${cmd_line} | tr '=' ' '`)
    case ${cmd_array[0]} in
        ip) ENTRY_IP=${cmd_array[1]};;
        port) ENTRY_PORT=${cmd_array[1]};;
        thread) THREADS=${cmd_array[1]};;
        fieldcount) FIELDS=${cmd_array[1]};;
        fieldlen) FIELDLEN=${cmd_array[1]};;
        *) helpMsg; exit ;;
    esac
}


while getopts 't:r:o:d:w:p:P:hT:f:F:c:s:' Cmd; do
    case $Cmd in
        t) TYPE=${OPTARG} ;;
        T) THREADS=${OPTARG} ;;
        f) FIELDLEN=${OPTARG} ;;
        F) FIELDS=${OPTARG} ;;
        r) RECORDCOUNT=${OPTARG} ;;
        o) OPERCOUNT=${OPTARG} ;;
        d) DISTRIBUTION=${OPTARG} ;;
        w) WORKLOADTYPE=${OPTARG} ;;
        c) CLIENT_NUM=${OPTARG} ;;
        s) SKEWED=${OPTARG} ;;
        p) cmdProcessing ${OPTARG} ;;
        h|?|*) helpMsg; exit;;
    esac
done

if [ ${TYPE} == "load" ]; then
    CLIENT_NUM=1
    THREADS=40
fi

cpunum=$(cat /proc/cpuinfo |grep "processor"|wc -l)
# echo  ${cpunum}
corect=0;
for i in $(seq 1 ${CLIENT_NUM}); do
    if [ ${corect} -eq ${cpunum} ]; then
        corect=0;
    fi;
    runYCSB $i ${corect} ${SKEWED} &
    let corect++;
done





