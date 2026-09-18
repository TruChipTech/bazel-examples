/* A freestanding program. No main(), no libc, no runtime. */

#define UART_TX ((volatile unsigned int *)0x40000000)

/* The vector table must sit at the very start of flash: the CPU reads the
   initial stack pointer and reset vector from the first two words. */
__attribute__((section(".vectors"), used))
const unsigned long vectors[2] = {
    0x20001000UL,  /* initial stack pointer */
    0x08000009UL,  /* reset vector -> _start (thumb bit set on real ARM) */
};

static void uart_put(char c) { *UART_TX = (unsigned int)c; }

void _start(void) {
    const char *msg = "BOOT";
    while (*msg) uart_put(*msg++);
    for (;;) { /* spin forever - there is nothing to return to */ }
}
