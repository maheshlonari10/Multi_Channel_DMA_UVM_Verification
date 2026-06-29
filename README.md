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
    subgraph uvm_test_top [UVM Test Layer]
        dma_base_test[dma_base_test]
    end

    subgraph dma_env [UVM Environment Layers]
        dma_scoreboard[dma_scoreboard Table Engine]
        
        subgraph axi_lite_agent [AXI-Lite Agent Slave Component]
            axi_lite_sequencer[axi_lite_sequencer]
            axi_lite_driver[axi_lite_driver]
            axi_lite_monitor[axi_lite_monitor]
        end
        
        subgraph axi_full_agent [AXI-Full Agent Reactive Slave Component]
            axi_full_driver[axi_full_driver Memory Slave]
            axi_full_monitor[axi_full_monitor Dual-Thread]
        end
    end

    subgraph DUT [Design Under Test]
        dma_top_rtl[dma_top Multi-Channel RTL]
    end

    virtual_if_lite((AXI-Lite Virtual Interface))
    virtual_if_full((AXI-Full Virtual Interface))

    dma_base_test -->|Executes Sequence| axi_lite_sequencer
    axi_lite_sequencer -->|TLM Get| axi_lite_driver
    
    axi_lite_driver ==>|Drive Reg Configs| virtual_if_lite
    axi_lite_monitor --->|Sample Handshakes| virtual_if_lite
    virtual_if_lite <=> dma_top_rtl

    axi_full_driver ==>|Reactive Handshakes / Memory Arrays| virtual_if_full
    axi_full_monitor --->|Sample Bursts Concurrently| virtual_if_full
    virtual_if_full <=> dma_top_rtl

    axi_lite_monitor -->|Analysis Port: write_lite| dma_scoreboard
    axi_full_monitor -->|Analysis Port: write_full| dma_scoreboard
