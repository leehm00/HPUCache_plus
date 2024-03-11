#!/bin/bash

parllal=$1


runWorkload() {
    workload=$1
    for i in $(seq 1 $parllal); do
        echo ${i}
        ./ycsb -run -db redis -s \
            -P workloads/workload${workload} \
            -p recordcount=10000 \
            -p operationcount=100000 \
            -p status.interval=1 >
    done
}

loadData() {
   ./ycsb -load -db redis -s \
       -P workloads/workloada \
       -p recordcount=10000 \
       -p operationcount=100000 \
       -p status.interval=1

}


