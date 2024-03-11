#!/bin/bash

# BASE=./Exp1_4HG-1_100client/96_4/workloada/ycsblog
# BASE=./test6/Exp1_${1}HG_client_1M/${2}_4/workload${3}/ycsblog
BASE=${1}/${2}_4/workload${3}/ycsblog

NODES="n5 n6 n7 n8 n9"

total=0
hit=0
for n in ${NODES}; do
    dir=${BASE}/${n}
    ct=0
    for f in $(ls $dir | grep run); do
        a=$(cat ${dir}/${f} | grep "ops/sec")
        if [ -n "$a" ]; then
            let hit++
            let ct++
        else
            echo ${dir}/${f}
        fi
        let total++
    done
    echo ${n}:${ct}
done

echo hit: ${hit}
echo total: ${total}




