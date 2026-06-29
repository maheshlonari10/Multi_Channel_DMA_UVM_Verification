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


class dma_multiburst_seq extends uvm_sequence #(axi_lite_seq_item);
  `uvm_object_utils(dma_multiburst_seq)

  function new(string name = "dma_multiburst_seq");
    super.new(name);
  endfunction

  virtual task body();
    axi_lite_seq_item req;
    
    `uvm_info("SEQ_BODY", "\n==================================================\n          STARTING MULTI-BURST (64-WORD) CONFIG          \n==================================================", UVM_LOW)

    // 1. Program Source Address
    req = axi_lite_seq_item::type_id::create("req");
    start_item(req);
    req.op_type = 1; // Write
    req.addr    = 32'h4;
    req.data    = 32'h10000000;
    finish_item(req);

    // 2. Program Destination Address
    req = axi_lite_seq_item::type_id::create("req");
    start_item(req);
    req.op_type = 1;
    req.addr    = 32'h8;
    req.data    = 32'h20000000;
    finish_item(req);

    // 3. Program Transfer Length to 64 words (0x40)
    req = axi_lite_seq_item::type_id::create("req");
    start_item(req);
    req.op_type = 1;
    req.addr    = 32'hc;
    req.data    = 32'h00000040; // 64 words!
    finish_item(req);

    // 4. Start the DMA
    req = axi_lite_seq_item::type_id::create("req");
    start_item(req);
    req.op_type = 1;
    req.addr    = 32'h0;
    req.data    = 32'h1;
    finish_item(req);

    `uvm_info("SEQ_BODY", "\n==================================================\n        MULTI-BURST REGISTERS PROGRAMMED SUCESSFULLY      \n==================================================", UVM_LOW)
  endtask
endclass
