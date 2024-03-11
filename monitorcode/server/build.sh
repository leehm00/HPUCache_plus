#!/bin/bash

# ./cluster.sh s
pgrep redis-server | xargs kill -9
pgrep controller | xargs kill -9
# make clean

# make CFLAGS="-static" EXEEXT="-static" LDFLAGS="-I/usr/local/include" -j 10000
make  -j

rm ./bin/redis-server
rm ./bin/redis-cli
rm ./bin/redis-benchmark
rm ./bin/redis-check-rdb
rm ./bin/redis-check-aof
rm ./bin/redis-sentinel
rm ./bin/controller

mkdir -p ./bin

cp src/redis-server     ./bin
cp src/redis-cli        ./bin
cp src/redis-benchmark  ./bin
cp src/redis-check-rdb  ./bin
cp src/redis-check-aof  ./bin
cp src/redis-sentinel   ./bin
cp src/controller       ./bin


# ./cluster.sh b

# make clean
