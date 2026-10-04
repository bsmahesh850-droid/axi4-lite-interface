# [AXI4-Lite Protocol Interface & Register Block](https://bsmahesh850-droid.github.io/axi4-lite-interface/)

An industry-compliant Verilog implementation of the **AMBA AXI4-Lite** protocol featuring an integrated Master generator, 4-register Slave block, full byte-strobe support (`WSTRB`), and protocol error handling (`SLVERR`).

## Key Hardware Features
- **5 Decoupled Channels:** Independent handshakes across AW, W, B, AR, and R channels.
- **Byte Enable Support (`WSTRB`):** Selective byte-level write operations across 32-bit registers.
- **Protocol Error Decoding (`SLVERR`):** Out-of-bounds address access detection returning `2'b10` status.
- **Self-Checking Verification:** Integrated testbench validating zero-latency back-to-back operations.

## Architecture
```text
 +---------------------+                       +---------------------+
 |                     |== Write Address =====>|                     |
 |  AXI4-Lite Master   |== Write Data =========>|  AXI4-Lite Slave    |
 |  (Initiator Core)   |<-- Write Response ----|  (4x32 Register)    |
 |                     |                       |                     |
 |                     |== Read Address ======>|  Byte Mask Logic    |
 |                     |<-- Read Data/Resp ----|  Error Handling     |
 +---------------------+                       +---------------------+
