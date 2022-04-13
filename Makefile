remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
HW_TESTS_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR:=$(HW_TESTS_DIR)/build

HW_TESTS_NAMES :=  $(notdir $(basename $(wildcard $(HW_TESTS_DIR)/test_*)))
HW_TESTS_ELFS := $(addprefix $(BUILD_DIR)/, $(addsuffix .elf, $(HW_TESTS_NAMES)))
HW_TESTS_TASKS := $(addsuffix .task, $(HW_TESTS_NAMES))
HW_TESTS_IDPT := $(BUILD_DIR)/idpt.bin

#CC:=riscv64-unknown-elf-gcc
CC:=riscv64-unknown-linux-gnu-gcc

CCFLAGS := -march=rv64g_zifencei -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -g -O0 -Wall
QEMU_FLAGS := -machine sanctum -m 2G -nographic

.PHONY: check_env
check_env:
ifndef SANCTUM_QEMU
	$(error SANCTUM_QEMU is undefined)
endif

# Identity Page Table 
$(HW_TESTS_IDPT): $(HW_TESTS_DIR)/make_idpt.py
	@echo "Building an identity page tables for hw_tests"
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && python $(HW_TESTS_DIR)/make_idpt.py

# Elf Files
$(BUILD_DIR)/%.elf: $(HW_TESTS_IDPT)
	mkdir -p $(BUILD_DIR)
	$(CC) -T $(HW_TESTS_DIR)/infrastructure.lds -I $(BUILD_DIR) $(CCFLAGS) $(HW_TESTS_DIR)/infrastructure.c $(HW_TESTS_DIR)/$*.S -o $(BUILD_DIR)/$*.elf

# Run the Tests
.PHONY: %.task
%.task: check_env $(BUILD_DIR)/%.elf
	- cd $(BUILD_DIR) && $(SANCTUM_QEMU) $(QEMU_FLAGS) -kernel $*.elf

# Build All the Elf Files
.PHONY: elfs
elfs: $(HW_TESTS_ELFS)

# Run All the Tests
.PHONY: run_tests
run_tests: $(HW_TESTS_TASKS)
	@echo "All the test cases in $(HW_TESTS_DIR) have been run."
	@echo "The tests were: $(HW_TESTS_NAMES)"

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
