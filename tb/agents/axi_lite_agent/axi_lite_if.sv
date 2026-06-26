interface axi_lite_if #(parameter ADDR_WIDTH = 32, parameter DATA_WIDTH = 32) (input logic ACLK, input logic ARESETn);

  // Write Address Channel
  logic [ADDR_WIDTH-1:0] awaddr;
  logic                  awvalid;
  logic                  awready;

  // Write Data Channel
  logic [DATA_WIDTH-1:0] wdata;
  logic [(DATA_WIDTH/8)-1:0] wstrb;
  logic                  wvalid;
  logic                  wready;

  // Write Response Channel
  logic [1:0]            bresp;
  logic                  bvalid;
  logic                  bready;

  // Read Address Channel
  logic [ADDR_WIDTH-1:0] araddr;
  logic                  arvalid;
  logic                  arready;

  // Read Data Channel
  logic [DATA_WIDTH-1:0] rdata;
  logic [1:0]            rresp;
  logic                  rvalid;
  logic                  rready;

  // Modport for the Driver/Monitor (Master Perspective)
  modport master_mp (
    input  ACLK, ARESETn, awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid,
    output awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready
  );

  // Modport for the DMA DUT (Slave Perspective)
  modport slave_mp (
    input  ACLK, ARESETn, awaddr, awvalid, wdata, wstrb, wvalid, bready, araddr, arvalid, rready,
    output awready, wready, bresp, bvalid, arready, rdata, rresp, rvalid
  );

endinterface
