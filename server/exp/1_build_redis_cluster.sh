#!/bin/bash

source /home/wangep/share/redis/utils/0_parameters.sh

getNodeNameFromPort() {
    ip=$1
    port=$2
    ${REDIS_CLI_BIN} -c -p ${ENTRY_PORT} -h ${ENTRY_IP} cluster nodes | grep ${ip}:${port} | awk '{print $1}'
}

getNodeNameFromSlot() {
    slot=$1
    a=$(${REDIS_CLI_BIN} -c -p ${ENTRY_PORT} -h ${ENTRY_IP} cluster getnodebyslot $1)
    # echo ${REDIS_CLI_BIN} -c -p ${ENTRY_PORT} -h ${ENTRY_IP} cluster getnodebyslot $1
    echo ${a}
}

selectNode() {
    nodenum=$1
    specify_node=$2
    n_l=(${NODELIST})
    node=${n_l[@]:0:$nodenum}
    if [ -n "${specify_node}" ]; then
        node=${specify_node}
    fi
    echo ${node[@]}
}
nodeToIP() {
    node=$1
    base="10.0.0.5"
    case ${node} in
        node1) echo "${base}1" ;;
        node2) echo "${base}2" ;;
        node3) echo "${base}3" ;;
        node4) echo "${base}4" ;;
        node5) echo "${base}5" ;;
        node6) echo "${base}6" ;;
        node7) echo "${base}7" ;;
        node8) echo "${base}8" ;;
        node9) echo "${base}9" ;;
        *) echo "Error" ;;
    esac
}
runRedisInstance() {
    nodelist=$1
    instance_num=$2
    based_port=$3
    totalnum=$4
    begin_ct=$5
    conf_dir=${REDIS_CONF_DIR}/cluster
    bct=0;
    if [ -n "${begin_ct}" ]; then
        bct=${begin_ct}
    fi
    let end_port=based_port+instance_num-1
    ct=0;
    for p in $(seq ${based_port} ${end_port}); do
        for n in $nodelist; do
            if [ $ct -eq ${totalnum} ]; then break; fi;
            echo ">> Port $p"
            conf_file=${conf_dir}/conf-${p}.conf
            ssh $n "taskset -c ${bct} ${REDIS_SERVER_BIN} ${conf_file} > /dev/null 2>&1 &"
            let ct++;
        done
        let bct++;
    done
}
stopRedisInstance() {
    nodelist=$1
    for n in ${nodelist}; do
        ssh $n "pgrep redis-server | xargs kill -9"
        echo ${n}
        ssh $n "rm -rf /home/wangep/data/redis-data/*; \
                rm -rf /home/wangep/data/redis-log/*; \
                rm -rf /home/wangep/data/redis-monitor/*; \
                rm -rf /home/wangep/tmp/*; "
    done

}

buildCluster(){
    nodenum=$1
    instancenum=$2
    replica=$3
    baseport=${ENTRY_PORT}
    nodelist=$(selectNode ${nodenum})
    let eachmach=instancenum/nodenum
    let mod=instancenum%nodenum
    if [ $mod -gt 0 ]; then let eachmach++; fi;
    let endport=baseport+eachmach-1
    runRedisInstance "$nodelist" ${eachmach} ${baseport} ${instancenum}
    sleep 5
    cluster_msg=""
    ct=0;
    for p in $(seq ${baseport} ${endport}); do
        for n in $nodelist; do
            ip=$(nodeToIP $n)
            if [ $ct -eq ${instancenum} ]; then break; fi;
            cluster_msg="$cluster_msg ${ip}:${p}"
            let ct++;
        done
    done
    echo "yes" | ${REDIS_CLI_BIN} --cluster create ${cluster_msg} --cluster-replicas ${replica}
}

stopCluster() {
    nodenum=$1
    nodelist=$(selectNode ${nodenum})
    stopRedisInstance "${nodelist}"
}

addCluster() {
    mode=$1
    nodenum=$2
    baseport=$3
    endport=$4
    nodelist=$(selectNode ${nodenum})
    for n in $nodelist; do
        ip=$(nodeToIP $n)
        for p in $(seq ${baseport} ${endport}); do
            if [ $mode == "add" ]; then
                ${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} -c cluster meet ${ip} ${p}
            elif [ $mode == "hg" ]; then
                if [ ${ip} == "${ENTRY_IP}" ] && [ ${p} -eq 21100 ]; then
                    ${REDIS_CLI_BIN} -h ${ip} -p ${p} -c cluster hotgroup add true
                else
                    ${REDIS_CLI_BIN} -h ${ip} -p ${p} -c cluster hotgroup add
                fi
            elif [ $mode == "rep" ]; then
                ${REDIS_CLI_BIN} -h ${ip} -p ${p} -c cluster replicate $(getNodeNameFromPort 51 21100)
                # echo "${REDIS_CLI_BIN} -h ${ip} -p ${p} -c cluster replicate xxx"
            fi
        done
    done
}
runHgInstance() {
    nodenum=$1
    hgnum=$2
    nodelist=$(selectNode ${nodenum})
    baseport=${HG_BASEPORT}
    let eachmach=hgnum/nodenum
    let endport=baseport+eachmach-1
    runRedisInstance "$nodelist" ${eachmach} ${baseport}

}

buildClusterWithHG() {
    nodenum=$1
    instancenum=$2
    replica=$3
    hgnum=$4
    let normal=instancenum-hgnum
    echo ${normal}
    buildCluster ${nodenum} ${normal} ${replica}
    nodelist=$(selectNode ${nodenum})
    baseport=${HG_BASEPORT}
    let eachmach=hgnum/nodenum
    let endport=baseport+eachmach-1
    runRedisInstance "$nodelist" ${eachmach} ${baseport}
    sleep 2
    addCluster "add" ${nodenum} ${baseport} ${endport}
    sleep 20
    addCluster "rep" ${nodenum} ${baseport} ${endport}
    # sleep 2
}

addHg() {
    nodenum=$1
    instancenum=$2
    replica=$3
    hgnum=$4
    baseport=${HG_BASEPORT}
    let eachmach=hgnum/nodenum
    let endport=baseport+eachmach-1
    addCluster "hg" ${nodenum} ${baseport} ${endport}

}

Cmd=$1
Nodenum=$2
Instancenum=$3
Replica=$4
Hotgroupinstancenum=$5

case $Cmd in
    bc) buildCluster ${Nodenum} ${Instancenum} ${Replica} ;;
    sc) stopCluster ${Nodenum} ;;
    bchg) buildClusterWithHG ${Nodenum} ${Instancenum} ${Replica} ${Hotgroupinstancenum} ;;
    addhg) addHg ${Nodenum} ${Instancenum} ${Replica} ${Hotgroupinstancenum} ;;
    runhgi) runHgInstance ${Nodenum} ${Hotgroupinstancenum} ;;
    addc) addCluster add ${Nodenum} 21100 21100 ;;
    *) ;;
esac
