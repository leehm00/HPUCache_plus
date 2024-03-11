#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "../deps/hiredis/hiredis.h"
#include "../deps/hiredis/async.h"
#include "../deps/hiredis/adapters/libevent.h"


void getCallback(redisAsyncContext *c, void *r, void *privdata) {
    redisReply *reply = r;
    if (reply == NULL) {
        if (c->errstr) {
            printf("errstr: %s\n", c->errstr);
        }
        return;

    }
    printf("need:%s, read %s\n", (char*)privdata, reply->str);

    /* Disconnect after receiving the reply to GET */
    /* redisAsyncDisconnect(c); */

}

void connectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;

    }
    printf("Connected...\n");

}

void disconnectCallback(const redisAsyncContext *c, int status) {
    if (status != REDIS_OK) {
        printf("Error: %s\n", c->errstr);
        return;

    }
    printf("Disconnected...\n");

}

typedef struct HotGroupNode {
    char* host;
    int port;
    redisAsyncContext* ractx;
} HotGroupNode;

struct HotGroupNode hg_instance[] = {
    {"127.0.0.1", 21007, NULL}, 
    {"127.0.0.1", 21008, NULL}
};

const int OP_NUM=1;

int main (int argc, char **argv) {
    int scale = sizeof(hg_instance) / sizeof(hg_instance[1]);
    struct event_base *base = event_base_new();
    // Link Phase
    
    for (int i = 0; i < scale; ++i) {
        hg_instance[i].ractx = redisAsyncConnect(
                hg_instance[i].host,
                hg_instance[i].port
                );
        if (hg_instance[i].ractx->err) {
            /* Let *c leak for now... */
            printf("Error: %s\n", hg_instance[i].ractx->errstr);
            return 1;
        }
        redisLibeventAttach(hg_instance[i].ractx, base);
        redisAsyncSetConnectCallback(hg_instance[i].ractx, connectCallback);
        redisAsyncSetDisconnectCallback(hg_instance[i].ractx, disconnectCallback);
    }

    HotGroupNode* send = &(hg_instance[0]);
    for (int i = 0; i < OP_NUM; ++i) {
        char snd[100];
        sprintf(snd, "VALUE%d", i);
        printf("send\n");
        redisAsyncCommand(send->ractx, NULL, NULL, "SET {7}%d %s", i, snd);
        /* sleep(1); */
        usleep(100 * 1000);
        printf("deal\n");
        for (int j = 1; j < scale; ++j) {
            redisAsyncCommand(hg_instance[j].ractx, getCallback, &snd, "GET {7}%d", i);
        }
    }
    

    /* unsigned int j, isunix = 0; */
    /* redisReply *reply; */
    /* const char *hostname = (argc > 1) ? argv[1] : "127.0.0.1"; */
    /* int port = (argc > 2) ? atoi(argv[2]) : 21007; */


    /* redisAsyncContext *c = redisAsyncConnect(hostname, port); */
    /* if (c->err) { */
    /*     /1* Let *c leak for now... *1/ */
    /*     printf("Error: %s\n", c->errstr); */
    /*     return 1; */

    /* } */
    /* redisLibeventAttach(c,base); */
    /* redisAsyncSetConnectCallback(c,connectCallback); */
    /* redisAsyncSetDisconnectCallback(c,disconnectCallback); */

    /* for (int i = 0; i < 100; ++i) { */
    /*     redisAsyncCommand(c, NULL, NULL, "SET {7}%d %d", i, i); */
    /*     redisAsyncCommand(c, getCallback, &i, "GET {7}xa"); */

    /* } */

    /* /1* redisAsyncCommand(c, NULL, NULL, "SET ${7}a a"), argv[argc-1], strlen(argv[argc-1])); *1/ */
    /* /1* sleep(2); *1/ */

    for (int i = 0; i < scale; ++i) {
        redisAsyncDisconnect(hg_instance[i].ractx);
    }
    event_base_dispatch(base);

    return 0;

}

