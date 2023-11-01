#include <stdint.h>

volatile uint64_t tohost    __attribute__((section(".htif.tohost")));
volatile uint64_t fromhost  __attribute__((section(".htif.fromhost")));

# define TOHOST_CMD(dev, cmd, payload) \
  (((uint64_t)(dev) << 56) | ((uint64_t)(cmd) << 48) | (uint64_t)(payload))

void print_char(char c) {
  // No synchronization needed, as the bootloader runs solely on core 0

  while (tohost) {
    // spin
    fromhost = 0;
  }

  tohost = TOHOST_CMD(1, 1, c); // send char
}

void print_str(char* s) {
  while (*s != 0) {
    print_char(*s++);
  }
}

void print_cntr() {
  print_str("Reached here\n");
}

void pass_test() {
  print_str("[TEST] OK\n");
  tohost = TOHOST_CMD(0, 0, 0b01); // report test done; 0 exit code
  while(1) {};
}

void fail_test() {
  /*
   * Instead of converting integers to ascii strings...
   * hardcode some print statements :')
   */
  uint64_t value;

  __asm__ volatile("csrr %0, mcause" : "=r"(value));
  if (value == 12) {
    print_str("[TEST] mcause was 12\n");
  } else if (value == 13) {
    print_str("[TEST] mcause was 13\n");
  } else {
    print_str("[TEST] mcause was ??\n");
  }

  __asm__ volatile("csrr %0, mtval" : "=r"(value));
  if (value == 0x19b5f0) {
    print_str("mtval is 0x19b5f0\n");
  } else {
    print_str("mtval is ????????\n");
  }

  __asm__ volatile("csrr %0, mepc" : "=r"(value));
  if (value == 0x20000008) {
    print_str("mepc is 0x20000008\n");
  } else {
    print_str("mepc is ??????????\n");
  }

  print_str("[TEST] FAILED\n");
  tohost = TOHOST_CMD(0, 0, 0b11); // report test done; 1 exit code
  while(1) {};
}
