`ifndef AXI_FULL_DRIVER_SV
`define AXI_FULL_DRIVER_SV

class axi_full_driver extends uvm_driver #(axi_full_seq_item);
  `uvm_component_utils(axi_full_driver)

  // Virtual Interface to drive AXI-Full physical pins
  virtual axi_full_if vif;

  // Constructor
  function new(string name = "axi_full_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Retrieve the interface
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_full_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV_NO_VIF", "Virtual interface not found for axi_full_driver")
    end
  endfunction

  // Run Phase: Reset pin state and continuously fetch transactions
  virtual task run_phase(uvm_phase phase);
    // Initialize Write Channels
    vif.awid    <= 0;  vif.awaddr  <= 0;  vif.awlen   <= 0;
    vif.awsize  <= 0;  vif.awburst <= 0;  vif.awvalid <= 0;
    vif.wdata   <= 0;  vif.wstrb   <= 0;  vif.wlast   <= 0;  vif.wvalid  <= 0;
    vif.bready  <= 0;

    // Initialize Read Channels
    vif.arid    <= 0;  vif.araddr  <= 0;  vif.arlen   <= 0;
    vif.arsize  <= 0;  vif.arburst <= 0;  vif.arvalid <= 1'b0;
    vif.rready  <= 0;

    forever begin
      seq_item_port.get_next_item(req);
      
      `uvm_info("AXI_FULL_DRV", $sformatf("\n==================================================\n[DRIVING TRANSACTION] ID: %0d | Op: %s\n==================================================", req.id, (req.op_type ? "WRITE" : "READ")), UVM_LOW)
      
      drive_burst_transfer(req);
      
      `uvm_info("AXI_FULL_DRV", $sformatf("\n[TRANSACTION COMPLETE]\n%s", req.sprint()), UVM_HIGH)
      
      seq_item_port.item_done();
    end
  endtask

  // Main task to route transactions based on operation type
  virtual task drive_burst_transfer(axi_full_seq_item item);
    @(posedge vif.ACLK);
    if (item.op_type == 1'b1) begin
      drive_write_burst(item);
    end else begin
      drive_read_burst(item);
    end
  endtask

  // AXI4-Full Write Burst Handshake Logic
  virtual task drive_write_burst(axi_full_seq_item item);
    // Write Address Phase
    vif.awid    <= item.id;
    vif.awaddr  <= item.addr;
    vif.awlen   <= item.len;
    vif.awsize  <= item.size;
    vif.awburst <= item.burst;
    vif.awvalid <= 1'b1;

    while (!vif.awready) @(posedge vif.ACLK);
    vif.awvalid <= 1'b0;

    // Write Data Phase
    for (int i = 0; i <= item.len; i++) begin
      vif.wdata  <= item.data[i];
      vif.wstrb  <= item.wstrb[i];
      vif.wvalid <= 1'b1;
      vif.wlast  <= (i == item.len) ? 1'b1 : 1'b0;

      while (!vif.wready) @(posedge vif.ACLK);
      @(posedge vif.ACLK);
    end
    vif.wvalid <= 1'b0;
    vif.wlast  <= 1'b0;

    // Write Response Phase
    vif.bready <= 1'b1;
    while (!vif.bvalid) @(posedge vif.ACLK);
    item.resp   = vif.bresp;
    vif.bready <= 1'b0;
  endtask

  // AXI4-Full Read Burst Handshake Logic
  virtual task drive_read_burst(axi_full_seq_item item);
    // Read Address Phase
    vif.arid    <= item.id;
    vif.araddr  <= item.addr;
    vif.arlen   <= item.len;
    vif.arsize  <= item.size;
    vif.arburst <= item.burst;
    vif.arvalid <= 1'b1;

    while (!vif.arready) @(posedge vif.ACLK);
    vif.arvalid <= 1'b0;

    // Read Data Phase
    vif.rready <= 1'b1;
    item.data   = new[item.len + 1];
    
    for (int i = 0; i <= item.len; i++) begin
      while (!vif.rvalid) @(posedge vif.ACLK);
      item.data[i] = vif.rdata;
      if (vif.rlast && (i != item.len)) begin
        `uvm_error("AXI_FULL_DRV", "Received unexpected early RLAST signal from Slave")
      end
      @(posedge vif.ACLK);
    end
    vif.rready <= 1'b0;
  endtask

endclass

`endif // AXI_FULL_DRIVER_SV
