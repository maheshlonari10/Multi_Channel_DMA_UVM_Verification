`ifndef DMA_ENV_SV
`define DMA_ENV_SV

class dma_env extends uvm_env;
  `uvm_component_utils(dma_env)

  // Instantiate our custom AXI agents
  axi_lite_agent  lite_agt;
  axi_full_agent  full_agt;

  // Constructor
  function new(string name = "dma_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Create the agents
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    lite_agt = axi_lite_agent::type_id::create("lite_agt", this);
    full_agt = axi_full_agent::type_id::create("full_agt", this);
  end function

  // Connect Phase: This is where we will link the agent monitors to the scoreboard later
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  end function

endclass

`endif // DMA_ENV_SV
