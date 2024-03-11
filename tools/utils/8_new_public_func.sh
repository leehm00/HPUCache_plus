#!/bin/bash
source ./0_parameters.sh
source ./1_build_redis_cluster.sh
source ./3_ycsb_client.sh
source ./4_monitor.sh


buildClusterWithHG() {
    c_size=$1
    HG_INSTANCE=$(getHGInsInfo ${MACH} ${INS} ${c_size} ${ENTRY_PORT})
    echo "> Build Cluster(Size: ${c_size})"
    buildCluster ${MACH} ${INS} ${c_size} ${ENTRY_PORT}
    echo "> Build Fin"
    echo "> Create HG Ins ..."
    for hg_ins in ${HG_INSTANCE}; do
        echo ">> add instance ${hg_ins} to group"
        ip=$(echo ${hg_ins} | awk -F: '{print $1}')
        port=$(echo ${hg_ins} | awk -F: '{print $2}')
        ${REDIS_CLI_BIN} -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster meet ${ip} ${port}
    done
}
copyOneSlot() {
    slot=$1
    c_size=$2
    to_msg=""
    HG_INSTANCE=$(getHGInsInfo ${MACH} ${INS} ${c_size} ${ENTRY_PORT})
    for hg_ins in ${HG_INSTANCE}; do
        name=$(getNodeNameFromIPPort ${hg_ins});
        echo ${name}
        to_msg="${to_msg}${name},"
    done
    ${REDIS_CLI_BIN} --cluster copyone ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromSlot ${slot}) \
        --cluster-to ${to_msg} \
        --cluster-aim-slot ${slot}
    # echo "${REDIS_CLI_BIN} --cluster copyone ${ENTRY_IP}:${ENTRY_PORT} \
    #     --cluster-from $(getNodeNameFromSlot ${slot}) \
    #     --cluster-to ${to_msg} \
    #     --cluster-aim-slot ${slot}"
}

setHotSlot() {
    slot=$1
    c_size=$2
    tag=$3
    HG_INSTANCE=$(getHGInsInfo ${MACH} ${INS} ${c_size} ${ENTRY_PORT})
    my=($(${REDIS_CLI_BIN} -p ${ENTRY_PORT} -h ${ENTRY_IP} cluster getipportbyslot ${slot}));
    ${REDIS_CLI_BIN} -p ${my[1]} -h ${my[0]} cluster hotgroup add ${slot}
    echo "${REDIS_CLI_BIN} -p ${my[1]} -h ${my[0]} cluster hotgroup add ${slot}"
    for hg_ins in ${HG_INSTANCE}; do
        ip=$(echo ${hg_ins} | awk -F: '{print $1}')
        port=$(echo ${hg_ins} | awk -F: '{print $2}')
        ${REDIS_CLI_BIN} -p ${port} -h ${ip} cluster hotgroup ${tag} ${slot}
        echo "${REDIS_CLI_BIN} -p ${port} -h ${ip} cluster hotgroup ${tag} ${slot}"
    done

}

copyOneAndSet() {
    slot=$1
    c_size=$2
    echo "start sethotslot"
    setHotSlot ${slot} ${c_size} add
    echo "start copyhotslot"
    copyOneSlot ${slot} ${c_size}
}


copySlotRange(){
    c_size=$1
    begin=$2
    num=$3
    let end=begin+num
    ct=0;
    for slot in ${HOTSLOT}; do
        if [ ${begin} -gt $ct ]; then
            let ct++; continue;
        fi
        if [ ${end} -eq $ct ]; then break;fi
        # echo copy ${slot}
        copyOneAndSet ${slot} ${c_size}
        sleep 10
        let ct++;
    done
}

doCopy() {
    c_size=$1
    wlt=$2
    let hg_num=INS-c_size
    # the num of hotslot of each workload, we should copy num hotslot to the hot instance 
    # 注意是累加，按照顺序来的
    # echo "${HG_DIR}/HG_${hg_num}"
    num=$(cat ${HG_DIR}/HG_${hg_num} | grep ${wlt} | awk '{print $2}')
    copySlotRange ${c_size} ${LAST_COPY_NUM} ${num}
    let LAST_COPY_NUM+=num
}


getAverageCpuUsage() {
    file=$1
    # cat $file | awk '{sum=0; for (i=21; i<=NF-20; i++) sum += $i; sum /= (NF-40); print $1,sum}'
    tmp=$(cat ${file} | grep "redis-server" | awk '{print $8}')
    echo ${tmp} | awk '{sum = 0; for (i=20; i < NF-20; i++) sum+=$i; sum /=(NF-40); print sum}'
}
getHotnessFile() {
    dir=$1
    wkld=$2
    rm *.log
    base=${LOG_DIR}/${dir}/${wkld}/monitor
    nodelist=$(selectNode ${MACH})
    baseport=${ENTRY_PORT}
    let eachmach=INS/MACH
    let endport=baseport+eachmach-1
    for n in $nodelist; do
        for f in $(ls ${base}/${n} | grep cpu); do
            p=$(echo ${f} | awk -F_ '{print $2}')
            echo $(nodeToIP $n):${p} $(getAverageCpuUsage ${base}/${n}/${f}) >> hotness.log
        done
    done
}

getNodeNameFromIPPort() {
    ip=$1
    ${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | \
        grep ${ip} | awk '{print $1}'
}

limitband(){
    nodenum=$1
    limitip=$2
    averagerate=$3
    let ceiling=$averagerate+5
    nodelist=$(selectNode ${nodenum})   
    for n in $nodelist; do
        echo $n
        ssh $n "sudo tc qdisc del dev $NETCARD root; \
                sudo tc qdisc add dev $NETCARD root handle 1: htb r2q 1; \
                sudo tc class add dev $NETCARD parent 1: classid 1:1 htb rate ${averagerate}mbit ceil ${ceiling}mbit; \
                sudo tc  filter add dev $NETCARD parent 1: protocol ip prio 16 u32 match ip dst ${limitip}  flowid 1:1;"
    done
}

cancellimit(){
    nodelist="knode1 knode2 knode3 knode4 knode5 knode6 knode7"
    for n in $nodelist; do
        echo $n
        ssh $n "sudo tc qdisc del dev ens4f1 root; \
                sudo tc qdisc del dev ens3f1 root; \
                sudo wondershaper clear ens4f1; \
                sudo wondershaper clear ens3f1; \
                sudo wondershaper  ens4f1 clear; \
                sudo wondershaper  ens3f1 clear; \
                "
    done 
}

limitall(){
    nodelist="knode1 knode2 knode3 knode4 knode5"
    nodelist1="knode6 knode7"
    for n in $nodelist; do
        echo $n
        ssh $n "sudo wondershaper ens4f1 102400 102400"
    done
    for n in $nodelist1; do
        echo $n
        ssh $n "sudo wondershaper ens3f1 102400 102400"
    done
}

startmount(){
    nodelist="knode1 knode3 knode4 knode6 knode7"
    for n in $nodelist; do
        echo $n
        ssh $n "sshfs homie@knode2:/home/homie/share /home/homie/share"
    done
    # newnode="knode5"
    ssh skv-node5 "sshfs homie@skv-node2:/home/homie/share /home/homie/share"
    echo "skv-node5"
}
stopmount(){
   nodelist="knode1 knode3 knode4 knode6 knode7 skv-node5"
    for n in $nodelist; do
        echo $n
        ssh $n "sudo fusermount -zu /home/homie/share"
    done 

}

# choosefield(){
#     fieldcount=$1
#     fieldlen=$2
#     case ${fieldlen} in
#         1) 
# }