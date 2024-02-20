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

  la t0, _illegal_address_mega
  csrw 0x07C5, t0 # Set mparbase
  li t0, 0xFFE00000
  csrw 0x07C6, t0 # Set mparmask

  /* Activate Address Translation */
  /** Set satp mode to Sv39 and set the root page table address **/ 
  # SATP_MODE: 0xFF00000000000000
  li t0, 0x8000000000000000 # Mode Sv39 is value 8
  la t2, root_page_table
  srl t2, t2, 0xC # Physical Address divided by 4KiB
  or t0, t0, t2 
  csrw satp, t0

  /** Enter malicious_program in U-mode **/
  la a0, .malicious_program
  j switch_u_mode
 
.malicious_program: /* Tries to write at the limit of the protected range and then inside */
  la t0, _illegal_address_mega
  li t1, 0x00200000
  add t0, t0, t1
  sw zero, 0(t0)
  la t0, _illegal_address_mega
  sw zero, -4(t0)
.illegal_store: // Write the first address of the illegal Mega page
  sw zero, 0(t0)

  j .test_failure

.new_trap_vector:
  csrr t0, mcause // Check this is a Store Page Fault
  li t1, 0xF
  bne t0, t1, .test_failure

  csrr t0, mepc   // That happend during the illegal store
  la t1, .illegal_store
  bne t0, t1, .test_failure

  csrr t0, mtval  // On the illegal address
  la t1, _illegal_address_mega
  bne t0, t1, .test_failure

  li a0, 1 // The test is successful
  jr ra

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */
