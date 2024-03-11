#!/bin/bash
source /home/homie/share/redis/utils/0_parameters.sh
source /home/homie/share/redis/utils/1_build_redis_cluster.sh

runexporter(){
    # cd $EXPORTER_DIR
    # 最后一个“&”表示后台运行程序
    # “2>&1”表示将标准错误输出转变为标准输出，可以将错误信息也输出到日志文件中（0-> stdin, 1->stdout, 2->stderr）
    $EXPORTER_DIR/redis_exporter -redis.addr $ENTRY_IP:$ENTRY_PORT > $OUTPUTDIR/exporter_out.out 2>&1 &
}

generatenprometheusyaml(){
    nodenum=$1
    instancenum=$2
    baseport=$3
    # baseport=$4
    # clean yaml
    cp $PROMETHEUS_DIR/prometheus.yml $PROMETHEUS_DIR/prometheus_copy.yml 
    echo "  - job_name: 'redis_exporter_targets'" >> $PROMETHEUS_DIR/prometheus_copy.yml
    echo "    static_configs:" >> $PROMETHEUS_DIR/prometheus_copy.yml
    echo "      - targets:" >> $PROMETHEUS_DIR/prometheus_copy.yml
    nodelist=$(selectNode ${nodenum})
    let eachmach=instancenum/nodenum
    let mod=instancenum%nodenum
    # not 4 * x
    if [ $mod -gt 0 ]; then let eachmach++; fi;
    let endport=baseport+eachmach-1
    all_msg=""
    ct=0;
    for p in $(seq ${baseport} ${endport}); do
        for n in $nodelist; do
            # echo ${ct}
            if [ $ct -eq ${instancenum} ]; then break; fi;
            ip=$(nodeToIP $n)
            all_msg="$all_msg ${ip}:${p}"
            let ct++;
        done
    done
    for item in $all_msg; do
        echo "        - redis://$item" >> $PROMETHEUS_DIR/prometheus_copy.yml
    done
    cat $PROMETHEUS_DIR/addingmessage.yml >> $PROMETHEUS_DIR/prometheus_copy.yml
}

runprometheus(){
    generatenprometheusyaml $1 $2 $3 
    runexporter
    $PROMETHEUS_DIR/prometheus --config.file=$PROMETHEUS_DIR/prometheus_copy.yml > $OUTPUTDIR/prometheus_out.out 2>&1 &

}

stopprometheus(){
    pgrep redis_exporter | xargs kill -9
    pgrep prometheus | sudo xargs kill -9
}
# movepromethusdata(){
#     dirname=$1
#     wlt=$2
#     mkdir -p ${LOG_DIR}
#     ssh node2 "sudo chown homie ${LOG_DIR} -R"
#     mkdir -p ${LOG_DIR}/${dirname}
#     mkdir -p ${LOG_DIR}/${dirname}/$wlt

#     prometheus_dir=${LOG_DIR}/${dirname}/$wlt/prometheus
#     mkdir -p ${prometheus_dir}
#     cp /home
# }
