#if !defined(__aarch64__)
#error "The binfmt oracle must be compiled for AArch64"
#endif

static long syscall3(long number, long arg0, long arg1, long arg2) {
    register long x0 __asm__("x0") = arg0;
    register long x1 __asm__("x1") = arg1;
    register long x2 __asm__("x2") = arg2;
    register long x8 __asm__("x8") = number;
    __asm__ volatile("svc 0"
                     : "+r"(x0)
                     : "r"(x1), "r"(x2), "r"(x8)
                     : "memory");
    return x0;
}

__attribute__((noreturn)) void _start(void) {
    static const char message[] = "A16_BINFMT_ARM64_PASS\n";
    (void)syscall3(64, 1, (long)message, sizeof(message) - 1);
    (void)syscall3(93, 0, 0, 0);
    __builtin_unreachable();
}
