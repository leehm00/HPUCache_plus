#!/bin/bash
source /home/homie/share/redis/utils/0_parameters.sh

loadData() {
    echo "Load Begin"
    rc=$1
    ip=$2
    port=$3
    testmod=$4
    # keysize=$5
    # opercount=$6
    if [ -n "$testmod" ]; then
        ssh knode1 "${BASEDIR}/2_run_ycsb.sh -t load \
                   -w write -r ${rc} -o 10000000 \
                   -d uniform -s no \
                   -p fieldcount=${FIELDS} \
                   -p fieldlen=${FIELDLEN} \
                   -p ip=$ip \
                   -p port=$port "
    else
        ssh knode1 "${BASEDIR}/2_run_ycsb.sh -t load \
                   -w write -r ${rc} -o 10000000 \
                   -d uniform -s no \
                   -p fieldcount=${FIELDS} \
                   -p fieldlen=${FIELDLEN} \
                   -p ip=$ip \
                   -p port=$port "
    fi
    # echo "${BASEDIR}/2_run_ycsb.sh -t load \
    #                -w write -r ${rc} -o 10000000 \
    #                -d uniform -s no \
    #                -p fieldcount=${FIELDS} \
    #                -p fieldlen=${FIELDLEN} \
    #                -p ip=$ip \
    #                -p port=$port "
    echo "Load End"
}

keysizetokeynum() {
    keysize=$1
    case ${keysize} in
        1) echo "10000000" ;;
        2) echo "5000000" ;;
        5) echo "2000000" ;;
        10) echo "1000000" ;;
        20) echo "500000" ;;
        50) echo "200000" ;;
        100) echo "100000" ;;
        500) echo "20000" ;;
        1000) echo "10000" ;;
        200) echo "50000" ;;
        2000) echo "5000" ;;
        5000) echo "2000" ;;
        *) echo "Error" ;;
    esac
}

multiClientRun() {
    wt=$1
    oc=$2
    dis=$3
    rc=$4
    c_num=$5
    ip=$6
    port=$7
    skewed=$8
    keysize=$9
    echo "Run Begin"
    for n in ${CLIENTNODES}; do
        ssh $n "${BASEDIR}/2_run_ycsb.sh -t run \
                -w ${wt} -o ${oc} -s ${skewed} \
                -r ${rc}  -c ${c_num} -d ${dis} \
                -p thread=${THREADS} \
                -p fieldcount=${FIELDS} \
                -p fieldlen=${keysize} \
                -p ip=${ip} \
                -p port=${port} " &
    done
    ct=0
    while true ; do                     
        n1=$(ssh knode1 "pgrep ycsb")
        # n2=$(ssh knode2 "pgrep ycsb")
        # n3=$(ssh knode3 "pgrep ycsb")
        n4=$(ssh knode4 "pgrep ycsb")
        # n5=$(ssh skv-node5 "pgrep ycsb")
        n6=$(ssh knode6 "pgrep ycsb")
        # n7=$(ssh knode7 "pgrep ycsb")
        # n8=$(ssh node8 "pgrep ycsb")
        # n11=$(ssh node11 "pgrep ycsb")
        if [ ! -n "${n1}" -a \
                ! -n "${n6}"  \
             ]; then break; fi;
        # if [  ! -n "${n4}" ]; then break; fi;
        sleep 5
    done
    echo "RUN ENd"
}

moveData() {
    dirname=$1
    wlt=$2
    mkdir -p ${LOG_DIR}
    ssh knode2 "sudo chown homie ${LOG_DIR} -R"
    mkdir -p ${LOG_DIR}/${dirname}
    mkdir -p ${LOG_DIR}/${dirname}/$wlt

    redislog_dir=${LOG_DIR}/${dirname}/$wlt/redislog
    monitor_dir=${LOG_DIR}/${dirname}/$wlt/monitor
    mkdir -p ${redislog_dir}
    mkdir -p ${monitor_dir}
    for sn in $SERVERNODES; do
        ssh ${sn} "mkdir -p ${monitor_dir}/$sn; \
                   cp /home/homie/data/redis-monitor/* ${monitor_dir}/${sn}"
        ssh ${sn} "mkdir -p ${redislog_dir}/$sn; \
            cp /home/homie/data/redis-log/* ${redislog_dir}/$sn; \
            mkdir -p ${monitor_dir}/$sn; \
            cp /home/homie/data/redis-monitor/* ${monitor_dir}/${sn}"
    done

    ycsblog_dir=${LOG_DIR}/${dirname}/$wlt/ycsblog
    mkdir -p ${ycsblog_dir}
    ssh knode2 "sudo chown homie ${LOG_DIR} -R"
    for cn in $CLIENTNODES; do
        ssh ${cn} "mkdir -p ${ycsblog_dir}/$cn; \
        cp /home/homie/tmp/* ${ycsblog_dir}/$cn"
    done
    ssh knode2 "sudo chown homie ${LOG_DIR} -R"
}


run() {
    cycle=0
    while true; do
        if [ $cycle -eq ${REPEAT} ]; then break; fi
        LOG_DIR="/home/homie/share/redis/log/${LOG_NAME}"
        runWorkload
        let cycle+=1
        cp -r ${LOG_DIR} ${LOG_DIR}_${cycle}
        rm -rf ${LOG_DIR}
    done
}
