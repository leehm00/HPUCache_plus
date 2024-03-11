#!/bin/bash

source ./1_build_redis_cluster.sh
source ./3_ycsb_client.sh
source ./4_monitor.sh

buildHGCluster() {
    nodenum=$1
    instancenum=$2
    replica=${REPLICA}
    hgnum=${HG_NUM}
    let normal=instancenum-hgnum
    echo ${normal}
    buildCluster ${nodenum} ${normal} ${replica}
    nodelist=$(selectNode ${nodenum})
    baseport=${HG_PORT}
    let eachmach=hgnum/nodenum
    let normalmach=(normal/nodenum)+1+3
    let mod=hgnum%nodenum
    if [ $mod -gt 0 ]; then let eachmach++; fi
    let endport=baseport+eachmach-1
    runRedisInstance "$nodelist" ${eachmach} ${baseport} ${hgnum} $normalmach
    # run main instance
        ssh $n "nohup ${REDIS_SERVER_BIN} ${conf_file} > /dev/null 2>&1 &"
    ssh ${MAIN_INSTANCE_NODE} "nohup ${REDIS_SERVER_BIN} ${REDIS_CONF_DIR}/cluster/conf-${MAIN_INSTANCE_PORT}.conf > /dev/null 2>&1 &"
    sleep 2
    addCluster "add" ${nodenum} ${baseport} ${endport}
    ${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} -c cluster meet ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT}
    sleep 10
    a=$(${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | wc -l)
    if [ $a -lt ${instancenum} ]; then
        echo error in build Cluster
        stopCluster ${nodenum}
        buildHGCluster ${nodenum} ${instancenum}
    fi
}


moveHotSlot() {
    base=$1
    move_num=$2
    begin=$base;
    let end=move_num+begin-1
    echo "${begin}-${end}"
    dest=$(getNodeNameFromPort ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT})
    for i in $(seq $begin $end); do
        slot=${HOTSLOT_L[i]}
        src=$(getNodeNameFromSlot $slot)
        echo "move $slot from $src to $dest"
        ${REDIS_CLI_BIN} --cluster slot ${ENTRY_IP}:${ENTRY_PORT} \
            --cluster-from ${src} \
            --cluster-to ${dest} \
            --cluster-aim-slot ${slot}
        sleep 1
        let ct++;
    done
}


setReplicaStatus() {
    cmd=$1
    nodenum=$2
    hg_num=${HG_NUM}
    based_port=${HG_PORT}
    nodelist=$(selectNode ${nodenum})

    let instance_num=hg_num/nodenum
    let mod=hg_num%nodenum
    if [ $mod -gt 0 ]; then let instance_num++; fi
    let end_port=based_port+instance_num-1

    ct=0
    for p in $(seq ${based_port} ${end_port}); do
        for n in $nodelist; do
            if [ $ct -eq ${hg_num} ]; then break; fi;
            case $cmd in
                add)
                    ${REDIS_CLI_BIN} -h $(nodeToIP ${n}) \
                        -p ${p} \
                        slaveof ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT}
                    ;;
                remove)
                    ${REDIS_CLI_BIN} -h $(nodeToIP ${n}) \
                        -p ${p} \
                        slaveof no one
                    ;;
                *);;
            esac
            let ct++;
        done

    done
}

addHG() {
    nodenum=$1
    cmd=$2
    hg_num=${HG_NUM}
    baseport=${HG_PORT}
    nodelist=$(selectNode ${nodenum})

    let instance_num=hg_num/nodenum
    let mod=hg_num%nodenum
    if [ $mod -gt 0 ]; then let instance_num++; fi
    let endport=baseport+instance_num-1

    nodelist=$(selectNode ${nodenum})

    ${REDIS_CLI_BIN} -h ${MAIN_INSTANCE_IP} -p ${MAIN_INSTANCE_PORT} -c cluster hotgroup ${cmd} true

    ct=0
    for p in $(seq ${baseport} ${endport}); do
        for n in $nodelist; do
            if [ $ct -eq ${hg_num} ]; then break; fi;
            ip=$(nodeToIP $n)
            ${REDIS_CLI_BIN} -h ${ip} -p ${p} -c cluster hotgroup ${cmd}
            let ct++;
        done
    done
}

moveSlotAdvance() {
    m=$1
    i=$2
    old_move=$3
    new_move=$4
    addHG ${m} del
    sleep 2
    echo "do move ${old_move} ${new_move}"
    moveHotSlot ${old_move} ${new_move}
    setReplicaStatus add ${m}
    sleep 20
    setReplicaStatus remove ${m}
    addHG ${m} add
    sleep 5
}

