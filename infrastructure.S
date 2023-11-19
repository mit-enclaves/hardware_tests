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