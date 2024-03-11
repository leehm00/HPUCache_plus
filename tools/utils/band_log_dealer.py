#!/usr/bin/python3

import sys

NET_FILE=sys.argv[1]
f=open(NET_FILE, "r");
f_list = f.readlines();
f.close();

i = 0
sum0=0
sum= 0
sum2=0

while (i < len(f_list)):
    ins = f_list[i].split();
    del ins[0];
    tmp=0;
    for j in ins:
        tmp=tmp+float(j);
    ave=tmp/len(ins);
    sum=sum+ave;
    sum0=sum0+float(ins[0]);
    i+=1

print(NET_FILE,sum0/8,sum/8)

