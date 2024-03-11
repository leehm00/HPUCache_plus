#!/usr/bin/python3

import sys

SLOT_FILE=sys.argv[1]
f=open(SLOT_FILE, "r");
f_list = f.readlines();
f.close();

slot_hotness = [0]*16384;
i = 0
while (i < len(f_list)):
    before = f_list[i]
    after = f_list[i+1]
    before = before.strip().split()[1].split(",")[:-1]
    after = after.strip().split()[1].split(",")[:-1]
    before = [_.split("_") for _ in before ]
    after = [_.split("_") for _ in after]
    if (len(before) != len(after)):
        print(len(before))
        print(len(after))
        print(i)
    assert(len(before) == len(after));

    for m in range(0, len(before)):
        sub = int(after[m][1]) - int(before[m][1])
        index = int(before[m][0])
        if (sub != 0):
            assert(slot_hotness[index] == 0);
            slot_hotness[index] = sub;
    i += 2

for i in range(0, len(slot_hotness)):
    print(i, slot_hotness[i]);


