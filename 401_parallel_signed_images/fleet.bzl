"""Build N images in parallel and sign each one, from a single declaration.

Bazel already parallelises independent actions. The job of this macro is simply
to produce targets that ARE independent - no shared mutable state, no ordering
between them - so the scheduler can run all of them at once.
"""

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("//201_oci_layout_basics:oci.bzl", "oci_image")
load("//271_sign_oci_image:sign_image.bzl", "sign_oci_image", "verify_oci_signature_test")

def signed_image_fleet(name, services, registry, private_key, public_key):
    """One call -> per service: a layer, an image, a signature and a verify test.

    Args:
      name: base name; also the name of the aggregate test_suite.
      services: dict of service name -> entrypoint script label.
      registry: registry prefix for the image reference.
      private_key: signing key label.
      public_key: verification key label.
    """
    tests = []
    images = []
    signatures = []

    for service, script in services.items():
        pkg_tar(
            name = "%s_layer" % service,
            srcs = [script],
            mode = "0755",
            package_dir = "/srv",
        )

        oci_image(
            name = "%s_image" % service,
            entrypoint = "/srv/%s" % script.lstrip(":"),
            layers = [":%s_layer" % service],
            ref = "%s/%s:v1" % (registry, service),
        )

        sign_oci_image(
            name = "%s_signature" % service,
            image = ":%s_image" % service,
            image_ref = "%s/%s:v1" % (registry, service),
            private_key = private_key,
        )

        verify_oci_signature_test(
            name = "%s_signature_test" % service,
            size = "small",
            public_key = public_key,
            signed_image = ":%s_signature" % service,
        )

        images.append(":%s_image" % service)
        signatures.append(":%s_signature" % service)
        tests.append(":%s_signature_test" % service)

    # One label that builds every image and signature - this is what CI asks
    # for, and Bazel fans it out across all available cores.
    native.filegroup(
        name = "%s_all" % name,
        srcs = images + signatures,
    )

    native.test_suite(
        name = name,
        tests = tests,
    )
