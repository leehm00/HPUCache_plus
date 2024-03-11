#!/bin/bash

source ./3_ycsb_client.sh
source ./1_build_redis_cluster.sh
source ./4_monitor.sh
source ./0_parameters.sh
source ./hotslot_exp1.sh
source ./7_public_func.sh

REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server"
ENTRY_IP="10.0.0.52"
ENTRY_PORT=27000
FIELDS=10
FIELDLEN=100
THREADS=1
DISTRIBUTION="zipfian"

CLIENT_NUM=100
RECORDCOUNT=1000000 # 1M data for test
OPERCOUNT=500000 # for 100 client each have 1M total 100M * 5 = 500M
REPLICA=0

REPEAT=1

HG_PORT=27100
MAIN_INSTANCE_IP=${ENTRY_IP}
MAIN_INSTANCE_NODE="n2"
MAIN_INSTANCE_PORT=27099





buildAndLoadPhase() {
    nodenum=$1
    instancenum=$2
    buildHGCluster ${nodenum} ${instancenum}
    loadData ${RECORDCOUNT}
}


getHotSlot() {
    # cat HG_$1 | grep ${2}_${3} | awk '{print $3}'
    # cat ./HG_para/Exp2/no/HG_$1| grep ${2}_${3} | awk '{print $3}'
    cat ./HG_para/Exp1/HG_$1| grep ${2}_${3} | awk '{print $3}'
    # cat ./HG_$1_test | grep ${2}_${3} | awk '{print $3}'

}

selectClientNum() {
    case ${1} in
        workloada)
            CLIENT_NUM=100;
            OPERCOUNT=400000
            # CLIENT_NUM=600;
            # OPERCOUNT=100000
            ;;
        workloadb)
            CLIENT_NUM=200
            OPERCOUNT=200000
            ;;
        workloadc)
            CLIENT_NUM=100
            # CLIENT_NUM=750
            # CLIENT_NUM=1000
            OPERCOUNT=400000
            ;;
        workloadd)
            CLIENT_NUM=200
            OPERCOUNT=200000
            ;;
        workloadf)
            CLIENT_NUM=100
            OPERCOUNT=400000
            ;;
        *) ;;
    esac
}

setHotSlot() {
    wlt=$1
    if [ $wlt == "workloadd" ]; then
        HOTSLOT=${HOTSLOT_NORMAL_D}
    else
        HOTSLOT=${HOTSLOT_NORMAL_ABCF}
    fi
    HOTSLOT_L=($HOTSLOT)
    echo "set hot slot "
}

#Get The Parameter

getHotnessTag() {
    ${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster hghot
}

getNormalHot() {
    ${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster inshot
}

getClusterStatus() {
    ret=$(${REDIS_CLI_BIN} -c -h ${ENTRY_IP} -p ${ENTRY_PORT} cluster nodes | grep fail)
    a=0
    if [ -n "${ret}" ]; then a=1; fi;
    echo ${a}
}

runWorkload() {
    m=$1
    ins=$2
    wlt=$3
    startMonitor
    selectClientNum ${wlt}
    echo "Run ${wlt} in CLIENT:${CLIENT_NUM} OP_NUM:${OPERCOUNT}"
    multiClientRun ${wlt} ${OPERCOUNT} \
        ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
    stopMonitor
    sleep 10
    fail=$(getClusterStatus);
    echo Fail:${fail}
    if [ ${fail} -eq 1 ]; then
        echo "Meet Error!"
        stopCluster ${m}
        buildAndLoadPhase ${m} ${ins}
        setHotSlot ${wlt}
        moveSlotAdvance ${m} ${ins} 0 $(getHotSlot ${HG_NUM} ${ins} ${wlt})
        runWorkload $m ${ins} ${wlt}
    fi
    LOG_NAME="Exp1_${HG_NUM}HG_client_1M"
    LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
    moveData "${ins}_${m}" ${wlt}
    cleanLog
}



moveOneSlot() {
    slot=$1
    ${REDIS_CLI_BIN} --cluster slot ${ENTRY_IP}:${ENTRY_PORT} \
                 --cluster-from $(getNodeNameFromSlot ${slot}) \
                 --cluster-to $(getNodeNameFromPort ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT}) \
                 --cluster-aim-slot ${slot}
    sleep 40
}

moveSlotBasedOnHotness() {
    # sleep 30 # sleep first 1m for ready
    while true; do
        hghot=$(getHotnessTag)
        inshot=$(getNormalHot);
        fail=$(getClusterStatus);
        echo "hghot:${hghot} inshot:$inshot fail:${fail}"
        if [ $hghot -eq 1 -a $inshot -eq 1 ]; then
            stat="normal"
            break;
        fi
        if [ ${fail} -eq 1 ]; then
            stat="fail"
            break;
        fi
        if [ $inshot -eq 0 ]; then
            stat="underheat"
            break;
        fi
        if [ $count -eq ${HOT_THRESHOLD} ]; then
            break;
        fi;
        moveOneSlot ${HOTSLOT_L[$count]}
        let count++
    done
}

reRunParaSingle() {
    let reruncount++;
    echo "Rerun Process"
    stopClient
    stopCluster ${m}
    buildAndLoadPhase ${m} ${ins}
    setReplicaStatus add ${m}
    sleep 5
    addHG ${m} add
    sleep 5
    getParaSingle ${m} ${ins} ${wlt}
}

getParaSingle() {
    m=$1
    ins=$2
    wlt=$3
    HOT_THRESHOLD=${HOT_THRESHOLD_NORMAL_10}
    if [ $wlt == "workloadd" ]; then
        HOTSLOT=${HOTSLOT_NORMAL_D}
    else
        HOTSLOT=${HOTSLOT_NORMAL_ABCF}
    fi
    HOTSLOT_L=($HOTSLOT)

    echo ${wlt}_${CLIENT_NUM}
    multiClientRun ${wlt} ${OPERCOUNT} \
        ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM} &

    while true; do # Waiting until hotness message broadcast
        inshot=$(getNormalHot)
        if [ ${inshot} -eq 1 ]; then break; fi
    done

    count=0
    stat="empty"
    moveSlotBasedOnHotness
    echo ${stat}
    if [ "${stat}" == "normal" ]; then
        echo "Normal"
        echo ${CLIENT_NUM} ${ins}_${wlt} ${count} >> HG_${HG_NUM}_test
    elif [ "${stat}" == "underheat" ]; then
        echo "Unheated in ${CLIENT_NUM}"
        if [ $reruncount -lt 10 ]; then
            let CLIENT_NUM+=50
            if [ ${wlt} == "workloadc" ]; then
                let CLIENT_NUM+=200
            fi
            reRunParaSingle
        else
            echo ${CLIENT_NUM} ${ins}_${wlt} ${stat} >> HG_${HG_NUM}_test;
        fi
    elif [ "${stat}" == "fail" ]; then # if fail, repeat
        echo "fail"
        CLIENT_NUM=100;
        if [ $reruncount -lt 10 ]; then reRunParaSingle;
        else echo ${CLIENT_NUM} ${ins}_${wlt} ${stat} >> HG_${HG_NUM}_test; fi
    elif [ "${stat}" == "empty" ]; then
        echo "empty error"
    else
        echo "Impossible Error ${stat}"
    fi
    stopClient
}

resetStatus() {
    m=$1
    addHG ${m} del
    sleep 5
    ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} \
        --cluster-from $(getNodeNameFromPort ${MAIN_INSTANCE_IP} ${MAIN_INSTANCE_PORT}) \
        --cluster-to $(getNodeNameFromPort ${ENTRY_IP} ${ENTRY_PORT})
    addHG ${m} add
    sleep 5
}


getPara() {
    M=$MACH
    for I in ${INS}; do
        buildAndLoadPhase ${M} ${I}
        setReplicaStatus add ${M}
        sleep 5
        addHG ${M} add
        sleep 5
        for WLT in ${WORKLOADTYPES}; do
            CLIENT_NUM=100
            echo ${CLIENT_NUM}
            reruncount=0;
            getParaSingle ${M} ${I} ${WLT}
            sleep 5
            resetStatus ${M}
        done
        stopCluster ${M}
    done
}

autoRunParameter() {
    MACH="3"
    # INS="128 112 96 80 64 48 32 16"
    # WORKLOADTYPES="workloada workloadf workloadb workloadd workloadc"
    INS="112"
    WORKLOADTYPES="workloadc"
    OPERCOUNT=100000000
    # default client num, not add too much in workloada/f
    HOT_THRESHOLD=${HOT_THRESHOLD_NORMAL_10}
    CLIENT_NUM=100 # Based

    HG_NUM=2
    getPara

    HG_NUM=3
    getPara

    HG_NUM=4
    getPara

}

# autoRunParameter
# exit

# Do Run



runExp1() {
    M=${MACH}
    for I in ${INS}; do
        buildAndLoadPhase ${M} ${I}
        for WLT in ${WORKLOADTYPES}; do
            echo "run ${WLT}"
            setHotSlot ${WLT}
            moveSlotAdvance ${M} ${I} 0 $(getHotSlot ${HG_NUM} ${I} ${WLT})
            runWorkload ${M} ${I} ${WLT}
            resetStatus ${M}
        done
        stopCluster ${M}
    done
}

EXP1() {
    MACH="4"
    # INS="128 112 96 80 64 48 32 16"
    # WORKLOADTYPES="workloada workloadf workloadb workloadd workloadc"
    INS="128"
    WORKLOADTYPES="workloadc"

    HG_NUM=0
    runExp1

    HG_NUM=2
    runExp1

    HG_NUM=3
    runExp1

    HG_NUM=4
    runExp1
}

# EXP1

EXP2() {
    # REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server-no"
    # REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server-1s"
    MACH="4"
    INS="128"
    WORKLOADTYPES="workloada"

    HG_NUM=0
    runExp1

    HG_NUM=2
    runExp1

    HG_NUM=4
    runExp1

    HG_NUM=6
    runExp1
}

moveAllSlotToOne() {
    mach=$1
    ins=$2
    nodelist=$(selectNode ${mach})
    baseport=${ENTRY_PORT}
    let eachmach=ins/mach
    let mod=ins%mach
    if [ $mod -gt 0 ]; then let eachmach++; fi;
    let endport=baseport+eachmach-1
    ct=0;
    for p in $(seq ${baseport} ${endport}); do
        for n in $nodelist; do
            ip=$(nodeToIP $n)
            if [ ${ip} == ${ENTRY_IP} -a ${p} == ${ENTRY_PORT} ]; then continue; fi
            if [ $ct -eq ${ins} ]; then break; fi;
            ${REDIS_CLI_BIN} --cluster move ${ENTRY_IP}:${ENTRY_PORT} \
                --cluster-from $(getNodeNameFromPort ${ip} ${p}) \
                --cluster-to $(getNodeNameFromPort ${ENTRY_IP} ${ENTRY_PORT})
            let ct++;
        done
    done

}

runSyncTest() {
    MACH="4"
    INS="4"
    CLIENT_NUM=50
    OPERCOUNT=50000
    RECORDCOUNT=1000000
    WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
    # buildCluster ${MACH} ${INS} 0;
    # moveAllSlotToOne ${MACH} ${INS}

    # loadData ${RECORDCOUNT}
    for WLT in ${WORKLOADTYPES}; do
        echo "run ${WLT}"
        # startMonitor
        multiClientRun ${WLT} ${OPERCOUNT} \
            ${DISTRIBUTION} ${RECORDCOUNT} ${CLIENT_NUM}
        # stopMonitor
        LOG_NAME="Exp0"
        LOG_DIR="/home/wangep/share/redis/log/${LOG_NAME}"
        moveData "${INS}_${MACH}" ${WLT}
        cleanLog
    done
    # stopCluster ${MACH}
}
# runSyncTest

# DIR="/home/wangep/share/redis/log"
# for index in {1..10}; do
#     REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server-no"
#     EXP2
#     mkdir ${DIR}/no
#     cp -r ${DIR}/Exp1_* ${DIR}/no
#     rm -rf ${DIR}/Exp1_*

#     REDIS_SERVER_BIN="/home/wangep/share/bin/redis-server-1s"
#     EXP2
#     mkdir ${DIR}/1s
#     cp -r ${DIR}/Exp1_* ${DIR}/1s
#     rm -rf ${DIR}/Exp1_*

#     mkdir ${DIR}/t${index}
#     cp -r ${DIR}/no ${DIR}/t${index}
#     cp -r ${DIR}/1s ${DIR}/t${index}
#     rm -rf ${DIR}/no
#     rm -rf ${DIR}/1s

#     mkdir -p ${DIR}/Exp2
#     cp -r ${DIR}/t${index} ${DIR}/Exp2
#     rm -rf ${DIR}/t${index}
# done



