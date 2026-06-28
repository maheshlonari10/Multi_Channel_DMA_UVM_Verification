module dma_master_axi_full (
    input  wire        ACLK,
    input  wire        ARESETn,
    
    // Control inputs from Register Block
    input  wire        dma_start,
    input  wire [31:0] src_addr,
    input  wire [31:0] dest_addr,
    input  wire [31:0] xfer_len,
    output reg         dma_done,
    
    // AXI-Full Read Address Channel (M)
    output reg  [31:0] ARADDR,
    output reg  [7:0]  ARLEN,
    output reg  [2:0]  ARSIZE,
    output reg         ARVALID,
    input  wire        ARREADY,
    
    // AXI-Full Read Data Channel (M)
    input  wire [31:0] RDATA,
    input  wire        RLAST,
    input  wire        RVALID,
    output reg         RREADY,
    
    // AXI-Full Write Address Channel (M)
    output reg  [31:0] AWADDR,
    output reg  [7:0]  AWLEN,
    output reg  [2:0]  AWSIZE,
    output reg         AWVALID,
    input  wire        AWREADY,
    
    // AXI-Full Write Data Channel (M)
    output reg  [31:0] WDATA,
    output reg         WLAST,
    output reg         WVALID,
    input  wire        WREADY,
    
    // AXI-Full Write Response Channel (M)
    input  wire [1:0]  BRESP,
    input  wire        BVALID,
    output reg         BREADY,
    
    // FIFO Interface Rails
    output reg         fifo_wr_en,
    output reg  [31:0] fifo_wr_data,
    input  wire        fifo_full,
    output reg         fifo_rd_en,
    input  wire [31:0] fifo_rd_data,
    input  wire        fifo_empty
);

    // States for the Read Master Engine
    reg [1:0] rd_state;
    localparam RD_IDLE  = 2'b00,
               RD_BURST = 2'b01,
               RD_DONE  = 2'b10;

    // States for the Write Master Engine
    reg [1:0] wr_state;
    localparam WR_IDLE  = 2'b00,
               WR_ADDR  = 2'b01,
               WR_DATA  = 2'b10,
               WR_RESP  = 2'b11;

    reg [31:0] rd_count;
    reg [31:0] wr_count;

    // ==========================================================================
    // 1. AXI-FULL READ MASTER STATE MACHINE
    // ==========================================================================
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARADDR       <= 32'h0;
            ARLEN        <= 8'h0;
            ARSIZE       <= 3'b010; // 4 Bytes per transfer
            ARVALID      <= 1'b0;
            RREADY       <= 1'b0;
            fifo_wr_en   <= 1'b0;
            fifo_wr_data <= 32'h0;
            rd_count     <= 0;
            rd_state     <= RD_IDLE;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    if (dma_start && (rd_count < xfer_len)) begin
                        ARADDR  <= src_addr + (rd_count << 2);
                        ARLEN   <= (xfer_len - rd_count > 16) ? 8'd15 : (xfer_len - rd_count - 1);
                        ARVALID <= 1'b1;
                        rd_state <= RD_BURST;
                    end
                end

                RD_BURST: begin
                    if (ARREADY) ARVALID <= 1'b0;
                    RREADY <= !fifo_full;

                    if (RVALID && RREADY) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= RDATA;
                        rd_count     <= rd_count + 1;
                        if (RLAST) begin
                            RREADY     <= 1'b0;
                            fifo_wr_en <= 1'b0;
                            rd_state   <= (rd_count + 1 >= xfer_len) ? RD_DONE : RD_IDLE;
                        end
                    end else begin
                        fifo_wr_en <= 1'b0;
                    end
                end

                RD_DONE: begin
                    fifo_wr_en <= 1'b0;
                    if (!dma_start) begin
                        rd_count <= 0;
                        rd_state <= RD_IDLE;
                    end
                end
            endcase
        end
    end

    // ==========================================================================
    // 2. AXI-FULL WRITE MASTER STATE MACHINE
    // ==========================================================================
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWADDR     <= 32'h0;
            AWLEN      <= 8'h0;
            AWSIZE     <= 3'b010;
            AWVALID    <= 1'b0;
            WDATA      <= 32'h0;
            WLAST      <= 1'b0;
            WVALID     <= 1'b0;
            BREADY     <= 1'b0;
            fifo_rd_en <= 1'b0;
            wr_count   <= 0;
            dma_done   <= 1'b0;
            wr_state   <= WR_IDLE;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    dma_done <= 1'b0;
                        // FIX: Only launch a write burst if we haven't already completed all transfers!
                        if (dma_start && (wr_count < xfer_len) && !fifo_empty) begin
                        AWADDR   <= dest_addr + (wr_count << 2);
                        AWLEN    <= (xfer_len - wr_count > 16) ? 8'd15 : (xfer_len - wr_count - 1);
                        AWVALID  <= 1'b1;
                        wr_state <= WR_ADDR;
                    end
                end

                WR_ADDR: begin
                    if (AWREADY) begin
                        AWVALID    <= 1'b0;
                        fifo_rd_en <= 1'b1; // Pop first item out of FIFO
                        wr_state   <= WR_DATA;
                    end
                end

              WR_DATA: begin
    fifo_rd_en <= 1'b0;
    WVALID     <= 1'b1; // Driven actively in this state
    WDATA      <= fifo_rd_data;
    
    // FIX: Look directly at incoming WREADY since WVALID is guaranteed to settle high
    if (WREADY) begin
        wr_count <= wr_count + 1;
        
        // Assert WLAST lookahead on the final beat or 16-beat boundary
        if ((wr_count + 1) == xfer_len || (wr_count + 1) % 16 == 0) begin
            WLAST <= 1'b1;
        end
        
        if (WLAST) begin
          WLAST    <= 1'b0;
          WVALID   <= 1'b0;
          BREADY   <= 1'b1;
          wr_state <= WR_RESP;
        end else begin
          fifo_rd_en <= 1'b1; // Advance FWFT FIFO pointer immediately for next cycle
        end
    end
end

                WR_RESP: begin
                    if (BVALID) begin
                        BREADY <= 1'b0;
                        if (wr_count >= xfer_len) begin
                            dma_done <= 1'b1;
                            wr_state <= WR_IDLE;
                        end else begin
                            wr_state <= WR_IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule
