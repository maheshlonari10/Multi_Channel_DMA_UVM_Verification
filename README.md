# Multi-Channel DMA Controller UVM Verification Environment

## 📌 Project Overview
This repository contains a production-grade Universal Verification Methodology (UVM) testbench environment designed to verify a multi-channel Direct Memory Access (DMA) controller IP. The environment comprehensively validates concurrent data transfers, priority arbitration, and strict compliance with standard bus protocols.

## 🛠️ Key Features & Protocols
* **Configuration Interface:** AMBA AXI4-Lite (Slave) for register programming.
* **Data Transfer Interface:** AMBA AXI4 (Master) for high-speed burst memory transactions.
* **Channels Supported:** 4 independent channels with programmable priority logic.
* **Verification Methodologies:** SystemVerilog, UVM 1.2, SystemVerilog Assertions (SVA), and constrained-random stimulus generation.

## 🏗️ Verification Architecture
The testbench is built using a highly modular, reusable Universal Verification Methodology (UVM) structure as illustrated below:

```mermaid
graph TD
    %% Test & Sequence Layer
    subgraph Tests [UVM Tests Layer]
        Write_Seq[Write Sequence]
        Read_Seq[Read Sequence]
    end

    %% Environment Layer
    subgraph Environment [UVM Environment Block]
        
        %% Scoreboard block
        subgraph Scoreboard [UVM Scoreboard]
            Ref_Model[Ref Model Queue]
            Comparison[Comparison Logic]
        end

        %% Write Agent
        subgraph wr_agent [wr agent Components]
            Write_Seqr[Write Seqr] -->|TLM Seq Item Port| Write_DRV[Write DRV]
            Write_Mon[Write Mon]
        end

        %% Read Agent
        subgraph rd_agent [rd agent Components]
            Read_Seqr[Read Seqr] -->|TLM Seq Item Port| Read_DRV[Read DRV]
            Read_Mon[Read Mon]
        end

    end

    %% Design Under Verification
    subgraph DUV_Block [Design Layer]
        DUV[DUV / RTL Design]
    end

    %% Sequence execution paths
    Write_Seq -.->|Started On| Write_Seqr
    Read_Seq -.->|Started On| Read_Seqr

    %% Physical Interface Pins
    Write_DRV <==>|Write Interface| DUV
    Read_DRV <==>|Read Interface| DUV
    DUV ===>|Passive Sniff| Write_Mon
    DUV ===>|Passive Sniff| Read_Mon

    %% Analysis Port connections to Scoreboard
    Write_Mon -->|TLM Analysis Port| Ref_Model
    Read_Mon -->|TLM Analysis Port| Comparison

    %% Visual Styling to match Maven Silicon Slides
    classDef test_layer fill:#cccccc,stroke:#666666,stroke-width:2px,color:#000;
    classDef env_layer fill:#f0f7ff,stroke:#1f6feb,stroke-width:2px,color:#000;
    classDef agent_block fill:#ffe3cc,stroke:#ff9933,stroke-width:1.5px,color:#000;
    classDef sb_block fill:#ffebd6,stroke:#ff9933,stroke-width:2px,color:#000;
    classDef component fill:#2471a3,stroke:#1b4f72,stroke-width:1px,color:#fff;
    classDef duv_style fill:#7dcea0,stroke:#1e8449,stroke-width:2px,color:#000;

    class Tests test_layer;
    class Environment env_layer;
    class wr_agent,rd_agent agent_block;
    class Scoreboard sb_block;
    class Write_Seq,Read_Seq,Write_Seqr,Write_DRV,Write_Mon,Read_Seqr,Read_DRV,Read_Mon component;
    class DUV duv_style;
```

## 📋 Verification Plan (VPlan)

To ensure 100% functional coverage and protocol compliance, the verification strategy maps out specific validation milestones:

### 1. Register & Configuration Interface (AXI4-Lite)
| Feature to Verify | Stimulus Mechanism | Expected Output / Checking | Status |
| :--- | :--- | :--- | :--- |
| Register Write/Read Access | Constrained Random Sequences | Scoreboard prints exact match of addresses, lengths, and start bits. | ✅ Passed |
| Back-to-Back Access | High-density configuration writes | Register file handles configuration without dropping transactions. | ✅ Passed |

### 2. Data Transfer & Protocol Compliance (AXI4-Full)
| Feature to Verify | Stimulus Mechanism | Expected Output / Checking | Status |
| :--- | :--- | :--- | :--- |
| Single Burst Transfer | `dma_base_test` configuration | 16-beat data streams match sequentially from source to destination. | ✅ Passed |
| Multi-Burst Split Transfers | Payloads > 16 words (`xfer_len` up to 256) | Master FSM splits transfers into independent 16-beat chunks seamlessly. | 🔄 Planned |
| Handshake Settlement Timing | Delta-cycle boundary simulation | No duplicate or stalled beats on high-speed transitions. | ✅ Passed |
| `WLAST` / `RLAST` Boundaries | End-of-burst alignment sequences | Master terminates bus phases exactly on the final handshake. | ✅ Passed |

### 3. Functional Coverage & Metrics (Planned)
* **SystemVerilog Assertions (SVA):** Checking interface boundary violations (e.g., `AWVALID` must not drop until `AWREADY` is asserted).
* **Cross-Coverage:** Cross-coverage metrics monitoring Channel IDs vs. Burst Lengths vs. Memory Ranges.
