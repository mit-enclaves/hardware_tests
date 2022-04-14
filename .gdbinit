set arch riscv:rv64
layout split
foc cmd
set trace-commands on
set logging on
target remote localhost:1234
#add-symbol-file test_untrusted_load.elf
