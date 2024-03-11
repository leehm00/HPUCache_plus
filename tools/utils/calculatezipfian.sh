source /home/homie/share/redis/utils/0_parameters.sh
source /home/homie/share/redis/utils/1_build_redis_cluster.sh

zeta=2
bct=0

base=0
totalnum=80
nodenum=2
nodelist=$(selectNode ${nodenum})
let eachmach=totalnum/nodenum
let mod=totalnum%nodenum
if [ $mod -gt 0 ]; then let eachmach++; fi;
calculatebin="/home/homie/share/redis/utils/cal"
let end=base+eachmach-1

ct=0;
for p in $(seq ${base} ${end}); do
    for n in $nodelist; do
        # echo ${ct}
        if [ $ct -eq ${totalnum} ]; then break; fi;
        # ip=$(nodeToIP $n)
        let beginnum=${ct}*125000000+1
        ssh $n "python3 ${calculatebin}/calculate.py  -z ${zeta} -b ${beginnum} >> ${calculatebin}/result.txt  2>&1 &"
        let ct++;
    done
    let bct++;
done



# ssh $n "cpulimit -- taskset -c ${bct} ${REDIS_SERVER_BIN} ${conf_file} > /dev/null 2>&1 &"