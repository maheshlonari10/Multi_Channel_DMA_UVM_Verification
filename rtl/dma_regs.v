module dma_regs (
    input  wire        ACLK,
    input  wire        ARESETn,

    // AXI-Lite Write Address Channel
    input  wire [31:0] AWADDR,
    input  wire        AWVALID,
    output reg         AWREADY,

    // AXI-Lite Write Data Channel
    input  wire [31:0] WDATA,
    input  wire [3:0]  WSTRB,
    input  wire        WVALID,
    output reg         WREADY,

    // AXI-Lite Write Response Channel
    output reg  [1:0]  BRESP,
    output reg         BVALID,
    input  wire        BREADY,

    // Internal HW Hardware Interface Rails to control DMA channels
    output reg  [31:0] src_addr,
    output reg  [31:0] dest_addr,
    output reg  [31:0] xfer_len,
    output reg         dma_start
);

    // State machine bits for clean transaction progression
    reg [1:0] write_state;
    localparam IDLE = 2'b00,
               DATA = 2'b01,
               RESP = 2'b10;

    // Synchronous Register Mapping and Decoding logic
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            src_addr    <= 32'h0;
            dest_addr   <= 32'h0;
            xfer_len    <= 32'h0;
            dma_start   <= 1'b0;
            AWREADY     <= 1'b0;
            WREADY      <= 1'b0;
            BVALID      <= 1'b0;
            BRESP       <= 2'b00;
            write_state <= IDLE;
        end else begin
            case (write_state)
                IDLE: begin
                    BVALID <= 1'b0;
                    if (AWVALID) begin
                        AWREADY     <= 1'b1;
                        write_state <= DATA;
                    end
                end

                DATA: begin
                    AWREADY <= 1'b0;
                    if (WVALID) begin
                        WREADY      <= 1'b1;
                        write_state <= RESP;

                        // Decode specific register address space maps
                        case (AWADDR)
                            32'h0000_0000: dma_start <= WDATA[0];
                            32'h0000_0004: src_addr  <= WDATA;
                            32'h0000_0008: dest_addr <= WDATA;
                            32'h0000_000C: xfer_len  <= WDATA;
                            default: ; // Ignore out-of-bounds register accesses
                        endcase
                    end
                end
                RESP: begin
                    WREADY <= 1'b0;
                    BVALID <= 1'b1;
                    BRESP  <= 2'b00; // Return OKAY
                    if (BREADY) begin
                        BVALID      <= 1'b0;
                        write_state <= IDLE;
                    end
                end

                default: write_state <= IDLE;
            endcase
        end
    end

endmodule
                           

                                    
