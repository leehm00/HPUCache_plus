#!/bin/bash

TEMPLATE_DIR=./template
INSTANCE_DIR=./instance
S_TEMP=${TEMPLATE_DIR}/single.conf
C_TEMP=${TEMPLATE_DIR}/cluster.conf
IO_S_TEMP=${TEMPLATE_DIR}/iosingle.conf
IO_C_TEMP=${TEMPLATE_DIR}/iocluster.conf

mkdir -p ${TEMPLATE_DIR}
mkdir -p ${INSTANCE_DIR}

helpMsg() {
    echo "
    Usage: $0 <option> <args>
    <option>
    -t  Conf Type, two options, s(single), c(cluster)
    -p  Other Options
        io=true/false   Open IO Thread or Not
        startport=<num> the start port num
        endport=<num>   the end port num
    "
    exit
}

commonGenerator() {
    template_file=$1
    aim_dir=$2
    port=$3
    let busport=port+5000
    mkdir -p ${aim_dir}
    instance_file=${aim_dir}/conf-${port}.conf
    cp ${template_file} ${instance_file}
    sed -i "s/<PORT>/${port}/g" ${instance_file}
    # sed -i "s/<BUS_PORT>/${busport}/g" ${instance_file}
}

genConf() {
    arch=$1
    io=$2
    baseport=$3
    endport=$4
    temp_file=${S_TEMP}
    outputfile=${INSTANCE_DIR}/single
    if [ $arch == "s" ]; then
        if [ $io == "true" ]; then
            opt="io_single";
        else
            opt="single"
        fi
    elif [ $arch == "c" ]; then
        if [ $io == "true" ]; then
            opt="io_cluster";
        else
            opt="cluster"
        fi
    fi
    case $opt in
        single)
            temp_file=${S_TEMP}
            outputfile=${INSTANCE_DIR}/single
            ;;
        cluster)
            temp_file=${C_TEMP}
            outputfile=${INSTANCE_DIR}/cluster
            ;;
        io_single)
            temp_file=${IO_S_TEMP}
            outputfile=${INSTANCE_DIR}/iosingle
            ;;
        io_cluster)
            temp_file=${IO_C_TEMP}
            outputfile=${INSTANCE_DIR}/iocluster
            ;;
        *)
            helpMsg
            ;;
    esac
    for port in $(seq ${baseport} ${endport}); do
        commonGenerator ${temp_file} ${outputfile} ${port}
    done
}

# Args

Option=""
IO=""
Startport=-1
Endport=-1
ioDealer() {
    cmd=$1
    if [ $cmd == "true" ]; then IO="true";
    else IO="false"; fi
}

cmdProcessing() {
    cmd_line=$1
    cmd_array=(`echo ${cmd_line} | tr '=' ' '`)
    case ${cmd_array[0]} in
        io) ioDealer ${cmd_array[1]};;
        startport) Startport=${cmd_array[1]};;
        endport) Endport=${cmd_array[1]};;
        *) helpMsg; echo "io|startport|endport";;
    esac
}
# Arg end

#Debug

debug() {
    echo "debug msg"
}

#Debug end

while getopts 't:p:hdp:P:' Opt; do
    case $Opt in
        t) Option=$OPTARG ;;
        p) cmdProcessing ${OPTARG} ;;
        h) helpMsg; exit ;;
        d) debug ;;
        *|?) helpMsg; exit ;;
    esac
done

genConf ${Option} ${IO} ${Startport} ${Endport}



