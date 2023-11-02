.section .os_page_table , "ax", %progbits

#ifndef OS_PT_FILE
  #error enclave_pt.bin path not defined
#endif

.align 12

.globl os_pt
os_pt:
  .incbin OS_PT_FILE
