#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

#include "stats.h"

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("usage: analyze DATA_FILE\n");
    return 2;
  }
  std::ifstream in(argv[1]);
  if (!in) {
    printf("cannot open %s\n", argv[1]);
    return 1;
  }
  std::vector<double> values;
  std::string line;
  while (std::getline(in, line)) {
    if (!line.empty()) values.push_back(std::atof(line.c_str()));
  }
  printf("count = %zu\n", values.size());
  printf("mean  = %.3f\n", Mean(values));
  printf("max   = %.3f\n", Max(values));
  return 0;
}
