.section .os_page_table , "ax", %progbits

 #ifndef OS_PT_FILE
   #error enclave_pt.bin path not defined
 #endif

 .globl root_page_table
 root_page_table:
   .incbin OS_PT_FILE