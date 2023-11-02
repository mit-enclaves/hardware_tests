.section .enclave_page_table , "ax", %progbits

#ifndef ENCLAVE_PT_FILE
  #error enclave_pt.bin path not defined
#endif

.globl enclave_page_table
enclave_page_table:
  .incbin ENCLAVE_PT_FILE
