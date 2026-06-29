`ifndef DMA_SCOREBOARD_SV
`define DMA_SCOREBOARD_SV

`uvm_analysis_imp_decl(_lite)
`uvm_analysis_imp_decl(_full)

class dma_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dma_scoreboard)

  uvm_analysis_imp_lite #(axi_lite_seq_item, dma_scoreboard) lite_export;
  uvm_analysis_imp_full #(axi_full_seq_item, dma_scoreboard) full_export;

  protected bit [31:0] expected_mem_payload[$];
  
  int match_count = 0;
  int mismatch_count = 0;
  int lite_write_count = 0;
  bit table_header_printed = 0;

  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    lite_export = new("lite_export", this);
    full_export = new("full_export", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  // Helper to draw the table header once
  function void print_header();
    if (!table_header_printed) begin
      $display("\n+---------------+--------------+-------+------------+------+--------------------------------+");
      $display("| TIME          | CHANNEL      | OP    | ADDRESS    | LEN  | PAYLOAD DATA / STATUS          |");
      $display("+---------------+--------------+-------+------------+------+--------------------------------+");
      table_header_printed = 1;
    end
  endfunction

 virtual function void write_lite(axi_lite_seq_item item);
    string reg_name;
    
    // Decode the Address into a readable register name
    case (item.addr)
      32'h0: reg_name = "CTRL_REG";
      32'h4: reg_name = "SRC_ADDR";
      32'h8: reg_name = "DEST_ADDR";
      32'hc: reg_name = "XFER_LEN";
      default: reg_name = "UNKNOWN";
    endcase

    lite_write_count++;
    print_header();
    
    // Formatted to fit beautifully in the PAYLOAD column
    $display("| %10d ns | %-12s | %-5s | 0x%08h | %4s | %-10s : 0x%08h       |", 
             $time, "AXI-Lite", (item.op_type ? "WRITE" : "READ"), item.addr, "-", reg_name, item.data);
  endfunction

  virtual function void write_full(axi_full_seq_item item);
    print_header();
    $display("+---------------+--------------+-------+------------+------+--------------------------------+");
    
    if (item.op_type == 1'b0) begin // AXI READ (Source -> DMA)
      $display("| %10d ns | %-12s | %-5s | 0x%08h | %4d | BURST INITIATED (%0d BEATS)      |", 
               $time, "AXI-Full", "READ", item.addr, item.len, item.len + 1);
      
      foreach (item.data[i]) begin
        expected_mem_payload.push_back(item.data[i]);
        $display("| %10s    | %-12s | %-5s | 0x%08h | %4s | VAL:  0x%08h               |", 
                 "", "  -> Beat", "", item.addr + (i << 2), "", item.data[i]);
      end
    end 
    else begin                     // AXI WRITE (DMA -> Destination)
      $display("| %10d ns | %-12s | %-5s | 0x%08h | %4d | BURST VERIFICATION (%0d BEATS)   |", 
               $time, "AXI-Full", "WRITE", item.addr, item.len, item.len + 1);
      
      foreach (item.data[i]) begin
        if (expected_mem_payload.size() > 0) begin
          bit [31:0] expected_data = expected_mem_payload.pop_front();
          bit [31:0] beat_addr     = item.addr + (i << 2);
          
          if (item.data[i] == expected_data) begin
            match_count++;
            $display("| %10s    | %-12s | %-5s | 0x%08h | %4s | PASS: 0x%08h               |", 
                     "", "  -> Beat", "", beat_addr, "", item.data[i]);
          end else begin
            mismatch_count++;
            $display("| %10s    | %-12s | %-5s | 0x%08h | %4s | FAIL! EXP: %08h GOT: %08h|", 
                     "", "  -> Beat", "", beat_addr, "", expected_data, item.data[i]);
            `uvm_error("SB_DATA_MISMATCH", $sformatf("Data error at 0x%0h!", beat_addr))
          end
        end else begin
          mismatch_count++;
          $display("| %10s    | %-12s | %-5s | 0x%08h | %4s | FAIL! UNEXPECTED EXTRA BEAT  |", 
                   "", "  -> Beat", "", item.addr + (i << 2), "");
        end
      end
    end
    $display("+---------------+--------------+-------+------------+------+--------------------------------+");
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_REPORT", $sformatf("\n==================================================\n              FINAL SCOREBOARD REPORT              \n==================================================\n AXI-Lite Config Writes Captured: %0d\n AXI-Full Burst Matches Checked:  %0d\n Functional Payload Mismatches:   %0d\n==================================================", 
              lite_write_count, match_count, mismatch_count), UVM_NONE)
  endfunction

endclass

`endif // DMA_SCOREBOARD_SV
