#============================================================================
# GBA on AUP-ZU3 (xczu3eg-sfvc784-2-e) - Vivado build (EECS 151 lab-style flow)
# Prereq: Vivado on PATH (e.g. source /home/ff/eecs151/eecs151_fpga.sh). Set 100 MHz clock in zu3.xdc.
# Run from aup_zu3: make setup project synth impl program
# Or from repo root: make -C aup_zu3 project
#============================================================================
SHELL       := $(shell which bash) -o pipefail
# Absolute path to this directory (aup_zu3). When run as "make -C aup_zu3", pwd is aup_zu3.
ABS_TOP     := $(shell pwd)
SCRIPTS     := $(ABS_TOP)/scripts
VIVADO      ?= vivado
VIVADO_OPTS ?= -nolog -nojournal -mode batch
FPGA_PART   ?= xczu3eg-sfvc784-2-e
TOP         ?= zu3_top

# Repo root (parent of aup_zu3) for create_project.tcl. Use absolute path so "cd $(REPO_ROOT) && vivado -source ..." finds the script.
REPO_ROOT   := $(ABS_TOP)/..
CREATE_PROJECT_SCRIPT := $(ABS_TOP)/scripts/create_project.tcl
BUILD_DIR   := $(ABS_TOP)/build

.PHONY: setup project synth impl program clean build_id

# Generate build/target.tcl so scripts can source ../target.tcl (lab style)
setup:
	mkdir -p $(BUILD_DIR)
	@echo "set ABS_TOP $(ABS_TOP)" > $(BUILD_DIR)/target.tcl
	@echo "set TOP $(TOP)" >> $(BUILD_DIR)/target.tcl
	@echo "set FPGA_PART $(FPGA_PART)" >> $(BUILD_DIR)/target.tcl

# Create Vivado project (run from repo root so script path is correct)
project: setup
	cd $(REPO_ROOT) && $(VIVADO) $(VIVADO_OPTS) -source $(CREATE_PROJECT_SCRIPT)

synth: project
	cd $(BUILD_DIR) && $(VIVADO) $(VIVADO_OPTS) -source $(SCRIPTS)/run_synth.tcl |& tee synth.log

impl: synth
	cd $(BUILD_DIR) && $(VIVADO) $(VIVADO_OPTS) -source $(SCRIPTS)/run_impl.tcl |& tee impl.log
	@mkdir -p $(BUILD_DIR)/impl && cp $(BUILD_DIR)/gba_zu3.runs/impl_1/$(TOP).bit $(BUILD_DIR)/impl/

# Program FPGA (board connected via USB-C JTAG). Uses build/target.tcl for ABS_TOP/TOP (lab style).
# At Cory 140: use assign-fpga-board, hw_server, then Vivado GUI → Program device → build/impl/zu3_top.bit
program: impl
	cd $(BUILD_DIR)/impl && $(VIVADO) $(VIVADO_OPTS) -source $(SCRIPTS)/program_fpga.tcl

clean:
	rm -rf $(BUILD_DIR)
	@echo "Cleaned $(BUILD_DIR)"

# Optional: regenerate build_id.v with current date
build_id:
	@echo '`define BUILD_DATE "'$$(date +%y%m%d)'"' > $(ABS_TOP)/build_id.v
