# 301 - Bare-Metal Firmware

**Concepts:** freestanding C, linker scripts, `objcopy`, raw flash images

No OS, no libc, no `main()`. This builds bytes intended to be written directly
to flash.

## Run it

```bash
bazel build //301_baremetal_basics:boot
wc -c < bazel-bin/301_baremetal_basics/boot.bin      # 35 bytes
xxd bazel-bin/301_baremetal_basics/boot.bin | head -3
```

```
00000000: 0010 0020 0900 0008 ba1e 0000 080f be02  ... ............
00000020: 4f54 00                                  OT.
```

The first two words are the vector table - `0x20001000` (initial stack pointer)
and `0x08000009` (reset vector), little-endian. The `BOOT` string is `.rodata`.

## ELF is not a flash image

```
boot.elf   5012 bytes   headers, symbols, section table, debug info
boot.bin     35 bytes   exactly what the flash controller writes
```

`objcopy -O binary` discards the ELF container. A flash chip has no loader to
interpret program headers; address 0 of flash must be the first real byte.

Keep the ELF anyway - it carries the symbols your debugger needs. This rule
emits both, plus the linker map, in separate output groups (sample 119):

```bash
bazel build //301_baremetal_basics:boot --output_groups=linker_map
grep -E '^\.(vectors|text)' bazel-bin/301_baremetal_basics/boot.map
```

## The linker script is the memory map

```
MEMORY {
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
  SRAM  (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
}
```

On bare metal nothing else decides where code lives. Two details matter:

- **`KEEP(*(.vectors))`** - nothing in the program references the vector table,
  so the linker would garbage-collect it. The *hardware* references it.
- **`/DISCARD/ : { *(.note*) *(.comment) }`** - otherwise GNU build-id notes
  land at the start of the raw image, before your vector table, and the chip
  boots into garbage. Without this the image begins `...GNU...` instead of the
  stack pointer.

## Flags that matter

| Flag | Why |
|------|-----|
| `-ffreestanding` | No assumption that libc exists |
| `-nostdlib` | Link no startup files or default libraries |
| `-Wl,--build-id=none` | A build id would make the image non-reproducible |
| `-Os` | Flash is small |

## A note on the target

This uses `-m32` x86 because no cross-compiler is installed. A real project
registers an ARM cross-toolchain (sample 168/169) and the rule is otherwise
identical - the linker script, `objcopy` step and reproducibility concerns do
not change.

## Key takeaway

The linker script defines the image; `objcopy` strips ELF away; discard notes
or they end up at address zero.
