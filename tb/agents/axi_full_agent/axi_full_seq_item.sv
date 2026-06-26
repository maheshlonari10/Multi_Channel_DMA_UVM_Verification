`ifndef AXI_FULL_SEQ_ITEM_SV
`define AXI_FULL_SEQ_ITEM_SV

class axi_full_seq_item extends uvm_sequence_item;

  // Transaction Attributes
  rand bit [3:0]          id;
  rand bit [31:0]         addr;
  rand bit [7:0]          len;       // Number of beats = len + 1
  rand bit [2:0]          size;      // 3'b010 = 4 bytes per beat (32-bit)
  rand bit [1:0]          burst;     // 2'b01 = INCR
  rand bit                op_type;   // 1 = Write, 0 = Read
  
  // Dynamic Array for Burst Payload
  rand bit [31:0]         data[];
  rand bit [3:0]          wstrb[];   // Byte strobes per beat

  // Response Field
  bit [1:0]               resp;

  // UVM Factory Automation Macros
  `uvm_object_utils_begin(axi_full_seq_item)
    `uvm_field_int(id,              UVM_DEFAULT)
    `uvm_field_int(addr,            UVM_DEFAULT)
    `uvm_field_int(len,             UVM_DEFAULT)
    `uvm_field_int(size,            UVM_DEFAULT)
    `uvm_field_int(burst,           UVM_DEFAULT)
    `uvm_field_int(op_type,         UVM_DEFAULT)
    `uvm_field_array_int(data,      UVM_DEFAULT)
    `uvm_field_array_int(wstrb,     UVM_DEFAULT)
    `uvm_field_int(resp,            UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "axi_full_seq_item");
    super.new(name);
  endfunction

  // Constraints to match structural AXI hardware rules
  constraint c_data_size {
    data.size() == (len + 1);
    wstrb.size() == data.size();
  }

  constraint c_axi_size {
    size == 3'b010; // Fixed to 4 bytes per transfer beat (matches 32-bit architecture)
  }

  constraint c_burst_type {
    burst == 2'b01; // Standard Incremental (INCR) bursts for block data moves
  }

  constraint c_aligned_addr {
    addr[1:0] == 2'b00; // Aligned to 32-bit boundaries
  }

endclass

`endif // AXI_FULL_SEQ_ITEM_SV
