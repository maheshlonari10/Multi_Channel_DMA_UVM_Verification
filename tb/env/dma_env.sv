`ifndef DMA_ENV_SV
`define DMA_ENV_SV

class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)

  // Component Handles
  axi_lite_agent  lite_agt;
  axi_full_agent  full_agt;
  dma_scoreboard  sb;

  // Constructor
  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Create agents and the scoreboard
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    lite_agt = axi_lite_agent::type_id::create("lite_agt", this);
    full_agt = axi_full_agent::type_id::create("full_agt", this);
    sb       = dma_scoreboard::type_id::create("sb", this);
  endfunction

  // Connect Phase: Wire up Monitor Ports to the Scoreboard Imports
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect AXI-Lite Monitor to Scoreboard
    lite_agt.mon.item_collected_port.connect(sb.lite_export);
    
    // Connect AXI-Full Monitor to Scoreboard
    full_agt.mon.item_collected_port.connect(sb.full_export);
  endfunction

endclass

`endif // DMA_ENV_SV
