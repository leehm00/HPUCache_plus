#!/bin/bash

begin=$1
len=$2

let end=begin+len


for i in $(seq $begin $end); do
    tmp1=$(lsof -i:${i})
    let j=i+10000
    tmp2=$(lsof -i:${j})
    if [ -n "$tmp1"  -o -n "$tmp2" ]; then
        echo "conflict port in $i or $j";
        break
    fi
done
