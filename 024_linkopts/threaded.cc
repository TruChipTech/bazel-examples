#include <cstdio>
#include <pthread.h>

void* Worker(void* arg) {
  int* n = static_cast<int*>(arg);
  printf("worker saw %d\n", *n);
  return nullptr;
}

int main() {
  pthread_t tid;
  int value = 7;
  pthread_create(&tid, nullptr, Worker, &value);
  pthread_join(tid, nullptr);
  printf("joined cleanly\n");
  return 0;
}
