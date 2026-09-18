#include "storage.h"

#include <map>

namespace {
std::map<std::string, std::string>& Store() {
  static std::map<std::string, std::string> store;
  return store;
}
}  // namespace

std::string Load(const std::string& key) { return Store()[key]; }
void Save(const std::string& key, const std::string& value) { Store()[key] = value; }
