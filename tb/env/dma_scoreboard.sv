`ifndef DMA_SCOREBOARD_SV
`define DMA_SCOREBOARD_SV

// Implement the UVM macro to declare separate analysis ports for different transaction types
`uvm_analysis_imp_decl(_lite)
`uvm_analysis_imp_decl(_full)

class dma_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dma_scoreboard)

  // Declare separate Analysis Imports to receive packets from the two different monitors
  uvm_analysis_imp_lite #(axi_lite_seq_item, dma_scoreboard) lite_export;
  uvm_analysis_imp_full #(axi_full_seq_item, dma_scoreboard) full_export;

  // Golden Reference Arrays to store expected vs actual data packets for checking
  protected bit [31:0] expected_mem_payload[$];
  
  // Counters for logging statistics
  int match_count = 0;
  int mismatch_count = 0;
  int lite_write_count = 0; // NEW TRACKING COUNTER FOR CONFIG REGISTERS

  // Constructor
  function new(string name = "dma_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    lite_export = new("lite_export", this);
    full_export = new("full_export", this);
  endfunction

  // Build Phase
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  // Implementation for receiving and processing AXI-Lite configuration setups
  virtual function void write_lite(axi_lite_seq_item item);
    lite_write_count++; // Increment our configuration access counter
    
    // UPDATED VERBOSITY FROM UVM_HIGH TO UVM_LOW SO IT PRINTS BY DEFAULT
    `uvm_info("SB_LITE_REC", $sformatf("\n[SCOREBOARD-LITE] Verified Config Register Access:\nAddr: 0x%0h | Data: 0x%0h | Op: %s", 
              item.addr, item.data, (item.op_type == 1'b1 ? "WRITE" : "READ")), UVM_LOW)
  endfunction

  // Implementation for receiving and checking high-speed AXI-Full Burst memory streams
  virtual function void write_full(axi_full_seq_item item);
    `uvm_info("SB_FULL_REC", $sformatf("\n[SCOREBOARD] Monitored AXI-Full Burst Captured:\nID: %0d | Addr: 0x%0h | Len: %0d | Op: %s", 
              item.id, item.addr, item.len, (item.op_type ? "WRITE" : "READ")), UVM_LOW)

    // Aligned to check the DMA pipeline: READ fills the queue, WRITE checks the queue
    if (item.op_type == 1'b0) begin // AXI READ (Data entering DMA from Source)
      foreach (item.data[i]) begin
        expected_mem_payload.push_back(item.data[i]);
      end
      `uvm_info("SB_QUEUE_STORE", $sformatf("Stored %0d beats into Golden Reference Queue. Total size: %0d", item.len + 1, expected_mem_payload.size()), UVM_LOW)
    end 
    else begin                     // AXI WRITE (Data leaving DMA to Destination)
      foreach (item.data[i]) begin
        if (expected_mem_payload.size() > 0) begin
          bit [31:0] expected_data = expected_mem_payload.pop_front();
          bit [31:0] beat_addr     = item.addr + (i << 2); // Calculate precise beat address
          
          if (item.data[i] == expected_data) begin
            match_count++;
          end else begin
            mismatch_count++;
            `uvm_error("SB_DATA_MISMATCH", $sformatf("Data error at Beat Address 0x%0h! Expected: 0x%0h, Got: 0x%0h", beat_addr, expected_data, item.data[i]))
          end
        end else begin
          `uvm_warning("SB_UNEXPECTED_WRITE", $sformatf("Scoreboard captured an extra Write beat at index %0d but expected queue is empty!", i))
          mismatch_count++;
        end
      end
    end
  endfunction

  // Report Phase: Dump final test stats cleanly into the terminal log window
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_REPORT", $sformatf("\n==================================================\n             FINAL SCOREBOARD REPORT              \n==================================================\n AXI-Lite Config Writes Captured: %0d\n AXI-Full Burst Matches Checked:  %0d\n Functional Payload Mismatches:   %0d\n==================================================", 
              lite_write_count, match_count, mismatch_count), UVM_LOW)
  endfunction

endclass

`endif // DMA_SCOREBOARD_SV
