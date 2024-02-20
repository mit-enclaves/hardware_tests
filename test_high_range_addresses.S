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
//li t0, 0x80000000 # Set mevbase
  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C0, t0
//li t0, 0xFFFFFFFF80000000
//li t0, 0xFFFFFFFFFE000000
  li t0, 0x0000000000000000
  csrw 0x07C1, t0 # Set mevmask
  
  /* Initialize meparbase and meparmask */
  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C7, t0 # Set meparbase
  li t0, 0x0000000000000000
  csrw 0x07C8, t0 # Set meparmask

  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C4, t0  # Set memrbm

  /* Activate Address Translation */
  /** Set satp mode to Sv39 **/  
  # SATP_MODE: 0xFF00000000000000
  li t0, 0x8000000000000000 # Mode Sv39 is value 8

  /** Set the root page table address for unstrusted page walk **/
  la t1, root_page_table
  srl t1, t1, 0xC # Physical Address divided by 4KiB
  or t0, t0, t1
  csrw satp, t0
  
  /** Set the root page table address for trusted page walk **/
  csrw 0x07C2, t1 # Set meatp

  /** Enter user_program in U-mode **/
  la a0, .user_program
  j switch_u_mode
 
.user_program: 
  li t0, 0x80000000
  li t1, 0x180000000
  li a1, 0x67420834
  sw a1, 0(t0)
  lw a1, 0(t0)
.high_address_access:
  lw a2, 0(t1)
  sw a1, 0(t1)
  li a0, 1 // The test is successful
  jr ra

.new_trap_vector:
  j .test_failure

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */
