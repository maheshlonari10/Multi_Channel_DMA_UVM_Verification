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

# Default target when typing just 'make'
help:
	@echo "======================================================================"
	@echo "             DMA Controller UVM Verification Environment              "
	@echo "======================================================================"
	@echo "Available Targets:"
	@echo "----------------------------------------------------------------------"
	@echo "  make help             - Displays this menu"
	@echo "  make comp             - Compiles the RTL and UVM testbench"
	@echo "  make opt              - Optimizes the compiled design (vopt)"
	@echo "  make run_base         - Runs the 16-beat Single Burst Sanity Test"
	@echo "  make run_multiburst   - Runs the 64-word Multi-Burst Stress Test"
	@echo "  make run_rand         - Runs the Constrained Random Length Test"
	@echo "  make clean            - Removes all simulation generated files"
	@echo "======================================================================"

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

run_rand: opt
	vsim -c -do "run -all; exit" +UVM_TESTNAME=dma_rand_len_test -sv_seed random tb_top
