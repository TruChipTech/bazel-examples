#include <cstdio>
#include <string>

#include "event.pb.h"

int main() {
  samples::event::Event event;
  event.set_id("evt-001");
  event.set_message("disk usage above threshold");
  event.set_severity(samples::common::SEVERITY_WARNING);
  event.mutable_occurred_at()->set_seconds(1767225600);
  event.add_tags("infra");
  event.add_tags("storage");

  // Serialize and parse back, to prove the generated code really works.
  std::string wire;
  if (!event.SerializeToString(&wire)) {
    printf("serialization failed\n");
    return 1;
  }

  samples::event::Event parsed;
  if (!parsed.ParseFromString(wire)) {
    printf("parse failed\n");
    return 1;
  }

  printf("id       : %s\n", parsed.id().c_str());
  printf("message  : %s\n", parsed.message().c_str());
  printf("severity : %d\n", static_cast<int>(parsed.severity()));
  printf("tags     : %d\n", parsed.tags_size());
  printf("wire size: %zu bytes\n", wire.size());
  return 0;
}
