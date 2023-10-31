remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
HW_TESTS_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR:=$(HW_TESTS_DIR)/build

HW_TESTS_NAMES :=  $(notdir $(basename $(wildcard $(HW_TESTS_DIR)/test_sanctum_low_va*)))
HW_TESTS_ELFS := $(addprefix $(BUILD_DIR)/, $(addsuffix .elf, $(HW_TESTS_NAMES)))
HW_TESTS_TASKS := $(addsuffix .task, $(HW_TESTS_NAMES))
HW_TESTS_DEBUG := $(addsuffix .debug, $(HW_TESTS_NAMES))
HW_TESTS_TASKSIM := $(addsuffix .tasksim, $(HW_TESTS_NAMES))
HW_TESTS_IDPT := $(BUILD_DIR)/idpt.bin $(BUILD_DIR)/enclave_pt.bin

CC:=riscv64-unknown-elf-gcc
#CC:=riscv64-unknown-linux-gnu-gcc
OBJCOPY:=riscv64-unknown-linux-gnu-objcopy
OBJDUMP:=riscv64-unknown-elf-objdump

CCFLAGS := -march=rv64g_zifencei -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -ggdb3 -O0 -Wall
QEMU_FLAGS := -smp cpus=2 -machine sanctum -m 2G -nographic

.PHONY: check_env
check_env:
ifndef SANCTUM_QEMU
	$(error SANCTUM_QEMU is undefined)
endif
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
$(HW_TESTS_IDPT): $(HW_TESTS_DIR)/make_idpt.py $(HW_TESTS_DIR)/make_enclave_pt.py $(BUILD_DIR)
	@echo "Building an identity page tables for hw_tests"
	cd $(BUILD_DIR) && python $(HW_TESTS_DIR)/make_idpt.py && python $(HW_TESTS_DIR)/make_enclave_pt.py

# Elf Files
$(BUILD_DIR)/%.elf: $(HW_TESTS_IDPT)
	mkdir -p $(BUILD_DIR)
	$(CC) -T $(HW_TESTS_DIR)/infrastructure.lds -I $(BUILD_DIR) $(CCFLAGS) $(HW_TESTS_DIR)/infrastructure.c $(HW_TESTS_DIR)/$*.S -o $(BUILD_DIR)/$*.elf

# Run the Tests
.PHONY: %.task
%.task: check_env $(BUILD_DIR)/%.elf $(NULL_BOOT_BINARY)
	-cd $(BUILD_DIR) && $(SANCTUM_QEMU) $(QEMU_FLAGS) -kernel $*.elf -bios $(NULL_BOOT_BINARY)

# Debug the Tests
.PHONY: %.debug
%.debug: check_env $(BUILD_DIR)/%.elf $(NULL_BOOT_BINARY)
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
%.tasksim: check_env $(BUILD_DIR)/%.elf
	-$(RISCY_HOME)/procs/build/RV64G_OOO.core_1.core_SMALL.cache_LARGE.tso.l1_cache_lru.secure_flush.check_deadlock/verilator/bin/ubuntu.exe --core-num 1 --rom $(RISCY_HOME)/procs/rom/out/rom_core_1 --elf $(BUILD_DIR)/$*.elf --mem-size 2048 > $(LOG_FILE)

.PHONY: run_tests_simulator
run_tests_simulator: $(HW_TESTS_TASKSIM)
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
