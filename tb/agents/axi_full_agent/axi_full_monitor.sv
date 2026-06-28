`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;
  `uvm_component_utils(axi_full_monitor)

  virtual axi_full_if vif;
  uvm_analysis_port #(axi_full_seq_item) item_collected_port;

  function new(string name = "axi_full_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON_NO_VIF", "Virtual interface not found for axi_full_monitor")
    end
  endfunction

  virtual task run_phase(uvm_phase phase);
    @(posedge vif.ARESETn);
    
    fork
      monitor_write_channel();
      monitor_read_channel();
    join
  endtask

  // ==========================================================================
  // 1. ISOLATED WRITE MONITORING THREAD
  // ==========================================================================
  task monitor_write_channel();
    axi_full_seq_item w_trans;
    bit [31:0] w_queue[$];
    
    w_trans = axi_full_seq_item::type_id::create("w_trans");
    
    forever begin
      @(posedge vif.ACLK);
      if (vif.ARESETn) begin
        if (vif.awvalid && vif.awready) begin
          w_trans.addr    = vif.awaddr;
          w_trans.id      = vif.awid;
          w_trans.len     = vif.awlen;
          w_trans.size    = vif.awsize;
          w_trans.burst   = vif.awburst;
          w_trans.op_type = 1'b1; // Dedicated Write
        end

        if (vif.wvalid && vif.wready) begin
          w_queue.push_back(vif.wdata);
          
          if (vif.wlast) begin
            w_trans.data = new[w_queue.size()];
            foreach (w_queue[i]) w_trans.data[i] = w_queue[i];
            w_queue.delete();
          end
        end

        if (vif.bvalid && vif.bready) begin
          w_trans.resp = vif.bresp;
          `uvm_info("MON_WRITE_CAPTURED", $sformatf("Captured AXI-Full WRITE! Addr=0x%0h, Beats=%0d", w_trans.addr, w_trans.len + 1), UVM_LOW)
          item_collected_port.write(w_trans);
          w_trans = axi_full_seq_item::type_id::create("w_trans");
        end
      end else begin
        w_queue.delete();
      end
    end
  endtask

  // ==========================================================================
  // 2. ISOLATED READ MONITORING THREAD
  // ==========================================================================
  task monitor_read_channel();
    axi_full_seq_item r_trans;
    bit [31:0] r_queue[$];
    
    r_trans = axi_full_seq_item::type_id::create("r_trans");
    
    forever begin
      @(posedge vif.ACLK);
      if (vif.ARESETn) begin
        if (vif.arvalid && vif.arready) begin
          r_trans.addr    = vif.araddr;
          r_trans.id      = vif.arid;
          r_trans.len     = vif.arlen;
          r_trans.size    = vif.arsize;
          r_trans.burst   = vif.arburst;
          r_trans.op_type = 1'b0; // Dedicated Read
        end

        if (vif.rvalid && vif.rready) begin
          r_queue.push_back(vif.rdata);
          
          if (vif.rlast) begin
            r_trans.data = new[r_queue.size()];
            foreach (r_queue[i]) r_trans.data[i] = r_queue[i];
            r_trans.resp = vif.rresp;
            
            `uvm_info("MON_READ_CAPTURED", $sformatf("Captured AXI-Full READ! Addr=0x%0h, Beats=%0d", r_trans.addr, r_trans.len + 1), UVM_LOW)
            item_collected_port.write(r_trans);
            r_queue.delete();
            r_trans = axi_full_seq_item::type_id::create("r_trans");
          end
        end
      end else begin
        r_queue.delete();
      end
    end
  endtask

endclass

`endif // AXI_FULL_MONITOR_SV
