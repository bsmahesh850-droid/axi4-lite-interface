# AXI4-Lite Register Interface — Learning Project

A small, educational 32-bit AXI4-Lite master/slave system written in Verilog, with a self-checking testbench and waveform output.

## Features
- Five AXI4-Lite channels: AW, W, B, AR, R
- Correct VALID/READY handshake-based transfers
- Independent acceptance of write address and write data
- Four 32-bit memory-mapped registers at offsets `0x00`, `0x04`, `0x08`, `0x0C`
- Byte-write support through `WSTRB`
- `OKAY` and `SLVERR` responses
- Single outstanding operation in the master; slave accepts at most one pending write and one pending read
- Testbench checks normal writes/reads, byte write, invalid address, response codes, and timeouts
- VCD waveform output for GTKWave

## Project structure
```
rtl/axi4_lite_master.v
rtl/axi4_lite_slave.v
tb/tb_axi4_lite_system.v
web/index.html
```

## Run simulation (Icarus Verilog)
From the project root:

```bash
iverilog -g2012 -Wall -s tb_axi4_lite_system -o simv rtl/axi4_lite_master.v rtl/axi4_lite_slave.v tb/tb_axi4_lite_system.v
vvp simv
```

The testbench should print `ALL TESTS PASSED: 8 checks` if the simulation completes successfully. This project package was generated as source code; run the commands above in your environment to verify it before claiming simulation results.

Open the generated waveform:

```bash
gtkwave axi4_lite_system.vcd
```

## Register map
| Address offset | Register | Reset value | Access |
|---|---|---:|---|
| `0x00` | REG0 | `0x00000000` | Read/write |
| `0x04` | REG1 | `0x00000000` | Read/write |
| `0x08` | REG2 | `0x00000000` | Read/write |
| `0x0C` | REG3 | `0x00000000` | Read/write |

Aligned addresses outside this four-register window return `SLVERR` (`2'b10`). This is an educational single-clock implementation, not a formally verified or production-certified AXI IP core.

## Suggested next upgrades
1. Add assertions/scoreboarding and randomized backpressure tests.
2. Add a real bus interconnect only after this master/slave pair passes simulation.
3. Synthesize with a documented FPGA toolchain and report LUT/FF/timing results only from actual tool reports.
4. Keep the website's browser demo clearly labelled as an explanatory simulation; the static page does not execute Verilog RTL.
