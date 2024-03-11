//
// A C++ Redis client that wraps hiredis
// Support redis cluster mode
// Qianli Wang <wangep@mail.ustc.edu.cn>
//

#ifndef YCSB_C_REDIS_CLIENT_H_
#define YCSB_C_REDIS_CLIENT_H_

#include <iostream>
#include <string>
#include <signal.h>
#include "hiredis-cluster/hircluster.h"

namespace ycsbc {
    /* struct timeval REDIS_DEFAULT_TIMEOUT = {15, 0}; // 15s */

    class RedisClient {
        public:
            /* RedisClient(const char *host_port) : RedisClient(host_port, REDIS_DEFAULT_TIMEOUT) {}; */
            RedisClient(const char *host_port);
            ~RedisClient();

            int Command(std::string cmd);

            redisClusterContext *context() { return context_; }
        private:
            void HandleError(redisReply *reply, const char *hint);
            redisClusterContext *context_;
    };

    //
    // Implementation
    //

    inline RedisClient::RedisClient(const char *host_port) {
        signal(SIGPIPE, SIG_IGN);
        struct timeval timeout = {15,0};
        context_ = redisClusterContextInit();
        redisClusterSetOptionAddNodes(context_, host_port);
        redisClusterSetOptionConnectTimeout(context_, timeout);
        redisClusterSetOptionRouteUseSlots(context_);
        redisClusterConnect2(context_);
        if (context_ && context_->err) {
            printf("Error: %s\n", context_->errstr);
            // handle error
            exit(-1);
        }
    }

    inline RedisClient::~RedisClient() {
        if (context_) {
            redisClusterFree(context_);
        }
    }

    inline int RedisClient::Command(std::string cmd) {
        redisReply *reply = 
            (redisReply *)redisClusterCommand(context_, cmd.c_str());

        if (reply == NULL) {
            printf("Empty Reply, the command is %s\n", cmd.c_str());
            exit(3);
        } else if (reply->type == REDIS_REPLY_ERROR) {
            HandleError(reply, cmd.c_str());
        }
        freeReplyObject(reply);
        return 0;
    }

    inline void RedisClient::HandleError(redisReply *reply, const char *hint) {
        std::cerr << hint << " error: " << this->context_->errstr << std::endl;
        if (reply) freeReplyObject(reply);
        redisClusterFree(this->context_);
        exit(2); 
    }

} // namespace ycsbc

#endif // YCSB_C_REDIS_CLIENT_H_
