#include "console.h"

void pass_test() {
  print_str("[TEST] OK\n");
  send_exit_cmd(0);
  while(1){};
}

void fail_test() {
  print_str("[TEST] FAILED\n");
  send_exit_cmd(1);
  while(1){};
}

void handle_trap(uint64_t mcause, uint64_t mtval, uint64_t mepc) {
    printm("Failed to the trap handler with mcause %x mtval %llx mepc %llx", mcause, mtval, mepc);
    platform_panic();
} 
