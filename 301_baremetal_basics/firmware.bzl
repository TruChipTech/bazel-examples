"""Bare-metal firmware: freestanding C -> ELF -> raw flash image.

There is no libc, no OS, no dynamic loader. The linker script decides the exact
memory layout, and objcopy strips the ELF container away leaving only the bytes
that get written to flash.
"""

FirmwareInfo = provider(
    doc = "A bare-metal firmware image.",
    fields = {
        "elf": "File - the linked ELF (for debugging/symbols)",
        "bin": "File - the raw flash image",
        "map": "File - the linker map",
    },
)

def _firmware_impl(ctx):
    elf = ctx.actions.declare_file(ctx.label.name + ".elf")
    binf = ctx.actions.declare_file(ctx.label.name + ".bin")
    mapf = ctx.actions.declare_file(ctx.label.name + ".map")

    srcs = ctx.files.srcs
    args = [
        ctx.file.linker_script.path,
        elf.path,
        binf.path,
        mapf.path,
        ctx.attr.arch_flag,
    ] + [s.path for s in srcs]

    ctx.actions.run_shell(
        inputs = srcs + [ctx.file.linker_script],
        outputs = [elf, binf, mapf],
        arguments = args,
        command = """
          set -euo pipefail
          ld_script="$1"; elf="$2"; bin="$3"; map="$4"; arch="$5"; shift 5
          # -ffreestanding: no libc assumptions. -nostdlib: link nothing implicit.
          # --build-id=none: a build id would land in the raw image and make it
          #                  non-reproducible.
          gcc "$arch" -ffreestanding -nostdlib -fno-pic -no-pie -Os \
              -fno-asynchronous-unwind-tables \
              -Wl,-T,"$ld_script" -Wl,--build-id=none -Wl,-Map,"$map" \
              -o "$elf" "$@" 2>&1 | grep -v 'RWX permissions' || true
          test -f "$elf"
          # Strip the ELF container: what remains is exactly what goes to flash.
          objcopy -O binary "$elf" "$bin"
        """,
        # Bazel runs actions with an EMPTY environment (`env -`), so gcc and
        # objcopy are not on PATH unless we say so. Pinning an explicit value
        # keeps the action reproducible - see sample 161.
        env = {"PATH": "/usr/bin:/bin:/usr/local/bin"},
        mnemonic = "FirmwareLink",
        progress_message = "Linking firmware %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([binf, elf, mapf])),
        FirmwareInfo(elf = elf, bin = binf, map = mapf),
        OutputGroupInfo(
            elf = depset([elf]),
            binary = depset([binf]),
            linker_map = depset([mapf]),
        ),
    ]

firmware_binary = rule(
    implementation = _firmware_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".c", ".S"], mandatory = True),
        "linker_script": attr.label(allow_single_file = [".ld"], mandatory = True),
        "arch_flag": attr.string(default = "-m32"),
    },
    provides = [FirmwareInfo],
)
