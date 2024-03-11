#!/bin/bash

for i in {1..10000}; do
    redis-cli -p 21000 -h 127.0.0.1 -c set id${i} "Hello World" >> /dev/null;
done
