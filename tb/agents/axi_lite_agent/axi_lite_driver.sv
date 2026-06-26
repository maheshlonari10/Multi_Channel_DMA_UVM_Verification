`ifndef AXI_LITE_DRIVER_SV
`define AXI_LITE_DRIVER_SV

class axi_lite_driver extends uvm_driver #(axi_lite_seq_item);
  `uvm_component_utils(axi_lite_driver)

  // Virtual Interface to drive physical pins
  virtual axi_lite_if vif;

  // Constructor
  function new(string name = "axi_lite_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase: Retrieve the interface from the config DB
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV_NO_VIF", "Virtual interface not found for axi_lite_driver")
    end
  endfunction

  // Run Phase: Continuous loop to fetch and drive transactions
  virtual task run_phase(uvm_phase phase);
    // Reset signals to default state
    vif.awvalid <= 1'b0;
    vif.wvalid  <= 1'b0;
    vif.bready  <= 1'b0;
    vif.arvalid <= 1'b0;
    vif.rready  <= 1'b0;

    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
  endtask

  // Main driving task splitting Read and Write protocol logic
  virtual task drive_transfer(axi_lite_seq_item item);
    @(posedge vif.ACLK);
    if (item.op_type == AXI_WRITE) begin
      drive_write(item);
    end else begin
      drive_read(item);
    end
  endtask

  // AXI4-Lite Write Handshake Logic
  virtual task drive_write(axi_lite_seq_item item);
    // Address & Data Phase
    vif.awaddr  <= item.addr;
    vif.awvalid <= 1'b1;
    vif.wdata   <= item.data;
    vif.wstrb   <= item.strb;
    vif.wvalid  <= 1'b1;
    vif.bready  <= 1'b1;

    // Wait for Slave to accept Address and Data
    fork
      begin : aw_handshake
        while (!vif.awready) @(posedge vif.ACLK);
        vif.awvalid <= 1'b0;
      end
      begin : w_handshake
        while (!vif.wready) @(posedge vif.ACLK);
        vif.wvalid  <= 1'b0;
      end
    join

    // Write Response Phase
    while (!vif.bvalid) @(posedge vif.ACLK);
    item.resp = vif.bresp;
    vif.bready  <= 1'b0;
  endtask

  // AXI4-Lite Read Handshake Logic
  virtual task drive_read(axi_lite_seq_item item);
    // Read Address Phase
    vif.araddr  <= item.addr;
    vif.arvalid <= 1'b1;
    vif.rready  <= 1'b1;

    while (!vif.arready) @(posedge vif.ACLK);
    vif.arvalid <= 1'b0;

    // Read Data Phase
    while (!vif.rvalid) @(posedge vif.ACLK);
    item.data = vif.rdata;
    item.resp = vif.rresp;
    vif.rready  <= 1'b0;
  endtask

endclass

`endif // AXI_LITE_DRIVER_SV
