#!/bin/bash

begin=$1
end=$2
let cb=begin+10000
let ce=end+10000
# echo ${begin} ${end} ${cb} ${ce}
for i in $(seq ${begin} ${end}); do
    a=$(sudo lsof -i:$i)
    if [ -n "$a" ]; then
        echo error in $i
        break;
    fi
done

for i in $(seq ${cb} ${ce}); do
    a=$(sudo lsof -i:$i)
    if [ -n "$a" ]; then
        echo error in $i
        break;
    fi
done
