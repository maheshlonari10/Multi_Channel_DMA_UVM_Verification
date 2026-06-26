`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;
  `uvm_component_utils(axi_full_monitor)

  virtual axi_full_if vif;
  uvm_analysis_port #(axi_full_seq_item) item_collected_port;
  protected axi_full_seq_item trans;

  function new(string name = "axi_full_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual interface not found for axi_full_monitor")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    trans = axi_full_seq_item::type_id::create("trans");
    forever begin
      @(posedge vif.ACLK);
      if (vif.ARESETn) begin
        fork
          monitor_write_burst();
          monitor_read_burst();
        join_any
        disable fork;
      end
    end
  endtask

  virtual task monitor_write_burst();
    if (vif.awvalid && vif.awready) begin
      trans.id      = vif.awid;
      trans.addr    = vif.awaddr;
      trans.len     = vif.awlen;
      trans.size    = vif.awsize;
      trans.burst   = vif.awburst;
      trans.op_type = 1'b1;

      trans.data  = new[vif.awlen + 1];
      trans.wstrb = new[vif.awlen + 1];

      for (int i = 0; i <= trans.len; i++) begin
        while (!(vif.wvalid && vif.wready)) @(posedge vif.ACLK);
        trans.data[i]  = vif.wdata;
        trans.wstrb[i] = vif.wstrb;
        @(posedge vif.ACLK);
      end

      while (!(vif.bvalid && vif.bready)) @(posedge vif.ACLK);
      trans.resp = vif.bresp;

      `uvm_info("AXI_FULL_MON", $sformatf("\n==================================================\n[MONITORED WRITE BURST COMPLETE]\n==================================================\n%s", trans.sprint()), UVM_LOW)
      item_collected_port.write(trans);
    end
  endtask

  virtual task monitor_read_burst();
    if (vif.arvalid && vif.arready) begin
      trans.id      = vif.arid;
      trans.addr    = vif.araddr;
      trans.len     = vif.arlen;
      trans.size    = vif.arsize;
      trans.burst   = vif.arburst;
      trans.op_type = 1'b0;

      trans.data  = new[vif.arlen + 1];
      trans.wstrb = new[vif.arlen + 1];

      for (int i = 0; i <= trans.len; i++) begin
        while (!(vif.rvalid && vif.rready)) @(posedge vif.ACLK);
        trans.data[i] = vif.rdata;
        trans.resp    = vif.rresp;
        @(posedge vif.ACLK);
      end

      `uvm_info("AXI_FULL_MON", $sformatf("\n==================================================\n[MONITORED READ BURST COMPLETE]\n==================================================\n%s", trans.sprint()), UVM_LOW)
      item_collected_port.write(trans);
    end
  endtask

endclass

`endif // AXI_FULL_MONITOR_SV
