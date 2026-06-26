`ifndef AXI_LITE_AGENT_SV
`define AXI_LITE_AGENT_SV

// Typedef the sequencer using the standard uvm_sequencer class template
typedef uvm_sequencer #(axi_lite_seq_item) axi_lite_sequencer;

class axi_lite_agent extends uvm_agent;
  `uvm_component_utils(axi_lite_agent)

  // Component Handles
  axi_lite_sequencer  sqr;
  axi_lite_driver     drv;
  axi_lite_monitor    mon;

  // Constructor
  function new(string name = "axi_lite_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Instantiate components based on active/passive settings
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Monitor is always instantiated (Passive & Active modes)
    mon = axi_lite_monitor::type_id::create("mon", this);

    // Driver and Sequencer only exist if the agent is ACTIVE
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = axi_lite_sequencer::type_id::create("sqr", this);
      drv = axi_lite_driver::type_id::create("drv", this);
    end
  end function

  // Connect Phase: Hook up the driver's port to the sequencer's export
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  end function

endclass

`endif // AXI_LITE_AGENT_SV
