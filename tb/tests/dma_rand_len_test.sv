`ifndef DMA_RAND_LEN_TEST_SV
`define DMA_RAND_LEN_TEST_SV

class dma_rand_len_test extends dma_base_test;
  `uvm_component_utils(dma_rand_len_test)

  function new(string name = "dma_rand_len_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma_rand_len_seq r_seq;
    
    phase.raise_objection(this);
    `uvm_info("RAND_LEN_TEST", "\n==================================================\n         KICKSTARTING UVM RANDOM LENGTH TEST      \n==================================================", UVM_LOW)
    
    // Wait for reset to clear
    #25; 
    
    // Create the sequence
    r_seq = dma_rand_len_seq::type_id::create("r_seq");
    
    // CRITICAL: Call randomize() to roll the dice on the transfer length!
    if (!r_seq.randomize()) begin
      `uvm_fatal("RAND_FAIL", "Failed to randomize dma_rand_len_seq!")
    end
    
    // Start the sequence on the AXI-Lite sequencer
    r_seq.start(env.lite_agt.sqr);
    
    // Give the DMA plenty of time to execute up to 256 words (16 max-length bursts)
    #10000; 
    
    `uvm_info("RAND_LEN_TEST", "\n==================================================\n          CLOSING UVM RANDOM LENGTH TEST          \n==================================================", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // DMA_RAND_LEN_TEST_SV
