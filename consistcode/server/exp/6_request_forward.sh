#!/bin/bash

source ./1_build_redis_cluster.sh

M="4"
I="128"

moveAllSlotToOne() {
    m=$1
    ins=$2

}

buildCluster ${M} ${I} 0



