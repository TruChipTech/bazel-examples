#include <cstdio>
#include <fstream>

#include "capstone_config.h"
#include "telemetry.pb.h"

int main(int argc, char** argv) {
  if (argc != 2) {
    fprintf(stderr, "usage: collector OUTPUT\n");
    return 2;
  }

  capstone::telemetry::Batch batch;
  batch.set_source(CONFIG_SERVICE);

  auto* cpu = batch.add_samples();
  cpu->set_metric("cpu_usage");
  cpu->set_value(0.62);
  cpu->set_level(capstone::telemetry::LEVEL_INFO);

  auto* disk = batch.add_samples();
  disk->set_metric("disk_free_ratio");
  disk->set_value(0.08);
  disk->set_level(capstone::telemetry::LEVEL_WARN);

  std::ofstream out(argv[1], std::ios::binary);
  if (!batch.SerializeToOstream(&out)) {
    fprintf(stderr, "serialization failed\n");
    return 1;
  }

  printf("collector: service=%s environment=%s\n", CONFIG_SERVICE, CONFIG_ENVIRONMENT);
  printf("wrote %d samples to %s\n", batch.samples_size(), argv[1]);
  return 0;
}
