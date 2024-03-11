#!/bin/bash

HOTSLOT="16112 5993 3468 3418 15335 9995 8905 10072 2571 1439 5459 3411 11931 15541 8791 13257 13386 1269 11427 1100 7554 5373 2958 13325 16231 10435 11754 8677 12742 11602 7231 8847 10319 10740 12887 6067 15624 13411 14395 14665 14253 15289 2568 12398 587 2794 6142 4813 8483 2868 1548 2130 7990 2775 4697 10224 6651 5430 5629 5229 6220 6027 7224 1370 13308 12711 5012 5953 10608 4188 13738 1216 12771 8626 7258 7315 376 13642 1935 8932 904 1643 4204 16193 5958 8369 9355 10055 5920 1315 10187 3101 6826 4553 1514 4554 1000 7691 7924 15395 3385 6683 7601 6231 2257 8817 10065 13499 4196 14926 10279 9276 2566 15266 5137 15600 3698 3563 6777 3724 219 5403 6041 8157 14317 8848 12300 9575 9651 2796 5369 3280 4665 16050 1011 3175 4295 1003 7101 8017 4610 8171 10811 586 3341 10853 1265 1229 9931 7376 15293 11343 2893 8666 15457 3044 3900 11092 1539 8197 13745 15930 8546 8201 14363 2235 4819 14744 1979 11441 7696 8248 9731 2861 10991 4857 13304 8249 11960 5893 3370 14778 7805 4882 16328 1062 15146"
REDIS_CLI_BIN=/home/homie/workspace/redis/src/bin/redis-cli
REDIS_SERVER_BIN=/home/homie/workspace/redis/src/bin/redis-server
MAIN_INS_IP=10.0.0.51
MAIN_INS_PORT=21007
HOTSLOT_L=($HOTSLOT)
HOT_THRESHOLD=153


getNodeNameFromSlot() {
    ${REDIS_CLI_BIN} -c -p 21000 -h 10.0.0.51 cluster getnodebyslot $1
}

getNodeNameFromPort() {
    port=$1
    ${REDIS_CLI_BIN} -c -p 21000 cluster nodes | grep ${port} | awk '{print $1}'
}

moveAllSlot() {
    from=$1
    to=$2
    ${REDIS_CLI_BIN} -h 10.0.0.51 -p ${from} cluster setallslot migrating \
        $(getNodeNameFromPort $from) $(getNodeNameFromPort $to)

    ${REDIS_CLI_BIN} -h 10.0.0.51 -p ${to} cluster setallslot importing \
        $(getNodeNameFromPort $from) $(getNodeNameFromPort $to)

    for i in {21000..21009}; do
        ${REDIS_CLI_BIN} -h 10.0.0.51 -p ${i} cluster setallslot node \
            $(getNodeNameFromPort $from) $(getNodeNameFromPort $to)
    done
    # ${REDIS_CLI_BIN} -h 10.0.0.51 -p ${to} cluster setallslot node \
    #     $(getNodeNameFromPort $from) $(getNodeNameFromPort $to)

}


buildCluster() {
    echo "yes" | ${REDIS_CLI_BIN} --cluster create \
        10.0.0.51:21000 \
        10.0.0.51:21001 \
        10.0.0.51:21002 \
        10.0.0.51:21003 \
        10.0.0.51:21004 \
        10.0.0.51:21005 \
        10.0.0.51:21006 \
        --cluster-replicas 0
    # ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21006
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21007
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21008
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21009
    # ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21010
    # ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21000 cluster meet 10.0.0.51 21011
    # ${REDIS_CLI_BIN} -c -p 21000 cluster meet 10.0.0.53 21007
    # ${REDIS_CLI_BIN} -c -p 21000 cluster meet 10.0.0.53 21008
}

setReplica() {
    cmd=$1
    case ${cmd} in
        add)
            ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21008 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21009 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            # ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21010 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            # ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21011 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            # ${REDIS_CLI_BIN} -h 10.0.0.53 -p 21007 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            # ${REDIS_CLI_BIN} -h 10.0.0.53 -p 21008 slaveof ${MAIN_INS_IP} ${MAIN_INS_PORT}
            ;;
        del)
            ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21008 slaveof NO ONE
            ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21009 slaveof NO ONE
            # ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21010 slaveof NO ONE
            # ${REDIS_CLI_BIN} -h 10.0.0.51 -p 21011 slaveof NO ONE
            # ${REDIS_CLI_BIN} -h 10.0.0.53 -p 21007 slaveof NO ONE
            # ${REDIS_CLI_BIN} -h 10.0.0.53 -p 21008 slaveof NO ONE
            rm -rf ~/data/redis-data/*.rdb
            # ssh knode3 "rm -rf /home/homie/data/redis-data/*.rdb"
            ;;
        *) ;;
    esac
}

moveSlot() {
    ct = 0
    for i in $HOTSLOT; do
        if [ $ct -eq 20 ]; then break; fi
        from=$(getNodeNameFromSlot $i)
        to=$(getNodeNameFromPort ${MAIN_INS_PORT})
        echo "shell $from -> $to"
        ${REDIS_CLI_BIN} --cluster slot 10.0.0.51 21000 \
                     --cluster-from $from --cluster-to $to  \
                     --cluster-aim-slot $i
        let ct++;
        sleep 1;
    done
}

moveOneSlot() {
    slot=$1
    to=$2
    ${REDIS_CLI_BIN} --cluster slot 10.0.0.51 21000 \
                 --cluster-from $(getNodeNameFromSlot ${slot}) \
                 --cluster-to $(getNodeNameFromPort ${to}) \
                 --cluster-aim-slot ${slot}
    sleep 10
}

getHotnessTag() {
    hot=$(${REDIS_CLI_BIN} -c -p 21000 cluster hghot)
    echo "$hot"
}

moveSlotBasedOnHotness() {
    count=0
    while true; do
        tag=$(getHotnessTag)
        if [ $tag -eq 1 ]; then break; fi
        if [ $count -eq ${HOT_THRESHOLD} ]; then break; fi;
        moveOneSlot ${HOTSLOT_L[$count]} ${MAIN_INS_PORT}
        let count++
    done
}

addHG() {
    cmd=$1
    ${REDIS_CLI_BIN} -c -p ${MAIN_INS_PORT} cluster hotgroup ${cmd} true
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21008 cluster hotgroup ${cmd}
    ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21009 cluster hotgroup ${cmd}
    # ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21010 cluster hotgroup ${cmd}
    # ${REDIS_CLI_BIN} -c -h 10.0.0.51 -p 21011 cluster hotgroup ${cmd}
    # ${REDIS_CLI_BIN} -c -h 10.0.0.53 -p 21007 cluster hotgroup ${cmd}
    # ${REDIS_CLI_BIN} -c -h 10.0.0.53 -p 21008 cluster hotgroup ${cmd}
}
cleanInfo() {
    rm -rf /home/homie/data/redis-data/*
}


# setReplica add

# sleep 1

# setReplica del

# sleep 1

# addHG add
# buildCluster



# rm /home/homie/data/redis-data/*

