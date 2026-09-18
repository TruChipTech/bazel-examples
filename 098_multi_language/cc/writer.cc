// The C++ producer: writes a serialized MetricSet to a file.
#include <cstdio>
#include <fstream>

#include "metric.pb.h"

int main(int argc, char** argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: writer OUTPUT\n");
    return 2;
  }

  samples::metric::MetricSet set;

  auto* cpu = set.add_metrics();
  cpu->set_name("cpu_usage");
  cpu->set_value(0.73);
  (*cpu->mutable_labels())["host"] = "web-01";

  auto* mem = set.add_metrics();
  mem->set_name("memory_bytes");
  mem->set_value(2147483648.0);
  (*mem->mutable_labels())["host"] = "web-01";

  std::ofstream out(argv[1], std::ios::binary);
  if (!set.SerializeToOstream(&out)) {
    fprintf(stderr, "serialization failed\n");
    return 1;
  }
  printf("wrote %d metrics to %s\n", set.metrics_size(), argv[1]);
  return 0;
}
