`ifndef AXI_LITE_SEQ_ITEM_SV
`define AXI_LITE_SEQ_ITEM_SV

typedef enum bit {
  AXI_WRITE = 1'b1,
  AXI_READ  = 1'b0
} axi_op_e;

class axi_lite_seq_item extends uvm_sequence_item;

  // Randomizable transaction fields
  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand axi_op_e   op_type;
  rand bit [3:0]  strb;        // Byte lane strobes

  // Response fields (driven by the slave/DUT)
  bit [1:0]       resp;

  // UVM Factory Registration Macro
  `uvm_object_utils_begin(axi_lite_seq_item)
    `uvm_field_int(addr,    UVM_DEFAULT)
    `uvm_field_int(data,    UVM_DEFAULT)
    `uvm_field_enum(axi_op_e, op_type, UVM_DEFAULT)
    `uvm_field_int(strb,    UVM_DEFAULT)
    `uvm_field_int(resp,    UVM_DEFAULT)
  `uvm_object_utils_end

  // Constructor
  function new(string name = "axi_lite_seq_item");
    super.new(name);
  endfunction

  // Standard Constraints
  constraint c_aligned_addr {
    addr[1:0] == 2'b00; // Force word-aligned addresses for 32-bit registers
  }

  constraint c_default_strb {
    strb == 4'b1111;    // Default to full 4-byte write enables
  }

endclass

`endif // AXI_LITE_SEQ_ITEM_SV
