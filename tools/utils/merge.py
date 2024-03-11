#!/usr/bin/python3

HOTFILE="./hotness.log"

HOT_THRESHOLD=60

def getKey(x):
    return float(x[1])
f=open(HOTFILE, "r");
f_content  = f.readlines();
f.close()
f_content=[ _.strip().split() for _ in f_content ]
f_content.sort(key=getKey)
# print(f_content)
# print(f_content[:2])
# print(sum(f_content[:2], key=getKey))

merge_group=[]
tmp_group=[]
hotness=0.0
for i in f_content:
    # print(getKey(i))
    if (hotness + getKey(i) < HOT_THRESHOLD):
        tmp_group.append(i[0])
        hotness += getKey(i);
    else:
        tmp_group.append(hotness);
        # print(tmp_group)
        merge_group.append(tmp_group);
        tmp_group = []
        hotness=0.0
        tmp_group.append(i[0])
        hotness += getKey(i);

tmp_group.append(hotness);
merge_group.append(tmp_group);
# print(tmp_group)

# print(merge_group)
for k in merge_group:
    if (len(k) <= 2):
        continue
    a = ""
    index = 1;
    while(index < len(k) - 1):
        a += ","
        a += k[index]
        index += 1;
    a += "_"
    a += k[0]
    print (a[1:])


# for i in f_content:
#     print(i)
