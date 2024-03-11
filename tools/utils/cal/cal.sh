zeta=$1
beginnum=$2
result=0
# for (( i=${beginnum}; i<${beginnum}+125000000; i=i+1 )); do
#   let result=result+1/${i}**${zeta}
# done

let endnum=${beginnum}+125000000
until [ ! $beginnum -lt ${endnum} ]
do
  let tmp=1/${beginnum}**${zeta}
  let result=result+tmp
  
  beginnum=`expr $beginnum + 1`
done
echo ${result}