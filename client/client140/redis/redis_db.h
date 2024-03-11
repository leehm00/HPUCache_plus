//
//  redis_db.h
//  YCSB-cpp
//
//  Copyright (c) 2021 Qianli Wang <wangep@mail.ustc.edu.cn>.
//

#ifndef YCSB_C_REDIS_DB_H_
#define YCSB_C_REDIS_DB_H_

#include "../core/db.h"
#include "redis_client.h"

#include <iostream>
#include <string>
#include <mutex>
#include <vector>

namespace {
    const std::string PROP_NAME = "redis.dbname";
    const std::string PROP_NAME_DEFAULT = "/tmp/redis";

    const std::string PROP_REDIS_HOST_PORT = "redis.hostport";
    const std::string PROP_REDIS_HOST_PORT_DEFAULT= "127.0.0.1:21000";

    const std::string PROP_REDIS_CLUSTER = "redis.cluster";
    const std::string PROP_REDIS_CLUSTER_DEFAULT= "true";
} // anonymous

namespace ycsbc {
    class RedisDB : public DB {
        public:
            RedisDB() {}
            ~RedisDB() {}

            void Init() {
                clusterInit();
            }

            void Cleanup() {
                clusterCleanup();
            }

            Status Read(const std::string &table, const std::string &key,
                    const std::vector<std::string> *fields, std::vector<Field> &result) {
                return (this->*(method_read))(table, key, fields, result);
            }
            Status Scan(const std::string &table, const std::string &key, int len,
                    const std::vector<std::string> *fields, std::vector<std::vector<Field>> &result) {
                throw "Scan: Function Not Implemented";
            }
            Status Update(const std::string &table, const std::string &key, std::vector<Field> &values) {
                return (this->*(method_update))(table, key, values);
            }
            Status Insert(const std::string &table, const std::string &key, std::vector<Field> &values) {
                return (this->*(method_insert))(table, key, values);
            }
            Status Delete(const std::string &table, const std::string &key) {
                return (this->*(method_delete))(table, key);
                throw "Delete: Function Not Implemented";
            }
        private:
            RedisClient *redis_client;

            // function interface
            void clusterInit();
            void clusterCleanup();

            Status (RedisDB::*method_read)(const std::string &, const std:: string &,
                    const std::vector<std::string> *, std::vector<Field> &);
            Status (RedisDB::*method_update)(const std::string &, const std::string &,
                    std::vector<Field> &);
            Status (RedisDB::*method_insert)(const std::string &, const std::string &,
                    std::vector<Field> &);
            Status (RedisDB::*method_delete)(const std::string &, const std::string &);

            // working function
            Status clusterRead(const std::string &table, const std::string &key,
                    const std::vector<std::string> *fields, std::vector<Field> &result);
            Status clusterUpdate(const std::string &table, const std::string &key,
                    std::vector<Field> &values);
            Status clusterInsert(const std::string &table, const std::string &key,
                    std::vector<Field> &values);
            Status clusterDelete(const std::string &table, const std::string &key);
    };

DB *NewRedisdbDB();

}

#endif
