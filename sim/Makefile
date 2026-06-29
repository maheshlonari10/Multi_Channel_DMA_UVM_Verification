# ==========================================
# UVM Verification Environment Makefile
# ==========================================

# Variables
TB_TOP = tb_top
TEST_NAME ?= dma_base_test
VERBOSITY = UVM_LOW

# Directory Paths (Relative to the 'sim' folder)
RTL_DIR = ../rtl
TB_DIR  = ../tb

# Source Files
RTL_SRC = $(RTL_DIR)/dma_regs.v \
          $(RTL_DIR)/dma_fifo.v \
          $(RTL_DIR)/dma_master_axi_full.v \
          $(RTL_DIR)/dma_top.v

TB_SRC  = $(TB_DIR)/agents/axi_lite_agent/axi_lite_if.sv \
          $(TB_DIR)/agents/axi_full_agent/axi_full_if.sv \
          $(TB_DIR)/dma_pkg.sv \
          $(TB_DIR)/tb_top.sv

# ==========================================
# Base Targets
# ==========================================
clean:
	rm -rf work transcript vsim.wlf *.log top_opt

comp: clean
	vlib work
	vlog -sv $(RTL_SRC) $(TB_SRC) +incdir+$(TB_DIR)

opt: comp
	vopt +acc $(TB_TOP) -o top_opt

# ==========================================
# Test Execution Targets
# ==========================================
# Generic run command (uses the TEST_NAME variable)
run:
	vsim -c top_opt +UVM_TESTNAME=$(TEST_NAME) +UVM_VERBOSITY=$(VERBOSITY) -do "run -all; quit"

# Specific Test Targets
run_base: opt
	$(MAKE) run TEST_NAME=dma_base_test

run_multiburst: opt
	$(MAKE) run TEST_NAME=dma_multiburst_test
