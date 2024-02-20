.section .text

.global dut_entry
dut_entry:
  /* INPUT:
    $ra contains return address for this test; do not clobber it */

  /* OUTPUT:
    $a0 should contain:
    0 if the test FAILS
    1 if the test PASSES */

  /* Set up a trap vector */
  la t0, .new_trap_vector
  csrw mtvec, t0

  /* Define the trusted memory as two Gigas of DRAM */ 
  li t0, 0x80000000 # Set mevbase
  csrw 0x07C0, t0
  li t0, 0xFFFFFFFF80000000
//li t1, 0xFFFFFFFFFE000000
  csrw 0x07C1, t0 # Set mevmask
  
  /* Initialize meparbase and meparmask */
  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C7, t0 # Set meparbase
  li t0, 0x0000000000000000
  csrw 0x07C8, t0 # Set meparmask

  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C4, t0  # Set memrbm

  /** Enter user_program in U-mode **/
  la a0, .user_program
  j switch_u_mode
 
.user_program: 
  li t0, 0x123456789
  li t1, 0x987654321
  add t0, t0, t1
  li t2, 0x67420834
  la t0, _illegal_address_region
  lw t1, 0(t0)
  lw t2, 4(t0)
  li a0, 1 // The test is successful
  jr ra

.new_trap_vector:
  j .test_failure

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */
