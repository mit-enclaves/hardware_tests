.section ".data.stack"
 .align 12
 .globl stack_base, stack_ptr
 stack_base:
   .skip 0x1000
 stack_ptr: