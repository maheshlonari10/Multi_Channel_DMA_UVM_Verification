module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import dma_pkg::*;

  // 1. Generate Clock and Reset Signals
  bit ACLK;
  bit ARESETn;

  // 100MHz Clock simulation
  always #5 ACLK = ~ACLK; 

  // 2. Instantiate the Physical Interfaces
  axi_lite_if lite_if (.ACLK(ACLK), .ARESETn(ARESETn));
  axi_full_if full_if (.ACLK(ACLK), .ARESETn(ARESETn));

  // 3. Pass the Interfaces to the UVM Configuration Database
  initial begin
    uvm_config_db#(virtual axi_lite_if)::set(null, "uvm_test_top.env.lite_agt*", "vif", lite_if);
    uvm_config_db#(virtual axi_full_if)::set(null, "uvm_test_top.env.full_agt*", "vif", full_if);
  end

  // 4. Kickstart the Testbench Execution
  initial begin
    ARESETn = 1'b0;
    #20;
    ARESETn = 1'b1;
    
    run_test("dma_base_test"); 
  end

endmodule
