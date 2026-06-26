`ifndef AXI_LITE_MONITOR_SV
`define AXI_LITE_MONITOR_SV

class axi_lite_monitor extends uvm_monitor;
  `uvm_component_utils(axi_lite_monitor)

  // Virtual Interface to sample pins
  virtual axi_lite_if vif;

  // Analysis Port to broadcast transactions to Scoreboard/Coverage
  uvm_analysis_port #(axi_lite_seq_item) item_collected_port;

  // Handle for captured transactions
  protected axi_lite_seq_item trans;

  // Constructor
  function new(string name = "axi_lite_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  // Build Phase: Get virtual interface handle
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON_NO_VIF", "Virtual interface not found for axi_lite_monitor")
    end
  endfunction

  // Run Phase: Constantly monitor the bus lines
  virtual task run_phase(uvm_phase phase);
    trans = axi_lite_seq_item::type_id::create("trans");
    
    forever begin
      @(posedge vif.ACLK);
      if (vif.ARESETn) begin
        fork
          sample_write_tx();
          sample_read_tx();
        join_any
        disable fork; // Prevent thread accumulation on clock cycles
      end
    end
  end task

  // Sample Write Operations passively
  virtual task sample_write_tx();
    // Capture Address phase
    if (vif.awvalid && vif.awready) begin
      trans.addr    = vif.awaddr;
      trans.op_type = AXI_WRITE;
      
      // Capture corresponding Data phase
      while (!(vif.wvalid && vif.wready)) @(posedge vif.ACLK);
      trans.data = vif.wdata;
      trans.strb = vif.wstrb;
      
      // Capture Response phase
      while (!(vif.bvalid && vif.bready)) @(posedge vif.ACLK);
      trans.resp = vif.bresp;
      
      // Send cloned item up the UVM hierarchy
      item_collected_port.write(trans);
    end
  end task

  // Sample Read Operations passively
  virtual task sample_read_tx();
    if (vif.arvalid && vif.arready) begin
      trans.addr    = vif.araddr;
      trans.op_type = AXI_READ;
      
      // Capture Data/Response phase
      while (!(vif.rvalid && vif.rready)) @(posedge vif.ACLK);
      trans.data = vif.rdata;
      trans.resp = vif.rresp;
      
      // Broadcast monitored transaction
      item_collected_port.write(trans);
    end
  end task

endclass

`endif // AXI_LITE_MONITOR_SV
