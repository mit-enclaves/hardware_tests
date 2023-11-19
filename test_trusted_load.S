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

  /* Switch to S-mode, jump to the protected range */
  /** Set mPP to 1 (S-mode), sIE to 1, mPIE to 0 and TVM to 1 **/
  csrr t0, mstatus
  # MSTATUS_TVM:  0x00100000
  # MSTATUS_MPP:  0x00001800
  # MSTATUS_mPIE: 0x00000080
  # MSTATUS_SIE:  0x00000002
  li t1, 0xFFFFFFFFFFEFE77D
  li t2, 0x00100802
  and t0, t0, t1
  or t0, t0, t2
  csrw mstatus, t0

  /* Set return address to malicious program mret to S-mode */
  la t0, .user_program
  csrw mepc, t0
  mret
 
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
