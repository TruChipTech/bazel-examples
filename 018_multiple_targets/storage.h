#ifndef STORAGE_H_
#define STORAGE_H_
#include <string>
std::string Load(const std::string& key);
void Save(const std::string& key, const std::string& value);
#endif
