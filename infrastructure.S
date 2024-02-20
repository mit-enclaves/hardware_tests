.option norvc
.section .text.entry

.global entry
entry:

csrr a0, mhartid // Only run test on core 0
bne a0, zero, .halt

/* Set up a trap vector */
la t0, .default_trap_vector
csrw mtvec, t0

/* Clear a0 */
li a0, 0

/* Initialize Sanctum CSRs */

li t0, 0
li t1, 0xFFFFFFFFFFFFFFFF

csrw 0x7c0, t1 // Write MEVBASE
csrw 0x7c1, t0 // Write MEVMASK

csrw 0x7c3, t1 // Write MMRBM

csrw 0x7c5, t1 // Write MPARBASE
csrw 0x7c6, t0 // Write MPARMASK

/* Call into design under test */
la sp, stack_ptr
call dut_entry
/* Read test result */
beq a0, zero, .test_failed
j .test_passed

/* If the test reports as failed, print "FAIL" in the console */
.test_failed:
/* Print "FAIL" */
call fail_test
j .halt

/* If the test reports as passed, print "PASS" in the console */
.test_passed:
/* Print "PASS" */
call pass_test
j .halt

.default_trap_vector:
  csrr a0, mcause
  csrr a1, mtval
  csrr a2, mepc
  call handle_trap

# void platform_panic (uint64_t error_code) __attribute__((noreturn));
.globl platform_panic
platform_panic:
/* Halt */
.halt:
  j .halt /* spin forever, for now */

.globl switch_s_mode
switch_s_mode:
/* INPUT:
  $ a0 should contain user_program address
*/

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
  csrw mepc, a0
  mret

.globl switch_u_mode
switch_u_mode:
/* INPUT:
  $ a0 should contain user_program address
*/

  /* Switch to U-mode, jump to the protected range */
  /** Set TVM to 1, MPP to 0 (U-mode), MPIE, SIE to 0 and UIE to 1 **/
  csrr t0, mstatus
  # MSTATUS_TVM:  0x00100000
  # MSTATUS_MPP:  0x00001800
  # MSTATUS_mPIE: 0x00000080
  # MSTATUS_SIE:  0x00000002
  # MSTATUS_UIE:  0x00000001
  li t1, 0xFFFFFFFFFFEFE77C
  li t2, 0x00100001
  and t0, t0, t1
  or t0, t0, t2
  csrw mstatus, t0

  /* Set return address to malicious program mret to U-mode */
  csrw mepc, a0
  mret
