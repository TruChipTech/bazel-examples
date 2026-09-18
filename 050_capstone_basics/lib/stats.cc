#include "stats.h"

#include <algorithm>

double Mean(const std::vector<double>& v) {
  if (v.empty()) return 0.0;
  double sum = 0;
  for (double x : v) sum += x;
  return sum / static_cast<double>(v.size());
}

double Max(const std::vector<double>& v) {
  if (v.empty()) return 0.0;
  return *std::max_element(v.begin(), v.end());
}
