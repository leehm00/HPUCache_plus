import argparse
import math



def test_for_sys(zeta, beginnum):
    result=0
    endnum=beginnum+125000000

    while (beginnum<+endnum):
        result+=1/math.pow(beginnum , zeta )
        beginnum=beginnum+1
    with open('/home/homie/share/redis/utils/cal_result.log', 'a',newline='') as f:
        print(result, file=f)

        


parser = argparse.ArgumentParser(description='Test for argparse')
parser.add_argument('--zeta', '-z', help='zeta参数，必要', required=True)
parser.add_argument('--beginnum', '-b', help='起始位置，必要参数', required=True)
# parser.add_argument('--body', '-b', help='body 属性，必要参数', required=True)
args = parser.parse_args()

if __name__ == '__main__':
    try:
        test_for_sys(float(args.zeta), int(args.beginnum))
    except Exception as e:
        print(e)


    
    