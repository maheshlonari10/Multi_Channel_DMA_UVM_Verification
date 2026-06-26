`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;
  `uvm_component_utils(axi_full_monitor)

  // Virtual Interface connection
  virtual axi_full_if vif;

  // Analysis Port to broadcast verified bursts to Scoreboard/Coverage
  uvm_analysis_port #(axi_full_seq_item) item_collected_port;

  // Internal transaction handle
  protected axi_full_seq_item trans;

  // Constructor
  function new(string name = "axi_full_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  // Build Phase: Fetch virtual interface handle
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found for axi_full_monitor")
    end
  endfunction

  // Run Phase: Passive structural observation loop
  virtual task run_phase(uvm_phase phase);
    trans = axi_full_seq_item::type_id::create("trans");
    
    forever begin
      @(posedge vif.ACLK);
      if (vif.ARESETn) begin
        fork
          monitor_write_burst();
          monitor_read_burst();
        join_any
        disable fork; // Clear parallel routing blocks per cycle
      end
    end
  end task

  // Capture Write Burst Transactions Passively
  virtual task monitor_write_burst();
    if (vif.awvalid && vif.awready) begin
      trans.id      = vif.awid;
      trans.addr    = vif.awaddr;
      trans.len     = vif.awlen;
      trans.size    = vif.awsize;
      trans.burst   = vif.awburst;
      trans.op_type = 1'b1; // Write Operation

      trans.data  = new[vif.awlen + 1];
      trans.wstrb = new[vif.awlen + 1];

      // Loop through all data beats until WLAST is observed
      for (int i = 0; i <= trans.len; i++) begin
        while (!(vif.wvalid && vif.wready)) @(posedge vif.ACLK);
        trans.data[i]  = vif.wdata;
        trans.wstrb[i] = vif.wstrb;
        if (vif.wlast && (i != trans.len)) begin
          `uvm_warning(get_type_name(), "Early WLAST detected on bus monitoring line")
        end
        @(posedge vif.ACLK);
      end

      // Catch the associated Response Phase
      while (!(vif.bvalid && vif.bready)) @(posedge vif.ACLK);
      trans.resp = vif.bresp;

      // Clean Structured Visual Printout
      `uvm_info("AXI_FULL_MON", $sformatf("\n==================================================\n[MONITORED WRITE BURST COMPLETE]\n==================================================\n%s", trans.sprint()), UVM_LOW)
      
      // Broadcast cloned transaction packet up to Scoreboard
      item_collected_port.write(trans);
    end
  end task

  // Capture Read Burst Transactions Passively
  virtual task monitor_read_burst();
    if (vif.arvalid && vif.arready) begin
      trans.id      = vif.arid;
      trans.addr    = vif.araddr;
      trans.len     = vif.arlen;
      trans.size    = vif.arsize;
      trans.burst   = vif.arburst;
      trans.op_type = 1'b0; // Read Operation

      trans.data  = new[vif.arlen + 1];
      trans.wstrb = new[vif.arlen + 1]; // Irrelevant for reads, but matches payload size arrays

      for (int i = 0; i <= trans.len; i++) begin
        while (!(vif.rvalid && vif.rready)) @(posedge vif.ACLK);
        trans.data[i] = vif.rdata;
        trans.resp    = vif.rresp;
        @(posedge vif.ACLK);
      end

      // Clean Structured Visual Printout
      `uvm_info("AXI_FULL_MON", $sformatf("\n==================================================\n[MONITORED READ BURST COMPLETE]\n==================================================\n%s", trans.sprint()), UVM_LOW)
      
      item_collected_port.write(trans);
    end
  end task

endclass

`endif // AXI_FULL_MONITOR_SV
