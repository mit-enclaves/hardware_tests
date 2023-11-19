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
  li a0, 0x91000000
  li a1, 0x92000000
  li a2, 1500
  li a3, 0
.loop:
  sb a3, 0(a0)
  sb a3, 0(a1)
  addi a3, a3, 1
  addi a0, a0, 1
  addi a1, a1, 1
  bne a3, a2, .loop

  csrw 0x801, 1
  li a3, 0
  li a0, 0x91000000
  li a1, 0x92000000
.loop2:
  lbu a4, 0(a0)
  lbu a5, 0(a1)
  mul a4, a4, a5
  sb a4, 0(a1)
  addi a3, a3, 1
  addi a0, a0, 1
  addi a1, a1, 1
  bne a3, a2, .loop2

  csrw 0x801, 0
  lw zero, 0(t0)
  li a0, 1 // The test is successful
  jr ra

.new_trap_vector:
  j .test_failure

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */
