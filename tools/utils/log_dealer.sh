#!/bin/bash
source ./0_parameters.sh
MACHINE="2"
# INSTANCE="96 88 80 72 64 56 48 40 32 24 16 8"
# INSTANCE="32 56 72"
# WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
# INSTANCE="32"
# WORKLOADTYPES="workloada"
MONITOR_DIR_NAME="monitor"
YCSBLOG_DIR_NAME="ycsblog"
# YCSBMODE="uniform zipfian zipfian_skew"
# YCSBMODE="uniform zipfian"

# NODELIST="knode2 knode1 knode7 knode6"
# CLIENTNODES="knode4 knode3 knode5"




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

getwaitCpu() {
    cpu_log=$1
    tag=$2
    cpuinfo=`cat ${cpu_log} | awk '{print $8}' | grep -v "CPU"`
    echo ${tag} ${cpuinfo}
}

getusrCpu() {
    cpu_log=$1
    tag=$2
    cpuinfo=`cat ${cpu_log} | awk '{print $5}' | grep -v "CPU"`
    echo ${tag} ${cpuinfo}
}

getsysCpu() {
    cpu_log=$1
    tag=$2
    cpuinfo=`cat ${cpu_log} | awk '{print $6}' | grep -v "CPU"`
    echo ${tag} ${cpuinfo}
}

getallCpu() {
    cpu_log=$1
    tag=$2
    cpuinfo=`cat ${cpu_log} | awk '{print $9}' | grep -v "CPU"`
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
}

getSlot() {
    redis_log=$1
    tag=$2
    dos2unix ${redis_log} > /dev/null 2>&1
    a=(`cat ${redis_log} | grep -a dealed`)
    a_num=${#a[@]}
    # echo $a_num
    # echo ${a[3]}
    # if [ ${a_num} -eq 4 ]; then
        echo ${tag}_before ${a[1]}
        echo ${tag}_end ${a[3]}
    # else
    #     echo ${tag}_before ${a[-3]:8}
    #     echo ${tag}_end ${a[-1]:8}
    # fi
    # result=$(calcTowRow sub ${a[1]} ${a[3]:4})
    # echo ${tag} ${result}
}

getBandsent(){
    band_log=$1
    beginport=$2
    endport=$3
    for ((i=${beginport}; i<=${endport}; i++)); do
        sent=(`cat ${band_log} | grep -a 0.0.0.0:${i} | awk '{print $4}'`)
        # recieve=(`cat ${band_log} | grep -a 0.0.0.0:${i} | awk '{print $5}'`)
        # recievenum=${#recieve[@]}
        echo ${i} ${sent[@]:4}
    done   
}

getBandrecieve(){
    band_log=$1
    beginport=$2
    endport=$3
    for ((i=${beginport}; i<=${endport}; i++)); do
        # sent = (`cat ${band_log} | grep -a 0.0.0.0:${i} | awk '{print $4}'`)
        recieve=(`cat ${band_log} | grep -a 0.0.0.0:${i} | awk '{print $5}'`)
        # recievenum=${#recieve[@]}
        echo ${i} ${recieve[@]:4}
    done   
}

getRedisStat() {
    # echo "Begin"
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${NODELIST}; do
                    for Y in $YCSBMODE;do
                        dir=${LOG_BASE_DIR}/${I}_${Y}/${W}/${MONITOR_DIR_NAME}/${sn}
                        echo $dir
                        for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                            p=$(echo ${logfile} | awk -F_ '{print $2}')
                            f=${dir}/${logfile}
                            getCommand  $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.cmd.log
                            getSize $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.size.log
                        done
                    done
                done
            done
        done
    done
}

getwaitCpuStat() {
    for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${NODELIST}; do
                    for Y in $YCSBMODE;do
                        dir=${LOG_BASE_DIR}/${I}_${Y}/${W}/${MONITOR_DIR_NAME}/${sn}
                        echo $dir
                        for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                            p=$(echo ${logfile} | awk -F_ '{print $2}')
                            f=${dir}/${logfile}
                            getwaitCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.cpu.log
                        done
                    done
                done
            done
        done
    done
}

getYCSBStat() {
    # for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                sum=0;
                ct=0;
                for cn in ${CLIENTNODES}; do
                    dir=${LOG_BASE_DIR}/${LOGNAME}/${I}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                    for f in $(ls ${dir} | grep "run_${W}" ); do
                        a=$(getYCSB ${dir}/$f)
                        if [ -n "$a" ]; then
                            sum=$(echo "${sum} + ${a}" | bc)
                            let ct=ct+1
                        fi
                    done
                done
                avg=$(echo "${sum} / ${ct}" | bc)
                echo ${LOGNAME} ${I} ${W} ${avg}
            done
        done
    # done

}

getSlotStat() {
    # for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${NODELIST}; do
                    # for Y in $YCSBMODE;do
                        dir=${LOG_BASE_DIR}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                        for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                            p=$(echo ${logfile} | awk -F_ '{print $2}')
                            f=${dir}/${logfile}
                            getSlot $f ${sn}_${p} > ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.slot.log.tmp
                        done
                        echo "processing ${M}_${I}_${W}_${Y}" 
                        ./slot_log_dealer.py ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.slot.log.tmp > ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.slot.log
                        rm ${DEALEDLOG_DIR}/${M}_${I}_${W}_${Y}.slot.log.tmp
                    # done
                done
                
            done
        done
    # done
}

getSlotStatexp1() {
    for M in ${MACHINE}; do
        # for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${NODELIST}; do
                    dir=${LOG_BASE_DIR}/3/${W}/${MONITOR_DIR_NAME}/${sn}
                    for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                        p=$(echo ${logfile} | awk -F_ '{print $2}')
                        f=${dir}/${logfile}
                        getSlot $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${W}.slot.log.tmp 
                    done
                done
                ./slot_log_dealer.py ${DEALEDLOG_DIR}/${W}.slot.log.tmp > ${DEALEDLOG_DIR}/${W}.slot.log
                rm ${DEALEDLOG_DIR}/${M}_${W}.slot.log.tmp
            done
        # done
    done
}

getYCSBStatforbase() {
    # for M in ${MACHINE}; do
        for I in ${INS}; do
            for W in ${WORKLOADTYPES}; do
                for C in $DISTRIBUTION; do
                    sum=0;
                    ct=0;
                    for cn in ${CLIENTNODES}; do
                        dir=${LOG_BASE_DIR}/${LOGNAME}/${I}_${C}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                        # echo $dir
                        for f in $(ls ${dir} | grep "run_${W}" ); do
                            a=$(getYCSB ${dir}/$f)
                            if [ -n "$a" ]; then
                                sum=$(echo "${sum} + ${a}" | bc)
                                let ct=ct+1
                            fi
                        done
                    done
                    avg=$(echo "${sum} / ${ct}" | bc)
                    echo ${I} ${W} ${C} ${avg}
                done
            done
        done
    # done

}

getYCSBStatforexp5() {
    # for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for C in $CONSISTTYPES; do
                    sum=0;
                    ct=0;
                    for cn in ${CLIENTNODES}; do
                        dir=${LOG_BASE_DIR}/consist${C}/${I}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                        # echo $dir
                        for f in $(ls ${dir} | grep "run_${W}" ); do
                            a=$(getYCSB ${dir}/$f)
                            if [ -n "$a" ]; then
                                sum=$(echo "${sum} + ${a}" | bc)
                                let ct=ct+1
                            fi
                        done
                    done
                    avg=$(echo "${sum} / ${ct}" | bc)
                    echo ${I} ${W} ${C} ${avg}
                done
            done
        done
    # done

}

getwaitCpuStatforexp5() {
    # for M in ${MACHINE}; do
        for I in ${INSTANCE}; do
            for W in ${WORKLOADTYPES}; do
                for C in $CONSISTTYPES; do
                    for sn in ${NODELIST}; do
                        
                            dir=${LOG_BASE_DIR}/consist${C}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                            echo $dir
                            for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                                p=$(echo ${logfile} | awk -F_ '{print $2}')
                                f=${dir}/${logfile}
                                getwaitCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${I}_${W}_${C}.cpu.log
                            done
                        
                    done
                done
            done
        done
    # done
}

getwaitCpuStatforexp7() {
    # for M in ${MACHINE}; do
        for I in ${ZIPFIANS}; do
            for W in ${WORKLOADTYPES}; do
                for C in $LOGNAME; do
                    for sn in ${NODELIST}; do
                        
                            dir=${LOG_BASE_DIR}/test${C}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                            echo $dir
                            for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                                p=$(echo ${logfile} | awk -F_ '{print $2}')
                                f=${dir}/${logfile}
                                getwaitCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${I}_${W}_${C}.cpu.log
                            done
                        
                    done
                done
            done
        done
    # done
}


getBandall(){
    # for M in ${MACHINE}; do
        for I in ${fieldlens}; do
            for W in ${WORKLOADTYPES}; do
                for C in $LOGNAME; do
                    for sn in ${NODELIST}; do
                        dir=${LOG_BASE_DIR}/keysize/${C}/${I}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                        # echo $dir
                        for logfile in $(ls ${dir} | grep "${sn}_netlog" ); do
                            # p=$(echo ${logfile} | awk -F_ '{print $2}')
                            f=${dir}/${logfile}
                            getBandsent $f $1 $2 >> ${DEALEDLOG_DIR}/sent${I}_${W}_${C}_${sn}.bandlog.log.tmp
                            getBandrecieve $f $1 $2 >> ${DEALEDLOG_DIR}/recieve${I}_${W}_${C}_${sn}.bandlog.log.tmp
                            ./band_log_dealer.py ${DEALEDLOG_DIR}/sent${I}_${W}_${C}_${sn}.bandlog.log.tmp >> ${DEALEDLOG_DIR}/sent_${W}_${C}_${sn}.bandlog.log
                            ./band_log_dealer.py ${DEALEDLOG_DIR}/recieve${I}_${W}_${C}_${sn}.bandlog.log.tmp >> ${DEALEDLOG_DIR}/recieve_${W}_${C}_${sn}.bandlog.log
                            rm ${DEALEDLOG_DIR}/sent${I}_${W}_${C}_${sn}.bandlog.log.tmp
                            rm ${DEALEDLOG_DIR}/recieve${I}_${W}_${C}_${sn}.bandlog.log.tmp
                        done
                    done
                done
                
            done
        done
    # done
}

getYCSBStatforexp7() {
    # for M in ${MACHINE}; do
        for I in ${ZIPFIANS}; do
            for W in ${WORKLOADTYPES}; do
                for C in $LOGNAME; do
                    sum=0;
                    ct=0;
                    for cn in ${CLIENTNODES}; do
                        dir=${LOG_BASE_DIR}/test${C}/${I}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                        # echo $dir
                        for f in $(ls ${dir} | grep "run_${W}" ); do
                            a=$(getYCSB ${dir}/$f)
                            if [ -n "$a" ]; then
                                sum=$(echo "${sum} + ${a}" | bc)
                                let ct=ct+1
                            fi
                        done
                    done
                    avg=$(echo "${sum} / ${ct}" | bc)
                    echo ${I} ${W} ${C} ${avg}
                done
            done
        done
    # done

}

getSlotStatexp7() {
    # for M in ${MACHINE}; do
        for I in ${ZIPFIANS}; do
            for W in ${WORKLOADTYPES}; do
                for sn in ${NODELIST}; do
                    dir=${LOG_BASE_DIR}/testzipfian100v3/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                    for logfile in $(ls ${dir} | grep redis | grep -v 6379);do
                        p=$(echo ${logfile} | awk -F_ '{print $2}')
                        f=${dir}/${logfile}
                        getSlot $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${W}.slot.log.tmp 
                    done
                done
                ./slot_log_dealer.py ${DEALEDLOG_DIR}/${W}.slot.log.tmp > ${DEALEDLOG_DIR}/${W}.slot.log
                rm ${DEALEDLOG_DIR}/${M}_${W}.slot.log.tmp
            done
        done
    # done
}

getYCSBStatforexp8() {
    # for M in ${MACHINE}; do
        for I in ${fieldlens}; do
            for W in ${WORKLOADTYPES}; do
                # for C in $LOGNAME; do
                    sum=0;
                    ct=0;
                    for cn in ${CLIENTNODES}; do
                        dir=${LOG_BASE_DIR}/normal/${I}/${I}/${W}/${YCSBLOG_DIR_NAME}/${cn}
                        # echo $dir
                        for f in $(ls ${dir} | grep "run_${W}" ); do
                            a=$(getYCSB ${dir}/$f)
                            if [ -n "$a" ]; then
                                sum=$(echo "${sum} + ${a}" | bc)
                                let ct=ct+1
                            fi
                        done
                    done
                    avg=$(echo "${sum} / ${ct}" | bc)
                    echo ${I} ${W} ${C} ${avg}
                    # echo ${avg}
                # done
            done
        done
    # done

}

getwaitCpuStatforexp8() {
    # for M in ${MACHINE}; do
        for I in ${fieldlens}; do
            for W in ${WORKLOADTYPES}; do
                for C in $LOGNAME; do
                    for sn in ${NODELIST}; do
                        
                            dir=${LOG_BASE_DIR}/nocopyfullband/${I}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                            echo $dir
                            for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                                p=$(echo ${logfile} | awk -F_ '{print $2}')
                                f=${dir}/${logfile}
                                getwaitCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${I}_${W}_${C}.cpu.log
                            done
                        
                    done
                done
            done
        done
    # done
}


getallCpuStatforexp8() {
    # for M in ${MACHINE}; do
        for I in ${fieldlens}; do
            for W in ${WORKLOADTYPES}; do
                for C in $LOGNAME; do
                    for sn in ${NODELIST}; do
                        
                            dir=${LOG_BASE_DIR}//${I}/${I}/${W}/${MONITOR_DIR_NAME}/${sn}
                            echo $dir
                            for logfile in $(ls ${dir} | grep cpu | grep -v 6379);do
                                p=$(echo ${logfile} | awk -F_ '{print $2}')
                                f=${dir}/${logfile}
                                getusrCpu $f ${sn}_${p} >> ${DEALEDLOG_DIR}/${I}_${W}_${C}.cpu.log
                            done
                        
                    done
                done
            done
        done
    # done
}
# rm -rf ${DEALEDLOG_DIR}



# LOGNAME="zipfian100v5"
# WORKLOADTYPES="workloadc"
# # WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
# # INSTANCE="10 20 25 30 35 40 45 50 55 60 70 80 90 100"
# ZIPFIANS="01 02 03 04 05 06 07 08 09 095 099 105 110 115 120 122 130 140 150 160 170 180 190 200"
# # ZIPFIANS="03"
# LOG_BASE_DIR="/home/homie/share/redis/log"
# OUT_PUT_DIR="/home/homie/share/redis/dealedlog/${LOGNAME}"
# DEALEDLOG_DIR="${OUT_PUT_DIR}"
# mkdir -p ${DEALEDLOG_DIR}

# getBandall 21000 21049

# getYCSBStatforexp7
# getwaitCpuStatforexp5
# getwaitCpuStatforexp7
# getYCSBStat >> ${DEALEDLOG_DIR}/ycsblog.log
# getwaitCpuStat
# getRedisStat

# getYCSBStat
# getwaitCpuStat

# getCommand ./32_4/wrbalance/monitor/node1/node1_21000_redis.log tag
# getwaitCpu ./32_4/wrbalance/monitor/node1/node1_21000_cpu.log node1_21001
# getYCSB ../log/baseline/32_uniform/workloada/ycsblog/knode3/run_workloada_1.txt
# getSlot ${LOG_BASE_DIR}/3/workloada/monitor/knode2/knode2_21000_redis.log tag
# LOG_BASE_DIR="/home/homie/share/redis/log/testbase"
# OUT_PUT_DIR="/home/homie/share/redis/dealedlog/exp1"
# getSlotStatexp7

LOGNAME="copyno122cpu60"
CONSISTTYPES="no 1s 09 08 07 06 05 04 03 02 01 immd"
# WORKLOADTYPES="workloadc"
# INSTANCE="1 2 3 4"
INSTANCE="0"
INS="25 50 75 100 125 150 175 200 225 250 275 300"
WORKLOADTYPES="workloada workloadb workloadc workloadd workloadf"
# WORKLOADTYPES="workloada workloadc"
# WORKLOADTYPES="workloada"
# INSTANCE="10 20 25 30 35 40 45 50 55 60 70 80 90 100"
fieldlens="1 2 5 10 20 50 100 200 500 1000 2000 5000"
LOG_BASE_DIR="/home/homie/share/redis/logtemp/"
# LOG_BASE_DIR="/home/homie/logs/logs/log/"
NODELIST="knode2 knode7 knode3 knode6"
OUT_PUT_DIR="/home/homie/share/redis/dealedlog/keysize/limitcpu/${LOGNAME}cpu"
DEALEDLOG_DIR="${OUT_PUT_DIR}"
mkdir -p ${DEALEDLOG_DIR}
DISTRIBUTION="zipfian_skew"
# getSlotStat  uniform zipfian_skew
# getBandall 21000 21023
# getYCSBStatforexp8
# getwaitCpuStatforexp8
# getallCpuStatforexp8
# getYCSBStatforbase
getYCSBStatforexp5