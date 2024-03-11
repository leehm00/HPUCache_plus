#!/bin/bash
source /home/wangep/share/redis/utils/0_parameters.sh

loadData() {
    echo "Load Begin"
    rc=$1
    testmod=$2
    if [ -n "$testmod" ]; then
        ssh node1 "${BASEDIR}/2_run_ycsb.sh -t load \
                   -w write -r ${rc} -o 10000000 \
                   -p thread=5 \
                   -p fieldcount=${FIELDS} \
                   -p fieldlen=${FIELDLEN} "
    else
        ssh node7 "${BASEDIR}/2_run_ycsb.sh -t load \
                   -w write -r ${rc} -o 10000000 \
                   -p thread=5 \
                   -p fieldcount=${FIELDS} \
                   -p fieldlen=${FIELDLEN} \
                   -p ip=${ENTRY_IP} \
                   -p port=${ENTRY_PORT} "
    fi
    echo "Load End"
}


multiClientRun() {
    wt=$1
    oc=$2
    dis=$3
    rc=$4
    c_num=$5
    echo "Run Begin"
    for n in ${CLIENTNODES}; do
        ssh $n "${BASEDIR}/2_run_ycsb.sh -t run \
                -w ${wt} -o ${oc} \
                -r ${rc}  -c ${c_num} \
                -p thread=${THREADS} \
                -p fieldcount=${FIELDS} \
                -p fieldlen=${FIELDLEN} \
                -p ip=${ENTRY_IP} \
                -p port=${ENTRY_PORT} " &
    done
    ct=0
    while true ; do
        n1=$(ssh node1 "pgrep ycsb")
        n2=$(ssh node2 "pgrep ycsb")
        n3=$(ssh node3 "pgrep ycsb")
        n4=$(ssh node4 "pgrep ycsb")
        n5=$(ssh node5 "pgrep ycsb")
        n6=$(ssh node6 "pgrep ycsb")
        n7=$(ssh node7 "pgrep ycsb")
        n8=$(ssh node8 "pgrep ycsb")
        n9=$(ssh node9 "pgrep ycsb")
        if [ ! -n "${n1}" -a ! -n "${n2}" -a \
             ! -n "${n3}" -a ! -n "${n4}" -a \
             ! -n "${n5}" -a ! -n "${n6}" -a \
             ! -n "${n7}" -a ! -n "${n8}" -a \
             ! -n "${n9}" ]; then break; fi;
        sleep 10
    done
    echo "RUN ENd"
}

moveData() {
    dirname=$1
    wlt=$2
    mkdir -p ${LOG_DIR}
    ssh node2 "sudo chown wangep ${LOG_DIR} -R"
    mkdir -p ${LOG_DIR}/${dirname}
    mkdir -p ${LOG_DIR}/${dirname}/$wlt

    redislog_dir=${LOG_DIR}/${dirname}/$wlt/redislog
    monitor_dir=${LOG_DIR}/${dirname}/$wlt/monitor
    mkdir -p ${redislog_dir}
    mkdir -p ${monitor_dir}
    for sn in $SERVERNODES; do
        ssh ${sn} "mkdir -p ${monitor_dir}/$sn; \
                   cp /home/wangep/data/redis-monitor/* ${monitor_dir}/${sn}"
        ssh ${sn} "mkdir -p ${redislog_dir}/$sn; \
            cp /home/wangep/data/redis-log/* ${redislog_dir}/$sn; \
            mkdir -p ${monitor_dir}/$sn; \
            cp /home/wangep/data/redis-monitor/* ${monitor_dir}/${sn}"
    done

    ycsblog_dir=${LOG_DIR}/${dirname}/$wlt/ycsblog
    mkdir -p ${ycsblog_dir}
    ssh node2 "sudo chown wangep ${LOG_DIR} -R"
    for cn in $CLIENTNODES; do
        ssh ${cn} "mkdir -p ${ycsblog_dir}/$cn; \
        cp /home/wangep/tmp/* ${ycsblog_dir}/$cn"
    done
    ssh node2 "sudo chown wangep ${LOG_DIR} -R"
}


run() {
    cycle=0
    while true; do
        if [ $cycle -eq ${REPEAT} ]; then break; fi
        LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
        runWorkload
        let cycle+=1
        cp -r ${LOG_DIR} ${LOG_DIR}_${cycle}
        rm -rf ${LOG_DIR}
    done
}
