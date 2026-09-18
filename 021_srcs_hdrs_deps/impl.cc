#include "private_impl.h"
#include "public_api.h"

int InternalHelper(int x) { return x * 3; }
int PublicCompute(int x) { return InternalHelper(x) + 1; }
