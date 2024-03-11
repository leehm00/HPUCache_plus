/*
 * WangEP: the controller for new arch
 * Using event-loop library and net module by antirez(Redis)
 */
//homietodo:the file need tobe modified
#include "sds.h"
#include "ae.h"
#include "anet.h"
#include "zmalloc.h"
#include "config.h"
#include "monotonic.h"
#include "../deps/hiredis/hiredis.h"

#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#define PORT 22000
#define LOGSIZE 1024
#define MAXSIZE 1024 * 16
#define UNUSED(V) ((void) V)
#define DEBUG 0


char err_log[LOGSIZE];


int shellCommand(char* cmd) {
    /* FILE *fp = popen(cmd, "r"); */
    /* char buffer[500]; */
    /* fgets(buffer,sizeof(buffer),fp); */
    /* printf("%s\n",buffer); */
    /* pclose(fp); */
    int retcode = system(cmd);
    if (retcode == -1) {
        printf("run error");
        return -1;
    }
    return 0;
}

// Period run task (return the frequecy(ms))
int printTimer(aeEventLoop *el, int fd, void* privdata, int mask) {
    static int count = 0;
    /* printf("the count = %d\n", count); */
    count ++;
    return 2000;
}

void clientClose(aeEventLoop *el, int fd, int err){
    if(err == 0)
        printf("Client quit: %d\n", fd);
    else if (err < 0) 
        fprintf(stderr, "Client Error: %s\n", strerror(errno));

    aeDeleteFileEvent(el, fd, AE_READABLE);
    aeDeleteFileEvent(el, fd, AE_WRITABLE);
    close(fd);
}

void sendToClient(aeEventLoop *el, int fd, void *privdata, int mask) {
    int writenLen;
    char * head = privdata;

    writenLen = write(fd, head, strlen(head));
    if (writenLen == -1){
        if(errno == ECONNRESET){
            printf("client socket closed...\n");
            clientClose(el, fd, writenLen);
        }
        else if (errno == EINTR || errno == EAGAIN){
            printf("init....continue...");
        }
        else{
            printf("write error...\n");
            clientClose(el, fd, writenLen);
        }
    }

    else if (writenLen == 0){
        printf("client socket closed...\n");
        clientClose(el, fd, writenLen);
    }

    else{
        aeDeleteFileEvent(el, fd, AE_WRITABLE);
        printf("write finished...\n");
        printf("write cnt:\n");
        printf("%s\n", head);
    }

}

void moveOneSlotToDest(int slot, char* source, char* target, char* worker_ip, int worker_port) {
    printf("slot:%d\nip:%s\nport:%d\nsrc:%s\ndest:%s\n",
            slot, worker_ip, worker_port, source, target);
    char *cli_bin = "/home/wangep/share/bin/redis-cli";
    sds cmd = sdscatprintf(sdsempty(), 
            "%s --cluster slot %s:%d --cluster-aim-slot %d --cluster-from %s --cluster-to %s", 
            cli_bin, worker_ip, worker_port, slot, source, target);
    printf("cmd = %s\n", cmd);
    shellCommand(cmd);
}

void moveSlotHandler(char* buf) {
    char* buf_dup = (char*) malloc(sizeof(char) * strlen(buf));
    strcpy(buf_dup, buf);
    char* token = strtok(buf_dup, ":");
    UNUSED(token);
    int slot = atoi(strtok(NULL, " "));
    char* ip = strtok(NULL, " ");
    int port = atoi(strtok(NULL, " "));
    char* src = strtok(NULL, " ");
    char* dest = strtok(NULL, " ");
    moveOneSlotToDest(slot, src, dest, ip, port);

}

void dealBuffer(char* buffer) {
    /* char *buffer = "MOVE: 0 127.0.0.1 21006 c188d64642422b2339675c5f1a84b76e55def343 6e4df6bc82a0f50f8f039a0e94990ab9c93c7a01"; */
    if (!strncmp(buffer, "MOVE", 4)) {
        printf("%s\n", buffer);
        moveSlotHandler(buffer);
    } else {
        printf("error command\n");
    }
}

void readFromClient(aeEventLoop *el, int fd, void *privdata, int mask) {
    int nread, readlen;
    sds buffer = sdsempty();
    readlen = MAXSIZE;
    buffer = sdsMakeRoomFor(buffer, readlen);
    // FIXME: MAY HAVE BUG! Only can read 1024 * 16 Byte
    // But it's enough for normal situation;
    nread = anetRead(fd, buffer, readlen);
    if (nread < 0) {
        if(errno == EWOULDBLOCK || errno == EAGAIN)
            printf("read finished...\n");
        else if(errno == EINTR)
            printf("initevent....continue...");
        else
            clientClose(el, fd, nread);
    } else if (nread == 0) {
        printf("Client close connection!\n");
        clientClose(el, fd, nread);
        return;
    }

    dealBuffer(buffer);

    char* ret = "OK";
    if (aeCreateFileEvent(el, fd, AE_WRITABLE, 
                sendToClient, ret) == AE_ERR) {
        fprintf(stderr, "set writeable fail: %d\n", fd);
    }
}


void acceptTcpHandlers(aeEventLoop *el, int fd, void *privdata, int mask){
    int cfd, cport;
    char cip[46];
    cfd = anetTcpAccept(err_log, fd, cip, sizeof(cip), &cport);
    if (cfd == ANET_ERR) {
        if (errno != EWOULDBLOCK)
            printf("Accepting client connection: %s", err_log);
        return;
    }
    if (anetNonBlock(err_log, cfd) == ANET_ERR) {
        fprintf(stderr, "set nonblock error: %d\n", cfd);
    }
    if (anetEnableTcpNoDelay(err_log, cfd) == ANET_ERR) {
        fprintf(stderr, "set nodelay error: %d\n", cfd);
    } 
    if (DEBUG)
        printf("Accept client %s:%d", cip, cport);
    if (aeCreateFileEvent(el, cfd, AE_READABLE, 
                readFromClient, NULL) == AE_ERR) {
        fprintf(stderr, "client connect fail: %d\n", cfd);
        close(cfd);
    }
}



int main() {
    int fd = 0;
    printf("Start Controller!\n");

    /* redisContext *redis_ctx = redisConnect("127.0.0.1", 21000); */
    /* redisReply *reply = (redisReply*) redisCommand(redis_ctx, "cluster nodes"); */
    /* printf("the ret str = %s\n", reply->str); */
    /* freeReplyObject(reply); */

    aeEventLoop * controller_loop = aeCreateEventLoop(1024);
    if ((fd = anetTcpServer(err_log, PORT, NULL, 3)) == AE_ERR) {
        fprintf(stderr, "Open port %d error: %s\n", PORT, err_log);
    }
    if (aeCreateFileEvent(controller_loop, fd, AE_READABLE, 
                acceptTcpHandlers, NULL) == AE_ERR) {
        fprintf(stderr, "Unrecoverable error creating server.ipfd file event.");
    }
    aeCreateTimeEvent(controller_loop, 1, printTimer, NULL, NULL);
    aeMain(controller_loop);
    aeDeleteEventLoop(controller_loop);
    printf("Exit the controller \n");
    return 0;
}

