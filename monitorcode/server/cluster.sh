#!/bin/bash

REDIS_SERVER_BIN=/home/wangep/workspace/redis/src/bin/redis-server
REDIS_CLI_BIN=/home/wangep/workspace/redis/src/bin/redis-cli
CONF_DIR=/home/wangep/workspace/redis/conf/instance/cluster

# run Instance

runOneInstance() {
    i=$1
    ${REDIS_SERVER_BIN} ${CONF_DIR}/conf-${i}.conf  &
}

doBuild() {
    echo yes | ${REDIS_CLI_BIN} --cluster create \
        127.0.0.1:21000 \
        127.0.0.1:21001 \
        127.0.0.1:21002 \
        127.0.0.1:21003 \
        127.0.0.1:21004 \
        127.0.0.1:21005 \
        --cluster-replicas 0 > /dev/null
}

buildC() {
    for i in {21000..21005}; do
        ${REDIS_SERVER_BIN} ${CONF_DIR}/conf-${i}.conf  &
    done

    sleep 2
    doBuild

    # build Cluster

}

stopC() {
    pgrep redis-server | xargs kill -9
    rm -rf /home/wangep/workspace/redis/data/*
    # rm -rf *.txt
}


Cmd=$1

case ${Cmd} in
    ri) runOneInstance $2 ;;
    bo) doBuild ;;
    b) buildC ;;
    s) stopC ;;
    *) echo "xxx" ;;
esac
