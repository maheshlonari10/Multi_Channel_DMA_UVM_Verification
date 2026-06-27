`ifndef DMA_SEQUENCES_SV
`define DMA_SEQUENCES_SV

// ============================================================================
// BASE LITE SEQUENCE
// ============================================================================
class axi_lite_base_seq extends uvm_sequence #(axi_lite_seq_item);
  `uvm_object_utils(axi_lite_base_seq)

  function new(string name = "axi_lite_base_seq");
    super.new(name);
  endfunction

  // Task to handle single register write operations
  task write_reg(bit [31:0] target_addr, bit [31:0] target_data);
    req = axi_lite_seq_item::type_id::create("req");
    start_item(req);
    
    if (!req.randomize() with { addr == target_addr; data == target_data; op_type == 1'b1; }) begin
      `uvm_fatal("SEQ_RAND_FAIL", "Failed to randomize AXI-Lite write item")
    end
    
    finish_item(req);
  endtask

endclass

`endif // DMA_SEQUENCES_SV

// ============================================================================
// DMA REGISTER CONFIGURATION STIMULUS SEQUENCE
// ============================================================================
class dma_channel_config_seq extends axi_lite_base_seq;
  `uvm_object_utils(dma_channel_config_seq)

  function new(string name = "dma_channel_config_seq");
    super.new(name);
  endfunction

  // The main body where the active sequence steps are executed
  virtual task body();
    `uvm_info("SEQ_BODY", "\n==================================================\n        STARTING DMA CHANNEL CONFIGURATION        \n==================================================", UVM_LOW)

    // Step 1: Program Source Address Register (Offset 0x04)
    write_reg(32'h0000_0004, 32'h1000_0000);

    // Step 2: Program Destination Address Register (Offset 0x08)
    write_reg(32'h0000_0008, 32'h2000_0000);

    // Step 3: Program Transfer Length Register (Offset 0x0C)
    write_reg(32'h0000_000C, 32'h0000_0010);

    // Step 4: Program Control Register to START the DMA engine (Offset 0x00, Control Bit = 1)
    write_reg(32'h0000_0000, 32'h0000_0001);

    `uvm_info("SEQ_BODY", "\n==================================================\n       DMA REGISTERS PROGRAMMED SUCCESSFULLY       \n==================================================", UVM_LOW)
  endtask

endclass
