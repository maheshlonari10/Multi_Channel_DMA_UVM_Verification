module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_pkg::*;

  // 1. Generate Clock and Reset Signals
  bit ACLK;
  bit ARESETn;

  // 100MHz Simulation Clock
  always #5 ACLK = ~ACLK; 

  // 2. Instantiate the Physical Interfaces
  axi_lite_if lite_if (.ACLK(ACLK), .ARESETn(ARESETn));
  axi_full_if full_if (.ACLK(ACLK), .ARESETn(ARESETn));

  // 3. Pass the Interfaces to the UVM Configuration Database
  initial begin
    uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.lite_agt*", "vif", lite_if);
    uvm_config_db#(virtual axi_full_if)::set(null, "uvm_test_top.env.full_agt*", "vif", full_if);
  end

  // 4. Clean Reset Generation Block
  initial begin
    ARESETn = 1'b0;
    #20;
    ARESETn = 1'b1;
  end

  // ==========================================================================
  // FULL HARDWARE WRAPPER RTL INSTANTIATION
  // ==========================================================================
  wire dma_irq_signal;

  dma_top u_dma_top (
    .ACLK                  (ACLK),
    .ARESETn               (ARESETn),
    
    // AXI-Lite Configuration Slave Port Mapping
    .S_AXI_LITE_AWADDR     (lite_if.awaddr),
    .S_AXI_LITE_AWVALID    (lite_if.awvalid),
    .S_AXI_LITE_AWREADY    (lite_if.awready),
    .S_AXI_LITE_WDATA      (lite_if.wdata),
    .S_AXI_LITE_WSTRB      (lite_if.wstrb),
    .S_AXI_LITE_WVALID     (lite_if.wvalid),
    .S_AXI_LITE_WREADY     (lite_if.wready),
    .S_AXI_LITE_BRESP      (lite_if.bresp),
    .S_AXI_LITE_BVALID     (lite_if.bvalid),
    .S_AXI_LITE_BREADY     (lite_if.bready),
    
    // ==========================================================================
    // AXI-FULL MASTER INTERFACE (Corrected Pin Mapping)
    // ==========================================================================
    .M_AXI_FULL_ARADDR     (full_if.araddr),     // Fixed from full_if.addr -> araddr
    .M_AXI_FULL_ARLEN      (full_if.arlen),      // Fixed from full_if.len -> arlen
    .M_AXI_FULL_ARSIZE     (full_if.arsize),     // Fixed from full_if.size -> arsize
    .M_AXI_FULL_ARVALID    (full_if.arvalid),
    .M_AXI_FULL_ARREADY    (full_if.arready),
    .M_AXI_FULL_RDATA      (full_if.rdata),
    .M_AXI_FULL_RLAST      (full_if.rlast),
    .M_AXI_FULL_RVALID     (full_if.rvalid),
    .M_AXI_FULL_RREADY     (full_if.rready),
    
    .M_AXI_FULL_AWADDR     (full_if.awaddr),     // Fixed from full_if.addr -> awaddr
    .M_AXI_FULL_AWLEN      (full_if.awlen),      // Fixed from full_if.len -> awlen
    .M_AXI_FULL_AWSIZE     (full_if.awsize),     // Fixed from full_if.size -> awsize
    .M_AXI_FULL_AWVALID    (full_if.awvalid),
    .M_AXI_FULL_AWREADY    (full_if.awready),
    .M_AXI_FULL_WDATA      (full_if.wdata),
    .M_AXI_FULL_WLAST      (full_if.wlast),
    .M_AXI_FULL_WVALID     (full_if.wvalid),
    .M_AXI_FULL_WREADY     (full_if.wready),
    .M_AXI_FULL_BRESP      (full_if.bresp),
    .M_AXI_FULL_BVALID     (full_if.bvalid),
    .M_AXI_FULL_BREADY     (full_if.bready),
    
    // Status Interrupt Wire
    .dma_irq               (dma_irq_signal)
  );

  // 5. Run UVM Test Sequence Engine
  initial begin
    run_test("dma_base_test"); 
  end

endmodule
