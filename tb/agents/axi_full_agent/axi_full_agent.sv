`ifndef AXI_FULL_AGENT_SV
`define AXI_FULL_AGENT_SV

typedef uvm_sequencer #(axi_full_seq_item) axi_full_sequencer;

class axi_full_agent extends uvm_agent;
  `uvm_component_utils(axi_full_agent)

  axi_full_sequencer  sqr;
  axi_full_driver     drv;
  axi_full_monitor    mon;

  function new(string name = "axi_full_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mon = axi_full_monitor::type_id::create("mon", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sqr = axi_full_sequencer::type_id::create("sqr", this);
      drv = axi_full_driver::type_id::create("drv", this);
    end
  end function

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  end function

endclass

`endif // AXI_FULL_AGENT_SV
