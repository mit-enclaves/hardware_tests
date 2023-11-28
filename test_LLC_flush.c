#include "console.h"
#include <stdint.h>

// LLC
#define LLC_INDEX_OFFSET 6
#define LLC_NUM_WAYS 16

// Zero-device for LLC flush
#define ZERO_DEVICE_OFFSET 0x100000000

#define NUM_REGIONS 64

// ### Protection Agaisnt Side Channels
#define CSR_MSPEC  0x7ca

#define set_csr(reg, bit) _set_csr(reg, bit)
#define _set_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrs %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

#define clear_csr(reg, bit) _clear_csr(reg, bit)
#define _clear_csr(reg, bit) ({ unsigned long __tmp; \
  asm volatile ("csrrc %0, " #reg ", %1" : "=r"(__tmp) : "rK"(bit)); \
  __tmp; })

// MSPEC configuration
#define MSPEC_ALL    (0UL)
#define MSPEC_NONMEM (1UL)
#define MSPEC_NONE   (3UL)
#define MSPEC_NOTRAINPRED (4UL)
#define MSPEC_NOUSEPRED (8UL)
#define MSPEC_NOUSEL1 (16UL)

#define REGION_2_ADDR 0x86000000

#define riscv_perf_cntr_begin() asm volatile("csrwi 0x801, 1")
#define riscv_perf_cntr_end() asm volatile("csrwi 0x801, 0")

void flush_llc_region(uintptr_t start_addr, int lgsize){

    int size_index_range = 1 << lgsize;

    __attribute__((unused)) volatile uint64_t buff = 0;
    for(int stride = 0; stride < LLC_NUM_WAYS; stride++) {
        for(int i = 0; i < size_index_range; i++) {
            uintptr_t index = (size_index_range * stride) + i;
            uintptr_t addr = ZERO_DEVICE_OFFSET | start_addr | (index << LLC_INDEX_OFFSET);
            set_csr(CSR_MSPEC, MSPEC_NOUSEL1);
            buff = *((uint64_t *) addr);
            clear_csr(CSR_MSPEC, MSPEC_NOUSEL1);
        }
        asm volatile ("fence" ::: "memory");
    }
}

void dut_entry_c() {
    printm("Made it here\n");

    riscv_perf_cntr_begin();
    flush_llc_region(REGION_2_ADDR, 0x4);
    riscv_perf_cntr_end();
    
    return;
}