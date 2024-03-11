#include "hircluster.h"
#include <stdio.h>
#include <stdlib.h>

void printNodes(dict* nodes) {
    dictIterator di;
    dictEntry *de;
    dictInitIterator(&di, nodes);
    cluster_node * node;
    while ((de = dictNext(&di)) != NULL) {
        node = dictGetEntryVal(de);
        printf("addr = %s\n", node->addr);
    }
}

int main(int argc, char **argv) {
    UNUSED(argc);
    UNUSED(argv);
    struct timeval timeout = {1, 500000}; // 1.5s

    redisClusterContext *cc = redisClusterContextInit();
    redisClusterSetOptionAddNodes(cc, "127.0.0.1:21000");
    redisClusterSetOptionConnectTimeout(cc, timeout);
    redisClusterSetOptionRouteUseSlots(cc);
    redisClusterConnect2(cc);
    if (cc && cc->err) {
        printf("Error: %s\n", cc->errstr);
        // handle error
        exit(-1);
    }
    redisReply *reply = NULL;
    
    for (int i = 0; i < 50; ++i) {
        /* reply = (redisReply *)redisClusterCommand(cc, "SET %s%d %d", "{8}", i, i); */
        /* printNodes(cc->nodes); */
        reply = (redisReply *)redisClusterCommand(cc, "set {7}%d %d", i, i);
        printf("node addr for slot 1716: %s\n", cc->table[1716]->addr);
        /* printNodes(cc->nodes); */
        printf("SET: %s\n", reply->str);
        if (reply->type == REDIS_REPLY_ERROR)
            printf("ERROR: %d\n", reply->type);
    }
    
    freeReplyObject(reply);

    /* redisReply *reply2 = (redisReply *)redisClusterCommand(cc, "GET %s", "{7}a"); */
    /* printf("GET: %s\n", reply2->str); */
    /* freeReplyObject(reply2); */

    redisClusterFree(cc);
    return 0;
}
