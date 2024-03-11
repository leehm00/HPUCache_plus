# HPUCache and HPUCache+

The Code for **HPUCache: Toward High Performance and Resource Utilization in Clustered Cache via Data Copying and Instance Merging** 

and **Enabling High Performance and Resource Utilization in Clustered Cache**

## Directory Structure

```
.
├── client -> A Redis Client forked from vipshop/hiredis-vip. 
├── server -> A Redis server modification from offical version 6.22 with basic hot data copy and cold instance merge
├── consistcode -> A Redis server modification from above server, adding more consistency levels
├── monitorcode -> A Redis server modification from above server, adding dynamic monitor and dynamic copy strategy
└── tools  -> some tools used in experiment.
```

## Compile 

We use make to build our system. 

### Client

Different number after client implies different Zipfian Coefficiency.

For example,

``` bash
cd ./client/client01
make -j
```

will compile a client  with Zipfian Coefficiency 0.1.

### consistcode

```sh
cd ./consistcode/server
./build.sh
```

### monitorcode

```
cd ./monitorcode/server
./build.sh
```

## Run

We build the Redis cluster and run experiment via bash script in
 ```./tools/utils```.

We have five experiments.

```
./tools/utils/baseline_scaling.sh -> Figure 2/3
./tools/utils/new_exp1.sh -> Figure 8/10/11
./tools/utils/new_exp2.sh -> Figure 12
./tools/utils/new_exp3.sh -> Figure 9
./tools/utils/new_exp4.sh -> Figure 9/13
./tools/utils/new_exp5.sh -> Figure 17
./tools/utils/new_exp6_cli_num.sh -> Table 1
./tools/utils/new_exp8_keysize.sh -> Figure 14
./tools/utils/new_exp9_consist.sh -> Figure 18
```
