`ifndef AXI_LITE_AGENT_SV
`define AXI_LITE_AGENT_SV

typedef uvm_sequencer #(axi_lite_seq_item) axi_lite_sequencer;

class axi_lite_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_agent)

  axi_lite_sequencer  sqr;
  axi_lite_driver     drv;
  axi_lite_monitor    mon;

  function new(string name = "axi_lite_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mon = axi_lite_monitor::type_id::create("mon", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sqr = axi_lite_sequencer::type_id::create("sqr", this);
      drv = axi_lite_driver::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction

endclass

`endif // AXI_LITE_AGENT_SV
