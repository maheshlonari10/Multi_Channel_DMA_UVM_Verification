`ifndef AXI_FULL_MONITOR_SV
`define AXI_FULL_MONITOR_SV

class axi_full_monitor extends uvm_monitor;
  `uvm_component_utils(axi_full_monitor)

  virtual axi_full_if vif;
  uvm_analysis_port #(axi_full_seq_item) item_collected_port;
  protected axi_full_seq_item trans;

  // Internal dynamic queues to hold burst data as it arrives over multiple clocks
  protected bit [31:0] write_data_queue[$];

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
    trans = axi_full_seq_item::type_id::create("trans");
    
    forever begin
      @(posedge vif.ACLK);
      
      if (vif.ARESETn) begin
        // ==========================================================================
        // 1. MONITOR AXI-FULL WRITE BURSTS
        // ==========================================================================
        if (vif.awvalid && vif.awready) begin
          trans.addr    = vif.awaddr;
          trans.id      = vif.awid;
          trans.len     = vif.awlen;
          trans.size    = vif.awsize;
          trans.burst   = vif.awburst;
          trans.op_type = 1'b1; // WRITE
        end

        if (vif.wvalid && vif.wready) begin
          write_data_queue.push_back(vif.wdata);
          
          if (vif.wlast) begin
            trans.data = new[write_data_queue.size()];
            foreach (write_data_queue[i]) begin
              trans.data[i] = write_data_queue[i];
            end
            write_data_queue.delete(); // Clear queue for next burst
          end
        end

        if (vif.bvalid && vif.bready) begin
          trans.resp = vif.bresp;
          `uvm_info("MON_FULL_CAPTURED", $sformatf("Captured AXI-Full WRITE Burst! Addr=0x%0h, Beats=%0d", trans.addr, trans.len + 1), UVM_LOW)
          
          item_collected_port.write(trans);
          trans = axi_full_seq_item::type_id::create("trans"); // Fresh item
        end

        // ==========================================================================
        // 2. MONITOR AXI-FULL READ BURSTS
        // ==========================================================================
        if (vif.arvalid && vif.arready) begin
          trans.addr    = vif.araddr;
          trans.id      = vif.arid;
          trans.len     = vif.arlen;
          trans.size    = vif.arsize;
          trans.burst   = vif.arburst;
          trans.op_type = 1'b0; // READ
          write_data_queue.delete(); // Reuse queue safely
        end

        if (vif.rvalid && vif.rready) begin
          write_data_queue.push_back(vif.rdata);
          
          if (vif.rlast) begin
            trans.data = new[write_data_queue.size()];
            foreach (write_data_queue[i]) begin
              trans.data[i] = write_data_queue[i];
            end
            trans.resp = vif.rresp;
            
            `uvm_info("MON_FULL_CAPTURED", $sformatf("Captured AXI-Full READ Burst! Addr=0x%0h, Beats=%0d", trans.addr, trans.len + 1), UVM_LOW)
            
            item_collected_port.write(trans);
            write_data_queue.delete();
            trans = axi_full_seq_item::type_id::create("trans");
          end
        end
        
      end else begin
        write_data_queue.delete();
      end
    end
  endtask

endclass

`endif // AXI_FULL_MONITOR_SV
