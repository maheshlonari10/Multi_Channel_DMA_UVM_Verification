module dma_top (
    input  wire        ACLK,
    input  wire        ARESETn,
    
    // ==========================================================================
    // AXI-LITE SLAVE INTERFACE (For Register Configuration)
    // ==========================================================================
    input  wire [31:0] S_AXI_LITE_AWADDR,
    input  wire        S_AXI_LITE_AWVALID,
    output wire        S_AXI_LITE_AWREADY,
    
    input  wire [31:0] S_AXI_LITE_WDATA,
    input  wire [3:0]  S_AXI_LITE_WSTRB,
    input  wire        S_AXI_LITE_WVALID,
    output wire        S_AXI_LITE_WREADY,
    
    output wire [1:0]  S_AXI_LITE_BRESP,
    output wire        S_AXI_LITE_BVALID,
    input  wire        S_AXI_LITE_BREADY,
    
    // ==========================================================================
    // AXI-FULL MASTER INTERFACE (For High-Speed Data Transfers)
    // ==========================================================================
    output wire [31:0] M_AXI_FULL_ARADDR,
    output wire [7:0]  M_AXI_FULL_ARLEN,
    output wire [2:0]  M_AXI_FULL_ARSIZE,
    output wire        M_AXI_FULL_ARVALID,
    input  wire        M_AXI_FULL_ARREADY,
    
    input  wire [31:0] M_AXI_FULL_RDATA,
    input  wire        M_AXI_FULL_RLAST,
    input  wire        M_AXI_FULL_RVALID,
    output wire        M_AXI_FULL_RREADY,
    
    output wire [31:0] M_AXI_FULL_AWADDR,
    output wire [7:0]  M_AXI_FULL_AWLEN,
    output wire [2:0]  M_AXI_FULL_AWSIZE,
    output wire        M_AXI_FULL_AWVALID,
    input  wire        M_AXI_FULL_AWREADY,
    
    output wire [31:0] M_AXI_FULL_WDATA,
    output wire        M_AXI_FULL_WLAST,
    output wire        M_AXI_FULL_WVALID,
    input  wire        M_AXI_FULL_WREADY,
    
    input  wire [1:0]  M_AXI_FULL_BRESP,
    input  wire        M_AXI_FULL_BVALID,
    output wire        M_AXI_FULL_BREADY,
    
    // Status Interrupt Interrupt Pin
    output wire        dma_irq
);

    // Internal interconnect wires connecting sub-modules
    wire [31:0] w_src_addr;
    wire [31:0] w_dest_addr;
    wire [31:0] w_xfer_len;
    wire        w_dma_start;
    wire        w_dma_done;

    wire        fifo_wr_en;
    wire [31:0] fifo_wr_data;
    wire        fifo_full;
    wire        fifo_rd_en;
    wire [31:0] fifo_rd_data;
    wire        fifo_empty;

    assign dma_irq = w_dma_done;

    // 1. Instantiate Configuration Register Block
    dma_regs u_regs (
        .ACLK      (ACLK),
        .ARESETn   (ARESETn),
        .AWADDR    (S_AXI_LITE_AWADDR),
        .AWVALID   (S_AXI_LITE_AWVALID),
        .AWREADY   (S_AXI_LITE_AWREADY),
        .WDATA     (S_AXI_LITE_WDATA),
        .WSTRB     (S_AXI_LITE_WSTRB),
        .WVALID    (S_AXI_LITE_WVALID),
        .WREADY    (S_AXI_LITE_WREADY),
        .BRESP     (S_AXI_LITE_BRESP),
        .BVALID    (S_AXI_LITE_BVALID),
        .BREADY    (S_AXI_LITE_BREADY),
        .src_addr  (w_src_addr),
        .dest_addr (w_dest_addr),
        .xfer_len  (w_xfer_len),
        .dma_start (w_dma_start)
    );

    // 2. Instantiate Internal Buffer Storage FIFO
    dma_fifo #(
        .DATA_WIDTH(32),
        .FIFO_DEPTH(16)
    ) u_fifo (
        .CLK      (ACLK),
        .RSTn     (ARESETn),
        .wr_en    (fifo_wr_en),
        .wr_data  (fifo_wr_data),
        .rd_en    (fifo_rd_en),
        .rd_data  (fifo_rd_data),
        .full     (fifo_full),
        .empty    (fifo_empty)
    );

    // 3. Instantiate High-Speed AXI-Full Master Transfer Engine
    dma_master_axi_full u_master (
        .ACLK         (ACLK),
        .ARESETn      (ARESETn),
        .dma_start    (w_dma_start),
        .src_addr     (w_src_addr),
        .dest_addr    (w_dest_addr),
        .xfer_len     (w_xfer_len),
        .dma_done     (w_dma_done),
        .ARADDR       (M_AXI_FULL_ARADDR),
        .ARLEN        (M_AXI_FULL_ARLEN),
        .ARSIZE       (M_AXI_FULL_ARSIZE),
        .ARVALID      (M_AXI_FULL_ARVALID),
        .ARREADY      (M_AXI_FULL_ARREADY),
        .RDATA        (M_AXI_FULL_RDATA),
        .RLAST        (M_AXI_FULL_RLAST),
        .RVALID       (M_AXI_FULL_RVALID),
        .RREADY       (M_AXI_FULL_RREADY),
        .AWADDR       (M_AXI_FULL_AWADDR),
        .AWLEN        (M_AXI_FULL_AWLEN),
        .AWSIZE       (M_AXI_FULL_AWSIZE),
        .AWVALID      (M_AXI_FULL_AWVALID),
        .AWREADY      (M_AXI_FULL_AWREADY),
        .WDATA        (M_AXI_FULL_WDATA),
        .WLAST        (M_AXI_FULL_WLAST),
        .WVALID       (M_AXI_FULL_WVALID),
        .WREADY       (M_AXI_FULL_WREADY),
        .BRESP        (M_AXI_FULL_BRESP),
        .BVALID       (M_AXI_FULL_BVALID),
        .BREADY       (M_AXI_FULL_BREADY),
        .fifo_wr_en   (fifo_wr_en),
        .fifo_wr_data (fifo_wr_data),
        .fifo_full    (fifo_full),
        .fifo_rd_en   (fifo_rd_en),
        .fifo_rd_data (fifo_rd_data),
        .fifo_empty   (fifo_empty)
    );

endmodule
