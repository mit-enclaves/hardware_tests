remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
HW_TESTS_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR:=$(HW_TESTS_DIR)/build

HW_TESTS_NAMES :=  $(notdir $(basename $(wildcard $(HW_TESTS_DIR)/test_*)))
HW_TESTS_ELFS := $(addprefix $(BUILD_DIR)/, $(addsuffix .elf, $(HW_TESTS_NAMES)))
HW_TESTS_TASKS := $(addsuffix .task, $(HW_TESTS_NAMES))
HW_TESTS_DEBUG := $(addsuffix .debug, $(HW_TESTS_NAMES))
HW_TESTS_TASKSIM := $(addsuffix .tasksim, $(HW_TESTS_NAMES))
HW_TESTS_TASKFPGA := $(addsuffix .taskfpga, $(HW_TESTS_NAMES))
ENCLAVE_PT_FILE := $(BUILD_DIR)/enclave_pt.bin
OS_PT_FILE := $(BUILD_DIR)/idpt.bin
HW_TESTS_PT := $(OS_PT_FILE)

CC:=riscv64-unknown-elf-gcc
#CC:=riscv64-unknown-linux-gnu-gcc
OBJCOPY:=riscv64-unknown-linux-gnu-objcopy
OBJDUMP:=riscv64-unknown-elf-objdump

CCFLAGS := -march=rv64g -mcmodel=medany -mabi=lp64 -nostdlib -nostartfiles -fno-common -fno-tree-loop-distribute-patterns -std=gnu11 -static -ggdb3 -O0 -Wall
QEMU_FLAGS := -smp cpus=2 -machine sanctum -m 2G -nographic

.PHONY: check_env_qemu
check_env_qemu:
ifndef SANCTUM_QEMU
	$(error SANCTUM_QEMU is undefined)
endif

.PHONY: check_env_riscy
check_env_riscy:
ifndef RISCY_HOME
	$(error RISCY_HOME is undefined)
endif

BOOT_LD := $(HW_TESTS_DIR)/null_boot.lds

# Build dir
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Null Boot Loadder
NULL_BOOT_BINARY := $(BUILD_DIR)/null_boot.bin
NULL_BOOT_ELF := $(BUILD_DIR)/null_boot.elf

BOOT_SRC := \
       $(HW_TESTS_DIR)/null_boot.S

# Rules
$(NULL_BOOT_ELF): $(BOOT_SRC) $(BOOT_LD) $(BUILD_DIR)
	$(CC) $(CCFLAGS) -T $(BOOT_LD) $(BOOT_SRC) -o $@

$(NULL_BOOT_BINARY): $(NULL_BOOT_ELF)
	$(OBJCOPY) -O binary --only-section=.boot  $< $@

.PHONY: null_bootloader
null_bootloader: $(NULL_BOOT_BINARY)

# Identity Page Table 
$(OS_PT_FILE): $(HW_TESTS_DIR)/make_idpt.py $(BUILD_DIR)
	@echo "Building identity page tables for hw_tests"
	cd $(BUILD_DIR) && python $(HW_TESTS_DIR)/make_idpt.py

COMMON_SRC := $(HW_TESTS_DIR)/infrastructure.c $(HW_TESTS_DIR)/infrastructure.S $(HW_TESTS_DIR)/stack.S $(HW_TESTS_DIR)/console.c $(HW_TESTS_DIR)/os_pt.S

# Elf Files
$(BUILD_DIR)/%.elf: $(OS_PT_FILE) $(HW_TESTS_DIR)/%.S $(COMMON_SRC)
	@mkdir -p $(BUILD_DIR)
	@# Check if a C file with the same name exists
	@$(eval C_FILE := $(wildcard $(HW_TESTS_DIR)/$*.c))
	@# Include the C file in the compilation command if it exists
	@if [ -z "$(C_FILE)" ]; then \
		$(CC) -T $(HW_TESTS_DIR)/infrastructure.lds -I $(BUILD_DIR) $(CCFLAGS) $(COMMON_SRC) -D OS_PT_FILE=\"$(OS_PT_FILE)\" $(HW_TESTS_DIR)/$*.S -o $(BUILD_DIR)/$*.elf; \
	else \
		$(CC) -T $(HW_TESTS_DIR)/infrastructure.lds -I $(BUILD_DIR) $(CCFLAGS) $(COMMON_SRC) -D OS_PT_FILE=\"$(OS_PT_FILE)\" $(HW_TESTS_DIR)/$*.S $(C_FILE) -o $(BUILD_DIR)/$*.elf; \
	fi

# Run the Tests
.PHONY: %.task
%.task: check_env_qemu $(BUILD_DIR)/%.elf $(NULL_BOOT_BINARY)
	-cd $(BUILD_DIR) && $(SANCTUM_QEMU) $(QEMU_FLAGS) -kernel $*.elf -bios $(NULL_BOOT_BINARY)

# Debug the Tests
.PHONY: %.debug
%.debug: check_env_qemu $(BUILD_DIR)/%.elf $(NULL_BOOT_BINARY)
	cd $(BUILD_DIR) && $(SANCTUM_QEMU) $(QEMU_FLAGS) -s -S -kernel $*.elf -bios $(NULL_BOOT_BINARY)

# Build All the Elf Files
.PHONY: elfs
elfs: $(HW_TESTS_ELFS)

# Run All the Tests
.PHONY: run_tests
run_tests: $(HW_TESTS_TASKS)
	@echo "All the test cases in $(HW_TESTS_DIR) have been run."
	@echo "The tests were: $(HW_TESTS_NAMES)"

LOG_FILE := $(HW_TESTS_DIR)/debug.log

.PHONY: %.tasksim
%.tasksim: check_env_riscy $(BUILD_DIR)/%.elf
	-$(RISCY_HOME)/procs/build/RV64G_OOO.core_2.core_SMALL.cache_LARGE.tso.l1_cache_lru.secure_flush.check_deadlock.llc_lru.fix/verilator/bin/ubuntu.exe --core-num 2 --rom $(RISCY_HOME)/procs/rom/out/rom_core_2 --elf $(BUILD_DIR)/$*.elf --mem-size 2048 > $(LOG_FILE)

.PHONY: run_tests_simulator
run_tests_simulator: $(HW_TESTS_TASKSIM)
	@echo "All the test cases in $(HW_TESTS_DIR) have been run."
	@echo "The tests were: $(HW_TESTS_NAMES)"

.PHONY: %.taskfpga
%.taskfpga: check_env $(BUILD_DIR)/%.elf
	sudo fpga-load-local-image -S 0 -I agfi-0b25880fb5ae74da1
	-$(RISCY_HOME)/procs/build/RV64G_OOO.core_2.core_SMALL.cache_LARGE.tso.l1_cache_lru.secure_flush.check_deadlock.llc_lru/awsf1/bin/ubuntu.exe --core-num 2 --rom $(RISCY_HOME)/procs/rom/out/rom_core_2 --elf $(BUILD_DIR)/$*.elf --mem-size 2048 --ignore-user-stucks 1000000

.PHONY: run_tests_fpga
run_tests_fpga: $(HW_TESTS_TASKFPGA)
	@echo "All the test cases in $(HW_TESTS_DIR) have been run."
	@echo "The tests were: $(HW_TESTS_NAMES)"

ELFS := $(shell find $(BUILD_DIR) -name '*.elf')
ELFS_PREF := $(addprefix $(BUILD_DIR)/, $(ELFS))
DISASS = $(ELFS:.elf=.disa.out)
DISASS_SOURCES = $(ELFS:.elf=.src.out)

%.disa.out : %.elf
	$(OBJDUMP) -D $^ > $@

%.src.out : %.elf
	$(OBJDUMP) -S $^ > $@

.PHONY: disassemble-all
disassemble-all:$(DISASS)

.PHONY: source-all
source-all:$(DISASS_SOURCES)
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(LOG_FILE)
