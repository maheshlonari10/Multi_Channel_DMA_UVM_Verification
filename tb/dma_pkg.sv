`ifndef DMA_PKG_SV
`define DMA_PKG_SV

package dma_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Include AXI-Lite Agent Files
  `include "agents/axi_lite_agent/axi_lite_seq_item.sv"
  `include "agents/axi_lite_agent/axi_lite_driver.sv"
  `include "agents/axi_lite_agent/axi_lite_monitor.sv"
  `include "agents/axi_lite_agent/axi_lite_agent.sv"

  // Include AXI-Full Agent Files
  `include "agents/axi_full_agent/axi_full_seq_item.sv"
  `include "agents/axi_full_agent/axi_full_driver.sv"
  `include "agents/axi_full_agent/axi_full_monitor.sv"
  `include "agents/axi_full_agent/axi_full_agent.sv"

  // Include Environment File
  `include "env/dma_env.sv"

endpackage

`endif // DMA_PKG_SV
