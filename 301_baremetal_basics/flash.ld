/* The linker script IS the memory map. On bare metal nothing else decides it. */
ENTRY(_start)

MEMORY {
  FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
  SRAM  (rwx) : ORIGIN = 0x20000000, LENGTH = 8K
}

SECTIONS {
  /* KEEP() stops --gc-sections discarding the vector table: nothing in the
     program references it, but the hardware does. */
  .vectors : { KEEP(*(.vectors)) } > FLASH
  .text    : { *(.text*) }         > FLASH
  .rodata  : { *(.rodata*) }       > FLASH
  .data    : { *(.data*) }         > SRAM
  .bss     : { *(.bss*) }          > SRAM

  /* Anything left here would end up in the raw image and bloat/derandomize it. */
  /DISCARD/ : { *(.note*) *(.comment) *(.eh_frame*) }
}
