#include "cache.h"

#include "storage.h"

std::string CachedLoad(const std::string& key) {
  static std::string last_key, last_value;
  if (key == last_key) return last_value;
  last_key = key;
  last_value = Load(key);
  return last_value;
}
