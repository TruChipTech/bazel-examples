# This file becomes the BUILD file of the @zlib_src repository. The downloaded
# archive has no Bazel support of its own, so we supply one.
load("@rules_cc//cc:defs.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "zlib",
    srcs = glob(["*.c"], exclude = ["example.c", "minigzip.c"]),
    hdrs = glob(["*.h"]),
    copts = [
        "-w",  # third-party code: do not enforce our warning settings
        "-DHAVE_UNISTD_H",
    ],
    includes = ["."],
)

filegroup(
    name = "all_files",
    srcs = glob(["**"]),
)
