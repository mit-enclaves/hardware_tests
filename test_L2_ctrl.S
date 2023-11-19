.section .text

.global dut_entry
dut_entry:
  /* INPUT:
    $ra contains return address for this test; do not clobber it */
  
  /* OUTPUT:
  $a0 should contain:
  0 if the test FAILS
  1 if the test PASSES */

  # Save $ra on the stack
  addi sp, sp, -16    # Allocate space on the stack (16-byte aligned)
  sd ra, 8(sp)        # Store $ra on the stack

  call dut_entry_c

  # Restore $ra from the stack
  ld ra, 8(sp)        # Load $ra from the stack
  addi sp, sp, 16     # Deallocate space from the stack
  
  li a0, 1
  jr ra /* return to caller */