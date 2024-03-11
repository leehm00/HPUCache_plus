#include <iostream>
#include <string>
#include <vector>
/* #include "redis_client.h" */
#include "redis_db.h"

using namespace std;
using namespace ycsbc;

int main(int argc, const char *argv[]) {
  const char *host_port = (argc > 1) ? argv[1] : "10.0.0.51:21000";

  RedisClient *client = new RedisClient(host_port);
  if (client->context() == NULL) {
      printf("err\n");
      return 0;
  }

  client->Command("set a b");

  /* RedisDB *db = new RedisDB(); */
  /* db->Init(); */
  /* string key = "Wang"; */
  /* DB::Field field1; */
  /* field1.name = "field1"; */
  /* field1.value = "Er"; */
  /* DB::Field field2; */
  /* field2.name = "field2"; */
  /* field2.value = "Pang"; */
  /* vector<DB::Field> values; */
  /* values.push_back(field1); */
  /* values.push_back(field2); */

  /* db->Insert(key, key, values); */

  /* vector<DB::Field> result; */
  /* db->Read(key, key, NULL, result); */
  /* for (auto &p : result) { */
  /*   cout << p.name << '\t' << p.value << endl; */
  /* } */

  /* result[1].value = "HelloWorld!"; */
  /* db->Update(key, key, result); */

  /* result.clear(); */
  /* db->Read(key, key, NULL, result); */
  /* for (auto &p : result) { */
  /*   cout << p.name << '\t' << p.value << endl; */
  /* } */
  /* db.Read(key, key, nullptr, result); */
  /*  for (auto &p : result) { */
  /*   cout << p.first << '\t' << p.second << endl; */
  /* } */

  /* db.Delete(key, key); */
  /* result.clear(); */
  /* db.Read(key, key, nullptr, result); */
  /* cout << "After delete: " << result.size() << endl; */
  return 0;
}
