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
  la t0, .default_trap_vector
  csrw mtvec, t0

  /* Define the enclave memory as 32MB, starting at 0x20000000 */
  li t0, 0x20000000 # Set mevbase
  csrw 0x07C0, t0
  li t0, 0xfffffffffe000000
  csrw 0x07C1, t0 # Set mevmask

  li t0, 0xffffffffffffffff
  csrw 0x07C4, t0  # Set memrbm

  /* Define no protected memory region */
  la t0, 0xffffffffffffffff
  csrw 0x07C7, t0 # Set meparbase
  li t0, 0x0
  csrw 0x07C8, t0 # Set meparmask

  /* Activate Address Translation */
  /** Set satp mode to Sv39 **/
  # SATP_MODE: 0xFF00000000000000
  li t0, 0x8000000000000000 # Mode Sv39 is value 8
  la t1, root_page_table
  srl t1, t1, 0xC # Physical Address divided by 4KiB
  or t0, t0, t1
  csrw satp, t0

  /** Set the root page table address for enclave page walk **/
  la t1, enclave_page_table
  srl t1, t1, 0xC
  csrw 0x07C2, t1 # Set meatp

  /* Switch to S-mode, jump to the protected range */
  /** Set mPP to 1 (S-mode), sIE to 1, mPIE to 0 and TVM to 1 **/
  /*
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
  */

  /* Set to launch enclave in U mode */
  // Set TVM to 1, MPP to 0 (U mode), MPIE, SIE to 0, UIE to 1
  // MSTATUS_TVM_MASK   (0x00100000)
  // MSTATUS_MPP_MASK   (0x00001800)
  // MSTATUS_MPP_OFFSET (11)
  // MSTATUS_MPIE_MASK  (0x00000080)
  // MSTATUS_MIE_MASK   (0x00000008)
  // MSTATUS_SIE_MASK   (0x00000002)
  // MSTATUS_UIE_MASK   (0x00000001)
  csrr t0, mstatus
  li t1, 0x00100000
  or t0, t0, t1 // |=  TVM_Mask

  li t1, 0xffffffffffffe7ff
  and t0, t0, t1 // &= ~MPP Mask

  li t1, 0xffffffffffffff7f
  and t0, t0, t1 // &= ~MPIE Mask

  li t1, 0xfffffffffffffffd
  and t0, t0, t1 // &= ~SIE Mask

  li t1, 0x00000001
  or t0, t0, t1 // |=  UIE Mask

  li t1, 0
  csrw mstatus, t0
  
  /* Set return address to user program mret to U-mode */
  la t0, 0x20000000
  csrw mepc, t0
  mret

.default_trap_vector:
  csrr t0, mcause // Check if this is an ECALL
  li t1, 0x8
  bne t0, t1, .test_failure
  
  // Test succeeded
  li a0, 1
  jr ra

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */

.section .text.enclave_program
.global enclave_program
enclave_program:
  li t0, 0x19b5f0
  lw t1, 0(t0)

  // Successful test
  ecall
