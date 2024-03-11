#!/bin/bash

# ./baseline.sh
# source ./exp1.sh


# export HG_NUM=4
# export MOVE_NUM=20
# export CLIENT_NUM=100
# export WORKLOADTYPES="workloada workloadf"
# ./exp1.sh

# export HG_NUM=8
# export MOVE_NUM=50
# export CLIENT_NUM=100
# ./exp1.sh

# export HG_NUM=12
# export MOVE_NUM=50
# export CLIENT_NUM=100
# ./exp1.sh

# export HG_NUM=12
# export MOVE_NUM=50
# export CLIENT_NUM=150
# ./exp1.sh

./baseline.sh > runlog1 2>&1
./exp1.sh > runlog2 2>&1

