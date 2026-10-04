# AXI4-Lite Protocol Interface & Memory Controller

A lightweight Verilog implementation of the AXI4-Lite protocol featuring an integrated Master generator and Slave memory-mapped register interface. Designed for efficient control-register accesses and internal CPU configuration transactions.

## Overview
- **Master Module (`axi4_lite_master.v`)**: Generates read/write transactions over standard AXI4-Lite handshakes.
- **Slave Module (`axi4_lite_slave.v`)**: Contains a 4-register bank (`reg_bank[0:3]`) with full address decoding (`0x0`, `0x4`, `0x8`, `0xC`).
- **Testbench (`tb_axi4_lite.v`)**: Verifies full write-then-read back functionality and detects data mismatches automatically.

## Repository Structure
