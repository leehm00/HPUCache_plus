#!/bin/bash
source /home/wangep/share/redis/utils/0_parameters.sh



monitorOneInstance() {
    node=$1
    pid=$2
    port=$3
    ssh $node "${PIDSTAT_BIN} -p ${pid} 1 9999999 > ${MONITOR_DIR}/${node}_${port}_cpu.log 2>&1" &
}


startOneNodeMonitor() {
    node=$1
    pid_list=($(ssh $node "pgrep redis-server"))
    port_list=($(ssh $node "pgrep redis-server -a | awk '{print \$3}' | awk -F: '{print \$2}'"))
    if [ ${#pid_list[@]} != ${#port_list[@]} ]; then
        echo "pidlist length != port list"
        exit
    fi
    for i in $(seq 1 ${#pid_list[@]}); do
        let index=i--
        monitorOneInstance ${node} ${pid_list[$i]} ${port_list[$i]}
    done
}

stopOneNodeMonitor() {
    node=$1
    ssh ${node} "pgrep pidstat | xargs kill -9" > /dev/null 2>&1
}

getOneNodeRedisStat() {
    node=$1
    port_list=$(ssh $node "pgrep redis-server -a | awk '{print \$3}' | awk -F: '{print \$2}'")
    for p in ${port_list}; do
        redis_stat_log=${MONITOR_DIR}/${node}_${p}_redis.log
        ssh $node "echo 'Begin' >> ${redis_stat_log};
                   ${REDIS_CLI_BIN} -p ${p} info >> ${redis_stat_log};
                   ${REDIS_CLI_BIN} -p ${p} cluster slot >> ${redis_stat_log};
                   echo 'End' >> ${redis_stat_log}  "
    done
}

startMonitor() {
    for n in ${SERVERNODES}; do
        startOneNodeMonitor $n;
    done
}

stopMonitor() {
    for n in ${SERVERNODES}; do
        stopOneNodeMonitor $n;
    done
}

getRedisStat() {
    for n in ${SERVERNODES}; do
        getOneNodeRedisStat $n;
    done
}

stopClient() {
    for n in ${CLIENTNODES}; do
        ssh $n "pgrep ycsb | xargs kill -9"
    done
}

cleanLog() {
    for n in ${CLIENTNODES}; do
        ssh $n "
        rm -rf /home/wangep/tmp/*
        rm -rf ${MONITOR_DIR}/*
        "
    done
}

# monitorOneInstance node1 283756 21002

Cmd=$1
Serverlist=$2
if [ -n "$Serverlist" ]; then
    SERVERNODES=${Serverlist}
fi

case ${Cmd} in
    startm) startMonitor ;;
    stopm) stopMonitor ;;
    startr) getRedisStat ;;
    clean) cleanLog ;;
    *) ;;
esac

