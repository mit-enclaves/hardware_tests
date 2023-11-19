#include "console.h"
#include <stdint.h>

#define L2_CTRL_ADDR 0x200000000
#define NUM_REGIONS 64

void dut_entry_c() {
    uint64_t *l2Ctrl = (uint64_t *) L2_CTRL_ADDR;
    
    printm("Made it here\n");

    for(int rid = 0; rid < NUM_REGIONS; rid++) {
        uint64_t base = rid * 16;
        uint64_t size = 0x4;
        printm("Setting up region %d with base %x and size %x\n", rid, base, size);
        *l2Ctrl = (rid << 14) + (base << 4) + size;
    }
    return;
}