#!/bin/bash

# INSTANCE="128 112 96 80 64 48 32 16"
# WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"

MACHINE="4"
INSTANCE="128"

WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"

INSTANCE="128"
WORKLOADTYPES="workloada"

MONITOR_DIR_NAME="monitor"
YCSBLOG_DIR_NAME="ycsblog"
SERVERNODES="node2 node3 node8 node9"
CLIENTNODES="n1 n4 n5 n6 n7"
# CLIENTNODES="n4"

LOG_BASE_DIR=$1
OUT_PUT_DIR=$2
DEALEDLOG_DIR=${OUT_PUT_DIR}


# INSTANCE="128"
# WORKLOADTYPES="workloadd"

calc() {
    cmd=$1
    before=$(echo $2 | awk -F_ '{print $2}')
    after=$(echo $3 | awk -F_ '{print $2}')
    beforetag=$(echo $2 | awk -F_ '{print $1}')
    aftertag=$(echo $3 | awk -F_ '{print $1}')
    if [ ! ${beforetag} -eq ${aftertag} ]; then
        echo "${beforetag} != ${aftertag}"
        echo "error"
        exit 1
    fi
    case $cmd in
        sum)
            let result=before+after
            ;;
        sub)
            let result=after-before
            ;;
        *)echo"sum/sub" ;;
    esac
    echo ${beforetag}_$result
}

calcTowRow() {
    cmd=$1
    fst=($(echo $2 | tr "," " "))
    snd=($(echo $3 | tr "," " "))
    for i in {0..16383}; do
        # SLOTS[$i]=$(calc $cmd ${fst[$i]} ${snd[$i]}) &
        # calc $cmd ${fst[$i]} ${snd[$i]}
        tag=$(echo ${fst[$i]} | awk -F_ '{print $1}')
        before=$(echo ${fst[$i]} | awk -F_ '{print $2}')
        end=$(echo ${snd[$i]} | awk -F_ '{print $2}')
        let sub=end-before
        echo ${tag}_${sub}
    done
}
getCommand() {
    redis_log=$1
    tag=$2
    dos2unix ${redis_log} > /dev/null 2>&1
    a=(`cat ${redis_log} | grep total_commands_processed | awk -F: '{print $2}'`)
    cmds=$(echo "${a[1]}-${a[0]}" | bc)
    echo ${tag} ${cmds}
}

getSize() {
    redis_log=$1
    tag=$2
    dos2unix ${redis_log} > /dev/null 2>&1
    a=(`cat ${redis_log} | grep keys | awk -F= '{print $2}' | awk -F, 'END{print $1}'`)
    echo ${tag} ${a}

}

getCpu() {
    cpu_log=$1
    tag=$2
    cpuinfo=`cat ${cpu_log} | awk '{print $8}' | grep -v "CPU"`
    echo ${tag} ${cpuinfo}
}

getYCSB() {
    ycsb_log=$1
    # For YCSB-JAVA
    # cat ${ycsb_log} | grep sec: | grep -v CLEANUP: \
    #     | awk '{print $7}' | grep -v est \
    #     | awk 'NR>1{sum+=$0}END{print sum/(NR-1)}'

    # For YCSB-CPP
    cat ${ycsb_log} | grep "ops/sec" | awk '{print $3}'

    # For YCSB-CPP Advance Version( only cat 10-40s)
    # fin=$(cat ${ycsb_log} | grep "ops/sec")
    # if [ -n "$fin" ]; then
    #     m=($(cat ${ycsb_log} | grep "sec:" | tail -n +10 | head -n 40 | awk 'NR==1{print $5}END{print $5}'))
    #     # echo ${m[0]}
    #     echo "(${m[1]}-${m[0]})/40" | bc
    # fi
}

getEachSecPerf() {
    file=$1
    cat ${file} | grep "sec:" | awk 'NR==10{base=$5}NR>10&&NR<110{print $5-base; base=$5}'
}

getSlot() {
    redis_log=$1
    tag=$2
    dos2unix ${redis_log} > /dev/null 2>&1
    a=(`cat ${redis_log} | grep -a dealed`)
    a_num=${#a[@]}
    if [ ${a_num} -eq 4 ]; then
        echo ${tag}_before ${a[1]}
        echo ${tag}_end ${a[3]}
    else
        echo ${tag}_before ${a[-3]}
        echo ${tag}_end ${a[-1]}
    fi
    # result=$(calcTowRow sub ${a[1]} ${a[3]:4})
    # echo ${tag} ${result}
}

getRedisStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${SERVERNODES}; do
                    dir=${LOG_BASE_DIR}/${I}_${M}/${W}/${MONITOR_DIR_NAME}/${sn}
                    for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                        p=$(echo ${logfile} | awk -F_ '{print $2}')
                        f=${dir}/${logfile}
                        getCommand  $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}.cmd.log
                        getSize $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}.size.log
                    done
                done
            done
        done
    done
}

getAvgCPU() {
    file=$1
    cat $file | awk '{sum=0; for (i=11; i<=NF-10; i++) sum += $i; sum /= (NF-20); print $1,sum}'
}

getCPUStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${SERVERNODES}; do
                    dir=${LOG_BASE_DIR}/${I}_${M}/${W}/${MONITOR_DIR_NAME}/${sn}
                    for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                        p=$(echo ${logfile} | awk -F_ '{print $2}')
                        f=${dir}/${logfile}
                        getCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}.cpu.log
                    done
                done
                getAvgCPU ${DEALEDLOG_DIR}/${M}_${I}_${W}.cpu.log > ${DEALEDLOG_DIR}/${M}_${I}_${W}.cpu.total.log
            done
        done
    done
}

getYCSBStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                sum=0;
                ct=0;
                for cn in ${CLIENTNODES}; do
                    dir=${LOG_BASE_DIR}/${I}_${M}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                    for f in $(ls ${dir} | grep "run_${W}" ); do
                        # echo ${dir}/${f}
                        a=$(getYCSB ${dir}/$f)
                        if [ -n "$a" ]; then
                            sum=$(echo "${sum} + ${a}" | bc)
                            let ct=ct+1
                        fi
                    done
                done
                avg=$(echo "${sum} / (${ct}) " | bc)
                echo ${M}_${I} ${W} ${avg}
            done
        done
    done

}

getSlotStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${SERVERNODES}; do
                    dir=${LOG_BASE_DIR}/${I}_${M}/${W}/${MONITOR_DIR_NAME}/${sn}
                    for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                        p=$(echo ${logfile} | awk -F_ '{print $2}')
                        f=${dir}/${logfile}
                        getSlot $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}.slot.log.tmp
                    done
                done
                ./slot_log_dealer.py ${DEALEDLOG_DIR}/${M}_${I}_${W}.slot.log.tmp > ${DEALEDLOG_DIR}/${M}_${I}_${W}.slot.log
                rm ${DEALEDLOG_DIR}/${M}_${I}_${W}.slot.log.tmp
            done
        done
    done
}

getEachSecYCSBStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for cn in ${CLIENTNODES}; do
                    dir=${LOG_BASE_DIR}/${I}_${M}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                    for f in $(ls ${dir} | grep "run_${W}" ); do
                        a=$(getEachSecPerf ${dir}/$f)
                        echo ${a} >> ${DEALEDLOG_DIR}/tmp.log
                    done
                done
            done
        done
    done
    cat ${DEALEDLOG_DIR}/tmp.log | awk '{for(i=1;i<NF;++i){a[i]+=$i}}END{for(x in a){printf a[x]/NR " "}}' > ${DEALEDLOG_DIR}/result.log
    rm ${DEALEDLOG_DIR}/tmp.log
}

mkdir -p ${DEALEDLOG_DIR}

# getSlotStat
# getYCSBStat > ${DEALEDLOG_DIR}/$3.log
# getCPUStat
# getRedisStat
getEachSecYCSBStat





