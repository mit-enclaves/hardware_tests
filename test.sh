#!/bin/bash

PROCNAME=RV64G_OOO.core_2.core_SMALL.cache_LARGE.tso.l1_cache_lru.secure_flush.check_deadlock

$RISCY_HOME/procs/build/$PROCNAME/verilator/bin/ubuntu.exe \
  --core-num 2 \
  --mem-size 2048 \
  --rom $RISCY_HOME/procs/rom/out/rom_core_2 \
  --elf build/test_sanctum_low_va.elf \
  > debug.log
