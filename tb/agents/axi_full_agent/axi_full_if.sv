interface axi_full_if #(
    parameter ADDR_WIDTH = 32, 
    parameter DATA_WIDTH = 32, 
    parameter ID_WIDTH   = 4
) (
    input logic ACLK, 
    input logic ARESETn
);

  // =========================================================================
  // Write Address Channel (AW)
  // =========================================================================
  logic [ID_WIDTH-1:0]    awid;
  logic [ADDR_WIDTH-1:0]  awaddr;
  logic [7:0]             awlen;     // Burst length: number of data transfers (beats) minus 1
  logic [2:0]             awsize;    // Burst size: bytes in each transfer beat
  logic [1:0]             awburst;   // Burst type: FIXED, INCR, WRAP
  logic                   awvalid;
  logic                   awready;

  // =========================================================================
  // Write Data Channel (W)
  // =========================================================================
  logic [DATA_WIDTH-1:0]      wdata;
  logic [(DATA_WIDTH/8)-1:0]  wstrb;     // Write strobes: indicates which byte lanes are valid
  logic                       wlast;     // Indicates the final beat of a burst transaction
  logic                       wvalid;
  logic                       wready;

  // =========================================================================
  // Write Response Channel (B)
  // =========================================================================
  logic [ID_WIDTH-1:0]    bid;
  logic [1:0]             bresp;     // Write response status (OKAY, EXOKAY, SLVERR, DECERR)
  logic                   bvalid;
  logic                   bready;

  // =========================================================================
  // Read Address Channel (AR)
  // =========================================================================
  logic [ID_WIDTH-1:0]    arid;
  logic [ADDR_WIDTH-1:0]  araddr;
  logic [7:0]             arlen;     // Read burst length
  logic [2:0]             arsize;    // Read burst size
  logic [1:0]             arburst;   // Read burst type
  logic                   arvalid;
  logic                   arready;

  // =========================================================================
  // Read Data Channel (R)
  // =========================================================================
  logic [ID_WIDTH-1:0]    rid;
  logic [DATA_WIDTH-1:0]  rdata;
  logic [1:0]             rresp;     // Read response status
  logic                       rlast;     // Indicates the final read beat of a burst
  logic                       rvalid;
  logic                       rready;

  // =========================================================================
  // Modports
  // =========================================================================
  
  // Master perspective (The DMA engine driving memory operations)
  modport master_mp (
    input  ACLK, ARESETn, awready, wready, bid, bresp, bvalid, arready, rid, rdata, rresp, rlast, rvalid,
    output awid, awaddr, awlen, awsize, awburst, awvalid, wdata, wstrb, wlast, wvalid, bready, arid, araddr, arlen, arsize, arburst, arvalid, rready
  );

  // Slave perspective (The System Memory interface reacting to DMA requests)
  modport slave_mp (
    input  awid, awaddr, awlen, awsize, awburst, awvalid, wdata, wstrb, wlast, wvalid, bready, arid, araddr, arlen, arsize, arburst, arvalid, rready, ACLK, ARESETn,
    output awready, wready, bid, bresp, bvalid, arready, rid, rdata, rresp, rlast, rvalid
  );

endinterface
