module dma_fifo #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
)(
    input  wire                    CLK,
    input  wire                    RSTn,
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    input  wire                    rd_en,
    output wire [DATA_WIDTH-1:0]   rd_data, // Changed from reg to wire
    output wire                    full,
    output wire                    empty
);

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr;
    reg [$clog2(FIFO_DEPTH):0]   count;

    assign full  = (count == FIFO_DEPTH);
    assign empty = (count == 0);

    // CRITICAL FWFT FIX: Data at the read pointer is ALWAYS visible instantly!
    // No clock edge delay required.
    assign rd_data = empty ? {DATA_WIDTH{1'b0}} : mem[rd_ptr];

    always @(posedge CLK or negedge RSTn) begin
        if (!RSTn) begin
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
        end else begin
            // Handle Write Cycle
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= wr_ptr + 1;
            end
            
            // Handle Read Cycle - Pointers only change on rd_en
            if (rd_en && !empty) begin
                rd_ptr  <= rd_ptr + 1;
            end
            
            // Track Counter Status
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: ;
            endcase
        end
    end

endmodule
