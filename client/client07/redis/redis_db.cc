//
//  redis_db.cc
//  YCSB-cpp
//
//  Copyright (c) 2021 Qianli Wang <wangep@mail.ustc.edu.cn>.
//
//


#include "redis_db.h"
#include "../core/properties.h"
#include "../core/utils.h"
#include "../core/core_workload.h"
#include "../core/db_factory.h"

#include <cstring>



namespace ycsbc {

    void RedisDB::clusterInit() {
        const utils::Properties &props = *props_;
        const std::string &format = props.GetProperty(PROP_REDIS_CLUSTER,
                PROP_REDIS_CLUSTER_DEFAULT);
        /* printf("the format = %s\n", format.c_str()); */
        /* std::string format = "true"; */
        if (format == "true") {
            method_read = &RedisDB::clusterRead;
            method_update = &RedisDB::clusterUpdate;
            method_insert = &RedisDB::clusterInsert;
            method_delete = &RedisDB::clusterDelete;
        } else {
            throw utils::Exception("unknown format");
        }
        const std::string &host_port = props.GetProperty(
                PROP_REDIS_HOST_PORT, PROP_REDIS_HOST_PORT_DEFAULT);
        /* std::string host_port = "127.0.0.1:21000"; */
        /* printf("the host and port = %s\n", host_port.c_str()); */
        this->redis_client = new RedisClient(host_port.c_str());
        if (this->redis_client == NULL || 
                this->redis_client->context() == NULL) {
            printf("cannot create link\n");
            exit(3);
        }
    }

    void RedisDB::clusterCleanup() {
        redisClusterFree(this->redis_client->context());
    }

    DB::Status RedisDB::clusterRead (const std::string &table, const std::string &key,
            const std::vector<std::string> *fields, std::vector<Field> &result) {
        redisReply* reply = NULL;
        if (fields) {
            int argc = fields->size();
            const char *argv[argc]; // the fields
            size_t argvlen[argc]; // the len of field
            argv[0] = "HMGET";
            argvlen[0] = std::strlen(argv[0]);
            argv[1] = key.c_str();
            argvlen[1] = key.length();
            int pos = 2;
            for (const std::string &f : *fields) {
                printf("%s\n", f.c_str());
                argv[pos] = f.data();
                argvlen[pos] = f.size();
                pos ++;
            }
            assert(pos == argc - 1);
            reply = (redisReply*) redisClusterCommandArgv(
                    redis_client->context(), argc, argv, argvlen
                    );
        } else {
        reply = (redisReply*) redisClusterCommand(redis_client->context(), "HGETALL %s", key.c_str());
        }
        if (reply == NULL) {
            printf("Empty Reply, the command is HGETALL %s\n", key.c_str());
            exit(3);
            freeReplyObject(reply);
            return DB::kOK;
        } else if (reply->type == REDIS_REPLY_ERROR) {
            printf("Error reply : %s\n", reply->str);
            exit(3);
        }
        if (reply->element != NULL) {
            for (size_t i = 0; i < reply->elements / 2; ++i) {
                Field tmp;
                tmp.name = reply->element[2 * i]->str;
                tmp.value = reply->element[2 * i + 1]->str;
                result.push_back(tmp);
            }
        }
        freeReplyObject(reply);
        return DB::kOK;
    }
    DB::Status RedisDB::clusterUpdate(const std::string &table, const std::string &key,
            std::vector<Field> &values) {
        std::string cmd = "HMSET";
        std::string cmd_body = "";
        cmd.append(" ").append(key);
        for (Field &p : values) {
            cmd.append(" ").append(p.name);
            cmd.append(" ").append(p.value);
        }
        /* printf("generate cmd = %s\n", cmd.c_str()); */
        redis_client->Command(cmd);
        return DB::kOK;
    }
    DB::Status RedisDB::clusterInsert(const std::string &table, const std::string &key,
            std::vector<Field> &values) {
        return this->clusterUpdate(table, key, values);
    }
    DB::Status RedisDB::clusterDelete(const std::string &table, const std::string &key) {
        std::string cmd("DEL " + key);
        redis_client->Command(cmd);
        return DB::kOK;
    }
    DB *NewRedisdbDB() {
        return new RedisDB;
    }
    const bool regisrered = DBFactory::RegisterDB("redis", NewRedisdbDB);
}


