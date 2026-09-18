#include <cstdio>
#include <fstream>
#include <memory>
#include <string>

#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

int main(int argc, char** argv) {
  std::string error;
  // Create() uses argv[0] plus the environment to find the runfiles tree.
  // This works under `bazel run`, `bazel test`, and when the binary is
  // executed directly from bazel-bin - which hard-coded paths do not.
  std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
  if (runfiles == nullptr) {
    printf("failed to init runfiles: %s\n", error.c_str());
    return 1;
  }

  // The key is always "<workspace_or_module_name>/<workspace-relative path>".
  std::string path =
      runfiles->Rlocation("_main/080_cc_runfiles/message.txt");

  std::ifstream in(path);
  if (!in) {
    printf("could not open resolved path: %s\n", path.c_str());
    return 1;
  }
  std::string line;
  std::getline(in, line);
  printf("resolved: %s\n", path.c_str());
  printf("contents: %s\n", line.c_str());
  return 0;
}
