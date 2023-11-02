.section .enclave_page_table , "ax", %progbits

#ifndef ENCLAVE_PT_FILE
  #error enclave_pt.bin path not defined
#endif

.align 12

.globl enclave_pt
enclave_pt:
  .incbin ENCLAVE_PT_FILE
