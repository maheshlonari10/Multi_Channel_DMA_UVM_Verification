`ifndef DMA_BASE_TEST_SV
`define DMA_BASE_TEST_SV

class dma_base_test extends uvm_test;
  `uvm_component_utils(dma_base_test)

  // Handle for the top-level environment
  dma_env env;

  // Handle for our active configuration sequence
  dma_channel_config_seq config_seq;

  // Constructor
  function new(string name = "dma_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Instantiate the environment container
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dma_env::type_id::create("env", this);
  endfunction

  // Run Phase: Control the simulation timeout and execute sequences
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("BASE_TEST", "\n==================================================\n        KICKSTARTING UVM BASE TEST RUN PHASE       \n==================================================", UVM_LOW)
    
    // 1. Create the configuration stimulus sequence
    config_seq = dma_channel_config_seq::type_id::create("config_seq");
    
    // 2. Start the sequence on the AXI-Lite Agent's Sequencer inside the environment
    config_seq.start(env.lite_agt.sqr);
    
    // Small stabilization delay
    #50;
    
    `uvm_info("BASE_TEST", "\n==================================================\n         CLOSING UVM BASE TEST RUN PHASE          \n==================================================", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass

`endif // DMA_BASE_TEST_SV
