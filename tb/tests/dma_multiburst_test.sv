`ifndef DMA_MULTIBURST_TEST_SV
`define DMA_MULTIBURST_TEST_SV

class dma_multiburst_test extends dma_base_test;
  `uvm_component_utils(dma_multiburst_test)

  function new(string name = "dma_multiburst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    dma_multiburst_seq m_seq;
    
    phase.raise_objection(this);
    `uvm_info("MULTIBURST_TEST", "\n==================================================\n         KICKSTARTING UVM MULTI-BURST TEST        \n==================================================", UVM_LOW)
    
    // Wait for reset to clear
    #25; 
    
    // Create and start the multi-burst sequence on the AXI-Lite sequencer
    m_seq = dma_multiburst_seq::type_id::create("m_seq");
    m_seq.start(env.lite_agt.sqr);
    
    // Give the DMA plenty of time to execute 4 full AXI bursts
    #2000; 
    
    `uvm_info("MULTIBURST_TEST", "\n==================================================\n          CLOSING UVM MULTI-BURST TEST            \n==================================================", UVM_LOW)
    phase.drop_objection(this);
  endtask

endclass

`endif // DMA_MULTIBURST_TEST_SV
